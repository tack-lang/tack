@propertyWrapper
class Indirect<T> {
    var wrappedValue: T
    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

enum VariableError: Error {
    case wrongType(tried: Type, actual: Type)
    case doesntExist(name: String)
    case alreadyExists(name: String)
}

public struct RuntimeVariable {
    let constant: Bool
    let type: Type
    var value: (Value, Span)?

    public mutating func set(to value: Value, at span: Span) throws {
        guard value.type() == type else {
            throw VariableError.wrongType(tried: value.type(), actual: type)
        }
        self.value = (value, span)
    }

    public func get() -> Value? {
        value?.0
    }

    public func at() -> Span? {
        value?.1
    }

    public func isInitialized() -> Bool {
        value != nil
    }
}

public struct Environment {
    var variables: [String: RuntimeVariable] = Dictionary()
    @Indirect var parent: Environment?

    public init() {}

    public init(_ env: Environment) {
        parent = env
    }

    public func root() -> Environment {
        parent?.root() ?? self
    }

    public func getVariable(named name: String) -> RuntimeVariable? {
        guard let value = variables[name] else {
            return parent?.getVariable(named: name)
        }
        return value
    }

    public func variableExists(named name: String) -> Bool {
        guard variables[name] != nil else {
            return parent?.variableExists(named: name) == true
        }
        return true
    }

    public mutating func declareConstant(named name: String, to value: Value, at span: Span) throws {
        guard variables[name] == nil else {
            throw VariableError.alreadyExists(name: name)
        }
        variables[name] = RuntimeVariable(constant: true, type: value.type(), value: (value, span))
    }

    public mutating func declareVariable(named name: String, as type: Type) throws {
        guard variables[name] == nil else {
            throw VariableError.alreadyExists(name: name)
        }
        variables[name] = RuntimeVariable(constant: false, type: type)
    }

    public mutating func setVariable(named name: String, to value: Value, at span: Span) throws {
        guard variables[name] != nil else {
            guard try parent?.setVariable(named: name, to: value, at: span) != nil else {
                throw VariableError.doesntExist(name: name)
            }
            return
        }
        try variables[name]!.set(to: value, at: span)
    }
}
