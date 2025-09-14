enum Function {
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

    func call(_ args: [(Value, Span)], parent env: Environment, leftParen: Span) throws -> Value {
        switch self {
        case .tack(let funct):
            try funct.call(args, parent: env, leftParen: leftParen)
        case .native(let funct):
            try funct.code(args, env, leftParen)
        }
    }
}

struct TackFunction {
    let code: Block
    let params: [(Identifier, Expression)]
    let retType: Expression
    var span: Span { Span(from: retType.span.start, to: code.span.end) }

    func call(_ args: [(Value, Span)], parent env: Environment, leftParen: Span) throws -> Value {
        var env = Environment(env)
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
            try env.declareConstant(named: name.lexeme, to: coerced)
        }
        return try code.value(withEnv: env)
    }
}

struct NativeFunction {
    let code: ([(Value, Span)], Environment, Span) throws -> Value
}
