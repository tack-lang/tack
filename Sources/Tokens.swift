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

    var lexeme: String { String(val) }
    static let staticLexeme: String? = nil
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
struct Void: Token {
    let span: Span

    var lexeme: String { "void" }
}
