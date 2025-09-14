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

    func call(_ args: [(Value, Span)], parent env: Environment) throws -> Value {
        switch self {
        case .tack(let funct):
            try funct.call(args, parent: env)
        case .native(let funct):
            try funct.code(args, env)
        }
    }
}

struct TackFunction {
    let code: Block
    let params: [(Identifier, Expression)]
    let retType: Expression
    var span: Span { Span(from: retType.span.start, to: code.span.end) }

    func call(_ args: [(Value, Span)], parent env: Environment) throws -> Value {
        var env = Environment(env)
        for ((name, type), (value, span)) in zip(params, args) {
            guard try type.toType(withEnv: env) == value.type() else {
                throw Diag(type: .wrongType, span: span)
            }
            try env.declareConstant(named: name.lexeme, to: value)
        }
        return try code.value(withEnv: env)
    }
}

struct NativeFunction {
    let code: ([(Value, Span)], Environment) throws -> Value
}
