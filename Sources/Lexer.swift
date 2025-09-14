protocol Token: CustomStringConvertible {
    var span: Span { get }
    var lexeme: String { get }
}

extension Token {
    var description: String { lexeme }
}

struct Lexer {
    var src: String.Iterator
    var file: File
    var peeked: Character??
    var span: Span

    typealias Element = Token

    init(src: File) {
        self.src = src.source.makeIterator()
        span = Span()
        file = src
    }

    mutating func skipWhitespace() {
        while true {
            switch peekChar() {
            case let char where char?.isWhitespace == true:
                _ = nextChar()
            default:
                _ = span.reset()
                return
            }
        }
    }

    mutating func atEof() -> Bool {
        peekChar() == nil
    }

    mutating func nextChar() -> Character? {
        span.growFront(by: 1)
        if peeked != nil {
            let old = peeked!
            peeked = nil
            return old
        }
        return src.next()
    }

    mutating func peekChar() -> Character? {
        if peeked != nil {
            return peeked!
        }
        peeked = src.next()
        return peeked!
    }

    func currentSubstring() -> Substring {
        span.apply(to: file.source)
    }

    mutating func next() throws -> Token? {
        skipWhitespace()

        if atEof() {
            return nil
        }

        let char = nextChar()!
        if let token = handleSingleCharacterTokens(char) {
            return token
        } else if char == "\"" {
            return try handleStringLiteral()
        } else if char.isWholeNumber {
            return try handleNumberLiteral(startingWith: char)
        } else if char.isLetter {
            return handleIdentifierOrKeyword(startingWith: char)
        } else {
            throw Diag(type: .unknownCharacter, span: span, msg: "unknown character '\(char)'")
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private mutating func handleSingleCharacterTokens(_ char: Character) -> Token? {
        switch char {
        case ":":
            return Colon(span: span.reset())
        case "(":
            return OpenParen(span: span.reset())
        case ")":
            return CloseParen(span: span.reset())
        case "{":
            return OpenBrace(span: span.reset())
        case "}":
            return CloseBrace(span: span.reset())
        case "+":
            return Plus(span: span.reset())
        case "-":
            return Minus(span: span.reset())
        case "*":
            return Star(span: span.reset())
        case "/":
            return Slash(span: span.reset())
        case ",":
            return Comma(span: span.reset())
        default:
            return nil
        }
    }

    // Helper function for string literals
    private mutating func handleStringLiteral() throws -> Token {
        while peekChar() != "\"" {
            _ = nextChar()
        }
        span.shrinkBack(by: 1)
        let substr = currentSubstring()
        span.growBack(by: 1)
        let lexeme = currentSubstring()
        _ = nextChar()

        return StringLit(span: span.reset(), val: String(substr), lexeme: String(lexeme))
    }

    // Helper function for number literals
    private mutating func handleNumberLiteral(startingWith char: Character) throws -> Token {
        while peekChar()?.isWholeNumber == true || peekChar() == "e" || peekChar() == "." {
            _ = nextChar()
        }
        let substr = currentSubstring()
        guard let val = Double(substr) else {
            throw Diag(type: .invalidInteger, span: span.reset())
        }
        return NumLit(span: span, val: val)
    }

    // Helper function for identifiers and keywords
    private mutating func handleIdentifierOrKeyword(startingWith char: Character) -> Token {
        while peekChar()?.isLetter == true {
            _ = nextChar()
        }
        let substr = currentSubstring()
        switch substr {
        case "void":
            return Void(span: span.reset())
        default:
            return Identifier(span: span.reset(), lexeme: String(substr))
        }
    }
}
