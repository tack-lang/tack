import Rainbow

enum DiagType {
    case eof
    case invalidInteger
    case expectedLiteral
    case unknownCharacter
    case expectedIdentifier
    case expectedParamsStart
    case expectedColon
    case expectedOpenBrace
    case expectedCloseBrace
    case expectedParamsEnd
    case expectedComma
    case mismatchedTypes
    case cantOperate
    case variableNotFound
    case variableUninitialized
    case expectedFunction
    case expectedType
    case wrongType
    case missingArgument
    case extraArgument
    case coercionFailure
    case missingMain
    case expectedCloseParen
    case expectedEquals

    // swiftlint:disable:next cyclomatic_complexity
    func msg() -> String {
        switch self {
        case .eof:
            return "unexpected end of file"
        case .invalidInteger:
            return "invalid integer literal"
        case .expectedLiteral:
            return "expected literal"
        case .unknownCharacter:
            return "unknown character"
        case .expectedIdentifier:
            return "expected identifier"
        case .expectedParamsStart:
            return "expected beginning of function params"
        case .expectedColon:
            return "expected colon"
        case .expectedCloseBrace:
            return "expected closing brace"
        case .expectedOpenBrace:
            return "expected opening brace"
        case .expectedParamsEnd:
            return "expected ending of function params"
        case .expectedComma:
            return "expected comma"
        case .mismatchedTypes:
            return "mismatched types"
        case .cantOperate:
            return "can't operate on type"
        case .variableNotFound:
            return "variable not found"
        case .variableUninitialized:
            return "variable not initialized"
        case .expectedFunction:
            return "expected function value"
        case .expectedType:
            return "expected type"
        case .wrongType:
            return "wrong type"
        case .missingArgument:
            return "missing argument"
        case .extraArgument:
            return "extra argument"
        case .coercionFailure:
            return "failed to coerce"
        case .missingMain:
            return "missing main function"
        case .expectedCloseParen:
            return "expected closing parenthesis"
        case .expectedEquals:
            return "expected equals sign"
        }
    }
}

public struct Diag: Error {
    let type: DiagType
    let span: Span
    let localMsg: String?
    let msg: String

    // Debug stuff
    #if DEBUG
        let file: String
        let line: UInt
        let column: UInt
    #endif

    init(
        type: DiagType, span: Span, msg: String? = nil, localMsg: String? = nil,
        file: String = #file, line: UInt = #line, column: UInt = #column
    ) {
        self.type = type
        self.span = span
        self.localMsg = localMsg
        if msg == nil {
            // lol debug message
            debugPrint("msg is nil!! plz fix!!")
            debugPrint("\(file):\(line):\(column)")
            self.msg = type.msg()
        } else {
            self.msg = msg!
        }
        #if DEBUG
            self.file = file
            self.line = line
            self.column = column
        #endif
    }
}

// swiftlint:disable:next function_body_length
public func renderError(diag: Diag, file: File) -> String {
    let sourceCode = file.source
    let lines = sourceCode.components(separatedBy: .newlines)
    let (startLine, startColumn) = findLineAndColumn(for: diag.span.start, in: lines)
    let (endLine, endColumn) = findLineAndColumn(for: diag.span.end, in: lines)

    // Check if the start and end lines exist
    guard startLine < lines.count, endLine < lines.count else {
        return "Error: \(diag.type)\n(Line out of bounds)"
    }

    var output = ""
    let lineStr = String(startLine + 1)
    let padding = lineStr.count + 1

    #if DEBUG
        var debug =
            "\n\(String(repeating: " ", count: padding - 1))\(diag.file):\(diag.line):\(diag.column)"
    #else
        let debug = ""
    #endif

    output += """
        \("Error".red.bold)\(":".white.bold) \(diag.msg.white.bold)\(debug)
        \(String(repeating: " ", count: padding - 1))--> \(file.getPath()):\(startLine + 1):\(startColumn + 1)
        """

    // Iterate through the lines covered by the span
    for line in startLine...endLine {
        let lineContent = lines[line]

        // Skip empty or whitespace-only lines
        if lineContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            continue
        }

        let currentLineStr = String(line + 1)
        let currentPadding = currentLineStr.count + 1

        let padding = String(repeating: " ", count: currentPadding - currentLineStr.count - 1)
        output +=
            "\n\(padding)\(currentLineStr) | \(lineContent)"

        // Create the marker for the current line
        let marker: String
        if line == startLine && line == endLine {
            // Single-line span
            let markerPadding = String(repeating: " ", count: startColumn)
            let markerLength = Int(diag.span.end - diag.span.start)
            marker = markerPadding + String(repeating: "^", count: markerLength)
        } else if line == startLine {
            // First line of a multi-line span
            let markerPadding = String(repeating: " ", count: startColumn)
            let markerLength = lineContent.count - startColumn
            marker = markerPadding + String(repeating: "^", count: markerLength)
        } else if line == endLine {
            // Last line of a multi-line span
            let markerLength = endColumn
            marker = String(repeating: "^", count: markerLength)
        } else {
            // Middle lines of a multi-line span
            marker = String(repeating: "^", count: lineContent.count)
        }

        output += "\n\(String(repeating: " ", count: currentPadding))| \(marker.red.bold)"
    }

    // Add the local message if available
    if let localMsg = diag.localMsg {
        output += " \(localMsg.red.bold)"
    }

    return output
}

// A helper function to find the line and column number
func findLineAndColumn(for index: UInt, in lines: [String]) -> (line: Int, column: Int) {
    var currentIndex: UInt = 0
    for (lineNumber, line) in lines.enumerated() {
        let lineLength = UInt(line.count) + 1  // +1 for the newline character
        if index < currentIndex + lineLength {
            let column = index - currentIndex
            return (lineNumber, Int(column))
        }
        currentIndex += lineLength
    }
    return (0, 0)
}
