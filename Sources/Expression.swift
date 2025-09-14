func isNumber(_ type: Type) -> Bool {
    switch type {
    case .uint, .int, .float, .double:
        true
    default:
        false
    }
}

func isString(_ type: Type) -> Bool {
    switch type {
    case .string:
        true
    default:
        false
    }
}

protocol BinaryExpression {
    var left: Expression { get }
    var right: Expression { get }

    /// Throws an error on failure
    func operate(_ left: Value, _ right: Value) throws -> Value
    /// Throws an error if expression is invalid, otherwise does nothing
    func valid(_ left: Value, _ right: Value) throws
    /// Return nil on failure, should only fail if valid() is false
    func type(_ left: Value, _ right: Value) -> Type?
}

extension BinaryExpression {
    func isValid(_ left: Value, _ right: Value) -> Bool {
        (try? valid(left, right)) != nil
    }
}

struct Binary: Expression {
    let inner: any BinaryExpression
    let span: Span

    init(_ inner: any BinaryExpression, span: Span) {
        self.inner = inner
        self.span = span
    }

    func evalSides(withEnv env: Environment) throws -> (Value, Value) {
        (try inner.left.value(withEnv: env), try inner.right.value(withEnv: env))
    }

    func value(withEnv env: Environment) throws -> Value {
        let (left, right) = try evalSides(withEnv: env)
        return try inner.operate(left, right)
    }

    func valid(withEnv env: Environment) -> Bool {
        guard let (left, right) = try? evalSides(withEnv: env) else {
            return false
        }
        return inner.isValid(left, right)
    }

    func type(withEnv env: Environment) -> Type? {
        guard let values = try? evalSides(withEnv: env) else {
            return nil
        }
        return inner.type(values.0, values.1)
    }
}

struct Addition: BinaryExpression {
    var left: any Expression
    var right: any Expression

    func operate(_ left: Value, _ right: Value) throws -> Value {
        try valid(left, right)
        switch (left, right) {
        case (.uint(let left), .uint(let right)):
            return .uint(left + right)
        case (.int(let left), .int(let right)):
            return .int(left + right)
        case (.float(let left), .float(let right)):
            return .float(left + right)
        case (.double(let left), .double(let right)):
            return .double(left + right)
        case (.string(let left), .string(let right)):
            return .string(left + right)
        default:
            unreachable()
        }
    }

    func valid(_ left: Value, _ right: Value) throws {
        guard left.type() == right.type() else {
            throw Diag(
                type: .mismatchedTypes,
                span: Span(from: self.left.span.start, to: self.right.span.end),
                msg: "mismatched types in operator '+'")
        }
        guard isNumber(left.type()) || isString(left.type()) else {
            throw Diag(
                type: .cantOperate,
                span: Span(from: self.left.span.start, to: self.right.span.end),
                msg: "operator '+' can't operate on type \(left.type())")
        }
    }

    func type(_ left: Value, _ right: Value) -> Type? {
        guard isValid(left, right) else {
            return nil
        }
        return left.type()
    }
}

struct Subtraction: BinaryExpression {
    var left: any Expression
    var right: any Expression

    func operate(_ left: Value, _ right: Value) throws -> Value {
        try valid(left, right)
        switch (left, right) {
        case (.uint(let left), .uint(let right)):
            return .uint(left - right)
        case (.int(let left), .int(let right)):
            return .int(left - right)
        case (.float(let left), .float(let right)):
            return .float(left - right)
        case (.double(let left), .double(let right)):
            return .double(left - right)
        default:
            unreachable()
        }
    }

    func valid(_ left: Value, _ right: Value) throws {
        guard left.type() == right.type() else {
            throw Diag(
                type: .mismatchedTypes,
                span: Span(from: self.left.span.start, to: self.right.span.end),
                msg: "mismatched types in operator '-'")
        }
        guard isNumber(left.type()) else {
            throw Diag(
                type: .cantOperate,
                span: Span(from: self.left.span.start, to: self.right.span.end),
                msg: "operator '-' can't operate on type \(left.type())")
        }
    }

    func type(_ left: Value, _ right: Value) -> Type? {
        guard isValid(left, right) else {
            return nil
        }
        return left.type()
    }
}

struct Multiplication: BinaryExpression {
    var left: any Expression
    var right: any Expression

    func operate(_ left: Value, _ right: Value) throws -> Value {
        try valid(left, right)
        switch (left, right) {
        case (.uint(let left), .uint(let right)):
            return .uint(left * right)
        case (.int(let left), .int(let right)):
            return .int(left * right)
        case (.float(let left), .float(let right)):
            return .float(left * right)
        case (.double(let left), .double(let right)):
            return .double(left * right)
        default:
            unreachable()
        }
    }

    func valid(_ left: Value, _ right: Value) throws {
        guard left.type() == right.type() else {
            throw Diag(
                type: .mismatchedTypes,
                span: Span(from: self.left.span.start, to: self.right.span.end),
                msg: "mismatched types in operator '*'")
        }
        guard isNumber(left.type()) else {
            throw Diag(
                type: .cantOperate,
                span: Span(from: self.left.span.start, to: self.right.span.end),
                msg: "operator '*' can't operate on type \(left.type())")
        }
    }

    func type(_ left: Value, _ right: Value) -> Type? {
        guard isValid(left, right) else {
            return nil
        }
        return left.type()
    }
}

struct Division: BinaryExpression {
    var left: any Expression
    var right: any Expression

    func operate(_ left: Value, _ right: Value) throws -> Value {
        try valid(left, right)
        switch (left, right) {
        case (.uint(let left), .uint(let right)):
            return .uint(left / right)
        case (.int(let left), .int(let right)):
            return .int(left / right)
        case (.float(let left), .float(let right)):
            return .float(left / right)
        case (.double(let left), .double(let right)):
            return .double(left / right)
        default:
            unreachable()
        }
    }

    func valid(_ left: Value, _ right: Value) throws {
        guard left.type() == right.type() else {
            throw Diag(
                type: .mismatchedTypes,
                span: Span(from: self.left.span.start, to: self.right.span.end),
                msg: "mismatched types in operator '/'")
        }
        guard isNumber(left.type()) else {
            throw Diag(
                type: .cantOperate,
                span: Span(from: self.left.span.start, to: self.right.span.end),
                msg: "operator '/' can't operate on type \(left.type())")
        }
    }

    func type(_ left: Value, _ right: Value) -> Type? {
        guard isValid(left, right) else {
            return nil
        }
        return left.type()
    }
}

struct Literal: Expression {
    let value: Value
    let span: Span

    init(_ value: Value, span: Span) {
        self.value = value
        self.span = span
    }

    func value(withEnv _: Environment) throws -> Value {
        value
    }

    func valid(withEnv _: Environment) -> Bool {
        true
    }

    func type(withEnv _: Environment) -> Type? {
        value.type()
    }
}

struct Variable: Expression {
    let name: Identifier
    var span: Span { name.span }

    func value(withEnv env: Environment) throws -> Value {
        guard let variable = env.getVariable(named: name.lexeme) else {
            throw Diag(
                type: .variableNotFound, span: span, msg: "variable '\(name.lexeme)' not found")
        }
        guard let value = variable.get() else {
            throw Diag(
                type: .variableUninitialized, span: span,
                msg: "variable '\(name.lexeme)' is unitialized")
        }
        return value
    }

    func valid(withEnv env: Environment) -> Bool {
        env.getVariable(named: name.lexeme) != nil
    }

    func type(withEnv env: Environment) -> Type? {
        env.getVariable(named: name.lexeme)?.type
    }
}

struct Block: Expression {
    var span: Span
    var statements: [Statement]

    func value(withEnv env: Environment) throws -> Value {
        var env = env
        var ret: Value = .void
        for stmt in statements {
            ret = try stmt.run(withEnv: &env)
        }
        return ret
    }

    func valid(withEnv env: Environment) -> Bool {
        true
    }

    func type(withEnv env: Environment) -> Type? {
        statements.last?.type(withEnv: env) ?? .void
    }

}

struct Call: Expression {
    let function: Expression
    let args: [Expression]
    let span: Span

    func value(withEnv env: Environment) throws -> Value {
        let val = try function.value(withEnv: env)
        guard case .function(let funct) = val else {
            throw Diag(type: .expectedFunction, span: span, msg: "expected function, found \(val.type())")
        }
        var argVals: [(Value, Span)] = []
        for arg in args {
            argVals.append((try arg.value(withEnv: env), arg.span))
        }
        return try funct.call(argVals, parent: env.root())
    }

    func valid(withEnv: Environment) -> Bool {
        todo()
    }

    func type(withEnv: Environment) -> Type? {
        todo()
    }

}
