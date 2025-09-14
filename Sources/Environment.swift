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

struct RuntimeVariable {
    let constant: Bool
    let type: Type
    var value: Value?

    mutating func set(to value: Value) throws {
        guard value.type() == type else {
            throw VariableError.wrongType(tried: value.type(), actual: type)
        }
        self.value = value
    }

    func get() -> Value? {
        value
    }

    func isInitialized() -> Bool {
        value != nil
    }
}

struct Environment {
    var variables: [String: RuntimeVariable] = Dictionary()
    @Indirect var parent: Environment?

    init() {}

    init(_ env: Environment) {
        parent = env
    }

    func root() -> Environment {
        parent?.root() ?? self
    }

    func getVariable(named name: String) -> RuntimeVariable? {
        guard let value = variables[name] else {
            return parent?.getVariable(named: name)
        }
        return value
    }

    func variableExists(named name: String) -> Bool {
        guard variables[name] != nil else {
            return parent?.variableExists(named: name) == true
        }
        return true
    }

    mutating func declareConstant(named name: String, to value: Value) throws {
        guard variables[name] == nil else {
            throw VariableError.alreadyExists(name: name)
        }
        variables[name] = RuntimeVariable(constant: true, type: value.type(), value: value)
    }

    mutating func declareVariable(named name: String, as type: Type) throws {
        guard variables[name] == nil else {
            throw VariableError.alreadyExists(name: name)
        }
        variables[name] = RuntimeVariable(constant: false, type: type)
    }

    mutating func setVariable(named name: String, to value: Value) throws {
        guard variables[name] != nil else {
            guard try parent?.setVariable(named: name, to: value) != nil else {
                throw VariableError.doesntExist(name: name)
            }
            return
        }
        try variables[name]!.set(to: value)
    }
}
