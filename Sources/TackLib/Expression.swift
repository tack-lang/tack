// swiftlint:disable file_length

func isNumber(_ type: Type) -> Bool {
    switch type {
    case .u8, .u16, .u32, .u64, .compuint, .i8, .i16, .i32, .i64, .compint, .float, .double,
        .compfloat, .compnum:
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

// swiftlint:disable cyclomatic_complexity
struct Binary: Expression {
    let inner: any BinaryExpression
    let span: Span

    init(_ inner: any BinaryExpression, span: Span) {
        self.inner = inner
        self.span = span
    }

    func evalSides(withEnv env: Environment) throws -> (Value, Value) {
        let left = try inner.left.value(withEnv: env)
        let right = try inner.right.value(withEnv: env)

        let rightCoerced = right.coerce(to: left.type())
        if let right = rightCoerced {
            return (left, right)
        }
        let leftCoerced = left.coerce(to: right.type())
        if let left = leftCoerced {
            return (left, right)
        }
        return (left, right)
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
        case (.u8(let left), .u8(let right)):
            return .u8(left + right)
        case (.u16(let left), .u16(let right)):
            return .u16(left + right)
        case (.u32(let left), .u32(let right)):
            return .u32(left + right)
        case (.u64(let left), .u64(let right)):
            return .u64(left + right)
        case (.i8(let left), .i8(let right)):
            return .i8(left + right)
        case (.i16(let left), .i16(let right)):
            return .i16(left + right)
        case (.i32(let left), .i32(let right)):
            return .i32(left + right)
        case (.i64(let left), .i64(let right)):
            return .i64(left + right)
        case (.float(let left), .float(let right)):
            return .float(left + right)
        case (.double(let left), .double(let right)):
            return .double(left + right)
        case (.string(let left), .string(let right)):
            return .string(left + right)
        case (.compnum(let left), .compnum(let right)):
            return .compnum(left + right)
        case (.compfloat(let left), .compfloat(let right)):
            return .compfloat(left + right)
        case (.compint(let left), .compint(let right)):
            return .compint(left + right)
        case (.compuint(let left), .compuint(let right)):
            return .compuint(left + right)
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
        case (.u8(let left), .u8(let right)):
            return .u8(left - right)
        case (.u16(let left), .u16(let right)):
            return .u16(left - right)
        case (.u32(let left), .u32(let right)):
            return .u32(left - right)
        case (.u64(let left), .u64(let right)):
            return .u64(left - right)
        case (.i8(let left), .i8(let right)):
            return .i8(left - right)
        case (.i16(let left), .i16(let right)):
            return .i16(left - right)
        case (.i32(let left), .i32(let right)):
            return .i32(left - right)
        case (.i64(let left), .i64(let right)):
            return .i64(left - right)
        case (.float(let left), .float(let right)):
            return .float(left - right)
        case (.double(let left), .double(let right)):
            return .double(left - right)
        case (.compnum(let left), .compnum(let right)):
            return .compnum(left - right)
        case (.compfloat(let left), .compfloat(let right)):
            return .compfloat(left - right)
        case (.compint(let left), .compint(let right)):
            return .compint(left - right)
        case (.compuint(let left), .compuint(let right)):
            return .compuint(left - right)
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
        case (.u8(let left), .u8(let right)):
            return .u8(left * right)
        case (.u16(let left), .u16(let right)):
            return .u16(left * right)
        case (.u32(let left), .u32(let right)):
            return .u32(left * right)
        case (.u64(let left), .u64(let right)):
            return .u64(left * right)
        case (.i8(let left), .i8(let right)):
            return .i8(left * right)
        case (.i16(let left), .i16(let right)):
            return .i16(left * right)
        case (.i32(let left), .i32(let right)):
            return .i32(left * right)
        case (.i64(let left), .i64(let right)):
            return .i64(left * right)
        case (.float(let left), .float(let right)):
            return .float(left * right)
        case (.double(let left), .double(let right)):
            return .double(left * right)
        case (.compnum(let left), .compnum(let right)):
            return .compnum(left * right)
        case (.compfloat(let left), .compfloat(let right)):
            return .compfloat(left * right)
        case (.compint(let left), .compint(let right)):
            return .compint(left * right)
        case (.compuint(let left), .compuint(let right)):
            return .compuint(left * right)
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
        case (.u8(let left), .u8(let right)):
            return .u8(left / right)
        case (.u16(let left), .u16(let right)):
            return .u16(left / right)
        case (.u32(let left), .u32(let right)):
            return .u32(left / right)
        case (.u64(let left), .u64(let right)):
            return .u64(left / right)
        case (.i8(let left), .i8(let right)):
            return .i8(left / right)
        case (.i16(let left), .i16(let right)):
            return .i16(left / right)
        case (.i32(let left), .i32(let right)):
            return .i32(left / right)
        case (.i64(let left), .i64(let right)):
            return .i64(left / right)
        case (.float(let left), .float(let right)):
            return .float(left / right)
        case (.double(let left), .double(let right)):
            return .double(left / right)
        case (.compnum(let left), .compnum(let right)):
            return .compnum(left / right)
        case (.compfloat(let left), .compfloat(let right)):
            return .compfloat(left / right)
        case (.compint(let left), .compint(let right)):
            return .compint(left / right)
        case (.compuint(let left), .compuint(let right)):
            return .compuint(left / right)
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
// swiftlint:enable cyclomatic_complexity

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
    var statements: [any Statement]

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
            throw Diag(
                type: .expectedFunction, span: span, msg: "expected function, found \(val.type())")
        }
        var argVals: [(Value, Span)] = []
        for arg in args {
            let value = try arg.value(withEnv: env)
            argVals.append((value, arg.span))
        }
        return try funct.call(
            argVals, env: env, leftParen: Span(from: span.end - 1, to: span.end))
    }

    func valid(withEnv: Environment) -> Bool {
        todo()
    }

    func type(withEnv: Environment) -> Type? {
        todo()
    }

}

struct Coerce: Expression {
    let left: any Expression
    let type: any Expression
    let span: Span

    func value(withEnv env: Environment) throws -> Value {
        let val = try left.value(withEnv: env)
        let type = try type.toType(withEnv: env)
        guard let coerced = val.coerce(to: type)
        else {
            throw Diag(type: .coercionFailure, span: span, msg: "cannot coerce \(val.type()) to \(type)")
        }
        return coerced
    }

    func valid(withEnv env: Environment) -> Bool {
        (try? value(withEnv: env)) != nil
    }

    func type(withEnv env: Environment) -> Type? {
        try? type.toType(withEnv: env)
    }

}
