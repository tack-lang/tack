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

public func renderError(diag: Diag, file: File) -> String {
    let sourceCode = file.source
    let lines = sourceCode.components(separatedBy: .newlines)
    let (line, column) = findLineAndColumn(for: diag.span.start, in: lines)

    // Check if the line exists
    guard line < lines.count else {
        return "Error: \(diag.type)\n(Line out of bounds)"
    }

    let lineContent = lines[line]

    // Create the visual marker
    let markerLength = Int(diag.span.end - diag.span.start)
    let markerPadding = String(repeating: " ", count: column)
    let marker = markerPadding + String(repeating: "^", count: markerLength)

    let lineStr = String(line + 1)
    let padding = lineStr.count + 1
    #if DEBUG
        var debug =
            "\n\(String(repeating: " ", count: padding - 1))\(diag.file):\(diag.line):\(diag.column)"
        if #available(macOS 13.0, *) {
            debug.replace("Tack", with: "Sources")
        } else {

        }
    #else
        let debug = ""
    #endif

    // Assemble the final output
    return """
        \("Error".red.bold)\(":".white.bold) \(diag.msg.white.bold)\(debug)
        \(String(repeating: " ", count: padding - 1))--> \(file.getPath()):\(lineStr):\(column)
        \(String(repeating: " ", count: padding))|
        \(String(repeating: " ", count: padding - lineStr.count - 1))\(lineStr) | \(lineContent)
        \(String(repeating: " ", count: padding))| \(marker.red.bold) \((diag.localMsg ?? "").red.bold)
        """
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
