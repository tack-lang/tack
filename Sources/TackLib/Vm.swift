public struct Vm {
    var env: Environment = Environment()
    let file: File

    public init(src file: File) throws {
        self.file = file
        let lexer = Lexer(src: file)
        var parser = Parser(lexer: lexer)
        var constants: [Constant] = []
        while let item = try parser.item() {
            switch item {
            case .constant(let constant):
                constants.append(constant)
            }
        }

        try prepareEnv()

        while !constants.isEmpty {
            var newConstants: [Constant] = []
            for constant in constants {
                do {
                    let value = try constant.value.value(withEnv: env)
                    try env.declareConstant(named: constant.name.lexeme, to: value, at: constant.value.span)
                } catch {
                    newConstants.append(constant)
                }
            }
            if newConstants.count == constants.count {
                _ = try newConstants[0].value.value(withEnv: env)
            }
            constants = newConstants
        }
    }

    mutating private func prepareEnv() throws {
        try addFunc(NativeFunction("println", println))
    }

    mutating public func addFunc(_ funct: NativeFunction) throws {
        try env.declareConstant(
            named: funct.name, to: .function(.native(funct)), at: Span()
        )
    }

    public func run() {
        do {
            let main = env.getVariable(named: "main")
            switch main?.get() {
            case .function(let funct):
                switch funct {
                case .tack(let funct):
                    guard funct.params.count == 0 else {
                        throw Diag(
                            type: .wrongType, span: Span(), msg: "wrong signature for main function"
                        )
                    }
                default: unreachable()
                }
                _ = try funct.call([], env: env, leftParen: Span())
            case .some:
                throw Diag(type: .wrongType, span: Span(), msg: "wrong type for main function")
            default: throw Diag(type: .missingMain, span: Span())
            }
        } catch {
            guard let diag = error as? Diag else {
                fatalError("unknown error \(error)")
            }
            print(renderError(diag: diag, file: file))
        }
    }

    public func runFunc(named name: String) throws -> Value? {
        let main = env.getVariable(named: name)
        switch main?.get() {
        case .function(let funct):
            return try funct.call([], env: env, leftParen: Span())
        case .some:
            print("not function")
            return nil
        default:
            print("doesn't exist")
            return nil
        }
    }
}

func println(_ arguments: [(Value, Span)], _ env: Environment, _ span: Span) throws -> Value {
    for (value, _) in arguments {
        switch value {
        case .u8(let num):
            print(num)
        case .u16(let num):
            print(num)
        case .u32(let num):
            print(num)
        case .u64(let num):
            print(num)
        case .i8(let num):
            print(num)
        case .i16(let num):
            print(num)
        case .i32(let num):
            print(num)
        case .i64(let num):
            print(num)
        case .float(let num):
            print(num)
        case .double(let num):
            print(num)
        case .string(let str):
            print(str)
        case .void:
            print("void")
        case .type(let type):
            print(type)
        case .function(let funct):
            print(funct)
        case .compuint(let num):
            print(num)
        case .compint(let num):
            print(num)
        case .compfloat(let num):
            print(num)
        case .compnum(let num):
            print(num)
        }
    }
    return .void
}
