enum Value {
    case uint(UInt)
    case int(Int)
    case float(Float)
    case double(Double)
    case string(String)
    case void

    func type() -> Type {
        switch self {
        case .uint:
            .uint
        case .int:
            .int
        case .float:
            .float
        case .double:
            .double
        case .string:
            .string
        case .void:
            .void
        }
    }
}

protocol Expression {
    var span: Span { get }

    func value(withEnv: Environment) throws -> Value
    func valid(withEnv: Environment) -> Bool
    func type(withEnv: Environment) -> Type?
}

enum Type {
    case uint
    case int
    case float
    case double
    case string
    case void
}

enum ExpressionError: Error {
    case mismatchedTypes(left: Type, right: Type)
    case cantOperate(type: Type, operator: String)
    case variableNotFound(name: String)
    case variableUnitialized(name: String)
}

struct Parser {
    var lexer: Lexer
    var peeked: Token??
    var file: File

    init(lexer: Lexer) {
        self.lexer = lexer
        file = lexer.file
    }

    mutating func nextToken() throws -> Token? {
        if peeked != nil {
            let old = peeked!
            peeked = nil
            return old
        }
        return try lexer.next()
    }

    mutating func peekToken() throws -> Token? {
        if peeked != nil {
            return peeked!
        }
        peeked = try lexer.next()
        return peeked!
    }

    func unwrapEof<T>(_ val: T?) throws -> T {
        if let unwrapped = val {
            return unwrapped
        } else {
            throw eofError()
        }
    }

    func eofError(file: String = #file, line: UInt = #line, column: UInt = #column) -> Diag {
        Diag(type: .eof, span: self.file.eofSpan(), file: file, line: line, column: column)
    }

    mutating func term() throws -> Expression? {
        guard var left = try primary() else {
            return nil
        }

        while let tok = try peekToken() {
            switch tok {
            case is Plus:
                let tok = try nextToken()!

                let right = try unwrapEof(try factor())
                left = Binary(Addition(left: left, right: right), span: Span(from: left.span.start, to: tok.span.end))
            case is Minus:
                let tok = try nextToken()!

                let right = try unwrapEof(try factor())
                left = Binary(Subtraction(left: left, right: right), span: Span(from: left.span.start, to: tok.span.end))
            case is NewLine:
                _ = try nextToken()
            default:
                return left
            }
        }

        return left
    }

    mutating func factor() throws -> Expression? {
        guard var left = try primary() else {
            return nil
        }

        while let tok = try peekToken() {
            switch tok {
            case is Star:
                let tok = try nextToken()!

                let right = try unwrapEof(try primary())
                left = Binary(Multiplication(left: left, right: right), span: Span(from: left.span.start, to: tok.span.end))
            case is Slash:
                let tok = try nextToken()!

                let right = try unwrapEof(try primary())
                left = Binary(Division(left: left, right: right), span: Span(from: left.span.start, to: tok.span.end))
            case is NewLine:
                _ = try nextToken()
            default:
                return left
            }
        }

        return left
    }

    mutating func primary() throws -> Expression? {
        guard let token: any Token = try peekToken() else {
            return nil
        }

        switch token {
        case is NewLine:
            _ = try nextToken()
            return try primary()
        case let token as Identifier:
            _ = try nextToken() // Skip equals
            return Variable(name: token)
        default:
            return try unwrapEof(try literal())
        }
    }

    mutating func literal() throws -> Literal? {
        guard let token: any Token = try nextToken() else {
            return nil
        }

        switch token {
        case is NewLine:
            return try literal()
        case let token as StringLit:
            return Literal(.string(token.val), span: token.span)
        case let token as NumLit:
            return Literal(.double(Double(token.val)), span: token.span)
        default:
            throw Diag(
                type: .expectedLiteral, span: token.span, msg: "expected a literal, found \(token)")
        }
    }
}
