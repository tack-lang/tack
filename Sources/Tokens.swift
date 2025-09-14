struct Identifier: Token {
    let span: Span
    let lexeme: String
    static let staticLexeme: String? = nil
}

// Literals
struct StringLit: Token {
    let span: Span
    let val: String

    var lexeme: String
    static let staticLexeme: String? = nil
}

struct NumLit: Token {
    let span: Span
    let val: Double
    let suffix: Character?

    var lexeme: String { String(val) }
    static let staticLexeme: String? = nil

    func toVal() -> Value {
        switch suffix {
        case "u":
            return .compuint(UInt(val))
        case "i":
            return .compint(Int(val))
        case "f", "d":
            return .compfloat(val)
        default:
            return .compnum(val)
        }
    }
}

// Symbols
struct OpenParen: Token {
    let span: Span

    var lexeme: String { "(" }
}

struct CloseParen: Token {
    let span: Span

    var lexeme: String { ")" }
}

struct OpenBrace: Token {
    let span: Span

    var lexeme: String { "{" }
}

struct CloseBrace: Token {
    let span: Span

    var lexeme: String { "}" }
}

struct Colon: Token {
    let span: Span

    var lexeme: String { ":" }
}

struct Comma: Token {
    let span: Span

    var lexeme: String { "," }
}

// Arithmetic
struct Plus: Token {
    let span: Span

    var lexeme: String { "+" }
}

struct Minus: Token {
    let span: Span

    var lexeme: String { "-" }
}

struct Star: Token {
    let span: Span

    var lexeme: String { "*" }
}

struct Slash: Token {
    let span: Span

    var lexeme: String { "/" }
}

// Keywords
struct VoidKey: Token {
    let span: Span

    var lexeme: String { "void" }
}

// swiftlint:disable:next type_name
struct As: Token {
    let span: Span

    var lexeme: String { "as" }
}

// swiftlint:disable:next type_name
struct U8: Token {
    let span: Span

    var lexeme: String { "u8" }
}

struct U16: Token {
    let span: Span

    var lexeme: String { "u16" }
}

struct U32: Token {
    let span: Span

    var lexeme: String { "u32" }
}

struct U64: Token {
    let span: Span

    var lexeme: String { "u64" }
}

// swiftlint:disable:next type_name
struct I8: Token {
    let span: Span

    var lexeme: String { "i8" }
}

struct I16: Token {
    let span: Span

    var lexeme: String { "i16" }
}

struct I32: Token {
    let span: Span

    var lexeme: String { "i32" }
}

struct I64: Token {
    let span: Span

    var lexeme: String { "i64" }
}

struct FloatKey: Token {
    let span: Span

    var lexeme: String { "float" }
}

struct DoubleKey: Token {
    let span: Span

    var lexeme: String { "double" }
}
