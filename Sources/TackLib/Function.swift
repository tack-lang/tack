public enum Function: Equatable {
    var span: Span {
        switch self {
        case .tack(let funct):
            return funct.span
        case .native:
            return Span()
        }
    }

    case tack(TackFunction)
    case native(NativeFunction)

    public func call(_ args: [(Value, Span)], env: Environment, leftParen: Span) throws
        -> Value {
        switch self {
        case .tack(let funct):
            try funct.call(args, env: env, leftParen: leftParen)
        case .native(let funct):
            try funct.code(args, env, leftParen)
        }
    }
}

public struct TackFunction: Equatable {
    let code: Block
    let params: [(Identifier, any Expression)]
    let retType: any Expression
    var span: Span { Span(from: retType.span.start, to: code.span.end) }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        false
    }

    public func call(_ args: [(Value, Span)], env: Environment, leftParen: Span) throws
        -> Value {
        let retType = try retType.toType(withEnv: env)
        var env = Environment(env.root())
        let diff = params.count - args.count
        switch diff {
        case 0: break
        case let diff where diff > 0:
            let ident = params[args.count].0
            throw Diag(type: .missingArgument, span: leftParen, msg: "missing argument \(ident)")
        case let diff where diff < 0:
            let span = args[params.count].1
            throw Diag(type: .extraArgument, span: span, msg: "extra argument")
        default: unreachable()
        }
        for ((name, type), (value, span)) in zip(params, args) {
            guard let coerced = value.coerce(to: try type.toType(withEnv: env)) else {
                throw Diag(
                    type: .wrongType, span: span, msg: "wrong type",
                    localMsg: "expected \(try type.toType(withEnv: env)), found \(value.type())")
            }
            try env.declareConstant(named: name.lexeme, to: coerced, at: span)
        }
        let value = try code.value(withEnv: env)
        guard let ret = value.coerce(to: retType) else {
            throw Diag(
                type: .wrongType, span: code.statements.last?.span ?? code.span,
                msg: "wrong return type", localMsg: "expected \(retType), found \(value.type())")
        }
        return ret
    }
}

public struct NativeFunction: Equatable {
    public static func == (lhs: NativeFunction, rhs: NativeFunction) -> Bool {
        lhs.name == rhs.name
    }

    public init(
        _ name: String, _ code: @escaping ([(Value, Span)], Environment, Span) throws -> Value
    ) {
        self.name = name
        self.code = code
    }

    public let name: String
    public let code: ([(Value, Span)], Environment, Span) throws -> Value
}
