public protocol Statement {
    var span: Span { get }

    func run(withEnv: inout Environment) throws -> Value
    func valid(withEnv: Environment) -> Bool
    func type(withEnv: Environment) -> Type?
}

public protocol Expression: Statement {
    var span: Span { get }

    func value(withEnv: Environment) throws -> Value
    func valid(withEnv: Environment) -> Bool
    func type(withEnv: Environment) -> Type?
}

extension Expression {
    func run(withEnv env: inout Environment) throws -> Value {
        try value(withEnv: env)
    }

    func toType(withEnv env: Environment) throws -> Type {
        switch try value(withEnv: env) {
        case .type(let type):
            return type
        default:
            throw Diag(type: .expectedType, span: span)
        }
    }
}

public struct Parser {
    var lexer: Lexer
    var peeked: Token??
    var file: File

    public init(lexer: Lexer) {
        self.lexer = lexer
        file = lexer.file
    }
}

extension Parser {
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

    mutating func identifier() throws -> Identifier {
        let tok = try unwrapEof(try nextToken())
        guard let ident = tok as? Identifier else {
            throw Diag(
                type: .expectedIdentifier, span: tok.span,
                msg: "expected identifier, found '\(tok)'")
        }
        return ident
    }

    mutating func block() throws -> Block? {
        guard let tok = try nextToken() else {
            return nil
        }

        guard let openBrace = tok as? OpenBrace else {
            throw Diag(type: .expectedOpenBrace, span: tok.span)
        }

        var statements: [Statement] = []

        while !(try unwrapEof(try peekToken()) is CloseBrace) {
            statements.append(try unwrapEof(try statement()))
        }

        let tok2 = try unwrapEof(try nextToken())
        guard let closeBrace = tok2 as? CloseBrace else {
            throw Diag(type: .expectedCloseBrace, span: tok2.span)
        }

        return Block(
            span: Span(from: openBrace.span.start, to: closeBrace.span.start),
            statements: statements)
    }

    mutating func funct() throws -> (Identifier, Function)? {
        let retType = try unwrapEof(try typeExpression())
        let ident = try identifier()
        let tok = try unwrapEof(try nextToken())
        guard tok is OpenParen else {
            throw Diag(
                type: .expectedParamsStart, span: tok.span,
                msg: "expected beginning of function params, found '\(tok)'")
        }
        var params: [(Identifier, any Expression)] = []
        while !(try unwrapEof(try peekToken()) is CloseParen) {
            let paramName = try identifier()
            let tok = try unwrapEof(try nextToken())
            guard tok is Colon else {
                throw Diag(type: .expectedColon, span: tok.span)
            }
            let type = try unwrapEof(try typeExpression())
            let comma = try unwrapEof(try peekToken())
            if comma is Comma {
                _ = try nextToken()
            }

            params.append((paramName, type))
        }
        let tok2 = try unwrapEof(try nextToken())
        guard tok2 is CloseParen else {
            throw Diag(
                type: .expectedParamsEnd, span: tok2.span,
                msg: "expected ending of function params, found '\(tok)'")
        }
        let code = try unwrapEof(try block())
        let funct = TackFunction(code: code, params: params, retType: retType)
        return (ident, .tack(funct))
    }

    mutating func statement() throws -> Statement? {
        guard try peekToken() != nil else {
            return nil
        }
        return try unwrapEof(try expression())
    }

    public mutating func item() throws -> Item? {
        guard let tok = try peekToken() else {
            return nil
        }

        switch tok {
        case is Const:
            _ = try nextToken()
            let ident = try identifier()
            let tok = try unwrapEof(try nextToken())
            guard tok is Equals else {
                throw Diag(
                    type: .expectedEquals, span: tok.span, msg: "expected equals, found '\(tok)'")
            }
            let expr = try unwrapEof(try expression())
            return .constant(
                Constant(name: ident, value: expr))
        default:
            let (ident, funct) = try unwrapEof(try funct())
            return .constant(
                Constant(name: ident, value: Literal(.function(funct), span: funct.span)))
        }
    }

    mutating func expression() throws -> Expression? {
        try term()
    }

    mutating func typeExpression() throws -> Expression? {
        try primary()
    }

    mutating func term() throws -> Expression? {
        guard var left = try factor() else {
            return nil
        }

        while let tok = try peekToken() {
            switch tok {
            case is Plus:
                _ = try nextToken()

                let right = try unwrapEof(try factor())
                left = Binary(
                    Addition(left: left, right: right),
                    span: Span(from: left.span.start, to: right.span.end)
                )
            case is Minus:
                _ = try nextToken()

                let right = try unwrapEof(try factor())
                left = Binary(
                    Subtraction(left: left, right: right),
                    span: Span(from: left.span.start, to: right.span.end)
                )
            default:
                return left
            }
        }

        return left
    }

    mutating func factor() throws -> Expression? {
        guard var left = try coerce() else {
            return nil
        }

        while let tok = try peekToken() {
            switch tok {
            case is Star:
                _ = try nextToken()

                let right = try unwrapEof(try coerce())
                left = Binary(
                    Multiplication(left: left, right: right),
                    span: Span(from: left.span.start, to: right.span.end)
                )
            case is Slash:
                _ = try nextToken()

                let right = try unwrapEof(try coerce())
                left = Binary(
                    Division(left: left, right: right),
                    span: Span(from: left.span.start, to: right.span.end)
                )
            default:
                return left
            }
        }

        return left
    }

    mutating func coerce() throws -> Expression? {
        guard let left = try call() else {
            return nil
        }
        guard try peekToken() is As else {
            return left
        }
        _ = try nextToken()
        let type = try unwrapEof(try typeExpression())
        return Coerce(left: left, type: type, span: Span(from: left.span.start, to: type.span.end))
    }

    mutating func call() throws -> Expression? {
        guard let left = try primary() else {
            return nil
        }
        guard try peekToken() is OpenParen else {
            return left
        }
        _ = try nextToken()
        var expressions: [Expression] = []
        while !(try unwrapEof(try peekToken()) is CloseParen) {
            let expr = try unwrapEof(try expression())
            if try unwrapEof(try peekToken()) is Comma {
                _ = try nextToken()
            }
            expressions.append(expr)
        }
        guard let closeParen = try nextToken() as? CloseParen else {
            unreachable()
        }
        return Call(
            function: left, args: expressions,
            span: Span(from: left.span.start, to: closeParen.span.end))
    }

    mutating func primary() throws -> Expression? {
        guard let token = try peekToken() else {
            return nil
        }

        switch token {
        case let token as Identifier:
            _ = try nextToken()  // Consume identifier
            return Variable(name: token)
        case is OpenBrace:
            let block = try unwrapEof(try block())
            return block
        case is OpenParen:
            _ = try nextToken()  // Consume OpenParen
            let expr = try unwrapEof(try expression())
            let tok = try unwrapEof(try nextToken())
            guard tok is CloseParen else {
                throw Diag(
                    type: .expectedCloseParen, span: tok.span, msg: "expected closing parenthesis")
            }
            return expr
        default:
            return try unwrapEof(try literal())
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    mutating func literal() throws -> Literal? {
        guard let token: any Token = try nextToken() else {
            return nil
        }

        switch token {
        case let token as StringLit:
            return Literal(.string(token.val), span: token.span)
        case let token as NumLit:
            return Literal(token.toVal(), span: token.span)
        case is VoidKey:
            return Literal(.type(.void), span: token.span)
        case is U8:
            return Literal(.type(.u8), span: token.span)
        case is U16:
            return Literal(.type(.u16), span: token.span)
        case is U32:
            return Literal(.type(.u32), span: token.span)
        case is U64:
            return Literal(.type(.u64), span: token.span)
        case is I8:
            return Literal(.type(.i8), span: token.span)
        case is I16:
            return Literal(.type(.i16), span: token.span)
        case is I32:
            return Literal(.type(.i32), span: token.span)
        case is I64:
            return Literal(.type(.i64), span: token.span)
        case is FloatKey:
            return Literal(.type(.double), span: token.span)
        case is DoubleKey:
            return Literal(.type(.double), span: token.span)
        default:
            throw Diag(
                type: .expectedLiteral, span: token.span,
                msg: "expected a literal, found '\(token)'")
        }
    }
}
