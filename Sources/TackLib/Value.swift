public enum Value: Equatable {
    // swiftlint:disable:next identifier_name
    case u8(UInt8)
    case u16(UInt16)
    case u32(UInt32)
    case u64(UInt64)
    // swiftlint:disable:next identifier_name
    case i8(Int8)
    case i16(Int16)
    case i32(Int32)
    case i64(Int64)

    case float(Float)
    case double(Double)
    case string(String)
    case void
    case type(Type)
    case function(Function)

    case compuint(UInt)
    case compint(Int)
    case compfloat(Double)
    case compnum(Double)

    // swiftlint:disable:next cyclomatic_complexity
    func type() -> Type {
        switch self {
        case .u8:
            .u8
        case .u16:
            .u16
        case .u32:
            .u32
        case .u64:
            .u64
        case .i8:
            .i8
        case .i16:
            .i16
        case .i32:
            .i32
        case .i64:
            .i64
        case .float:
            .float
        case .double:
            .double
        case .string:
            .string
        case .void:
            .void
        case .type:
            .type
        case .function:
            .function
        case .compint:
            .compint
        case .compuint:
            .compuint
        case .compfloat:
            .compfloat
        case .compnum:
            .compnum
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func coerce(to type: Type) -> Value? {
        if type == .void {
            return .void
        }
        if self.type() == type {
            return self
        }
        if self.type() == .string || type == .string {
            return nil
        }
        if self.type() == .function || type == .function {
            return nil
        }
        if self.type() == .type || type == .type {
            return nil
        }
        let value: CoercingValue
        switch self {
        case .u8(let num):
            value = .uint(UInt(num))
        case .u16(let num):
            value = .uint(UInt(num))
        case .u32(let num):
            value = .uint(UInt(num))
        case .u64(let num):
            value = .uint(UInt(num))
        case .i8(let num):
            value = .int(Int(num))
        case .i16(let num):
            value = .int(Int(num))
        case .i32(let num):
            value = .int(Int(num))
        case .i64(let num):
            value = .int(Int(num))
        case .float(let num):
            value = .float(Double(num))
        case .double(let num):
            value = .float(num)
        case .string, .function, .type, .void:
            unreachable()
        case .compfloat(let num):
            value = .float(num)
        case .compuint(let num):
            value = .uint(num)
        case .compint(let num):
            value = .int(num)
        case .compnum(let num):
            value = .compnum(num)
        }
        switch (value, type) {
        case (.uint(let num), .u8):
            return .u8(UInt8(num))
        case (.uint(let num), .u16):
            return .u16(UInt16(num))
        case (.uint(let num), .u32):
            return .u32(UInt32(num))
        case (.uint(let num), .u64):
            return .u64(UInt64(num))
        case (.uint(let num), .i8):
            return .i8(Int8(num))
        case (.uint(let num), .i16):
            return .i16(Int16(num))
        case (.uint(let num), .i32):
            return .i32(Int32(num))
        case (.uint(let num), .i64):
            return .i64(Int64(num))

        case (.int(let num), .i8):
            return .i8(Int8(num))
        case (.int(let num), .i16):
            return .i16(Int16(num))
        case (.int(let num), .i32):
            return .i32(Int32(num))
        case (.int(let num), .i64):
            return .i64(Int64(num))

        case (.float(let num), .float):
            return .float(Float(num))
        case (.float(let num), .double):
            return .double(Double(num))

        case (.compnum(let num), .u8):
            return .u8(UInt8(num))
        case (.compnum(let num), .u16):
            return .u16(UInt16(num))
        case (.compnum(let num), .u32):
            return .u32(UInt32(num))
        case (.compnum(let num), .u64):
            return .u64(UInt64(num))
        case (.compnum(let num), .i8):
            return .i8(Int8(num))
        case (.compnum(let num), .i16):
            return .i16(Int16(num))
        case (.compnum(let num), .i32):
            return .i32(Int32(num))
        case (.compnum(let num), .i64):
            return .i64(Int64(num))
        case (.compnum(let num), .float):
            return .float(Float(num))
        case (.compnum(let num), .double):
            return .double(Double(num))

        default:
            return nil
        }
    }
}

enum CoercingValue {
    case uint(UInt)
    case int(Int)
    case float(Double)

    case compnum(Double)
}

public enum Type: Sendable {
    // swiftlint:disable:next identifier_name
    case u8
    case u16
    case u32
    case u64
    // swiftlint:disable:next identifier_name
    case i8
    case i16
    case i32
    case i64

    case float
    case double
    case string
    case void
    case type
    case function

    case compint
    case compuint
    case compfloat
    case compnum
}
