struct Identifier: Token {
    let span: Span
    let lexeme: String
}

// Literals
struct StringLit: Token {
    let span: Span
    let val: String

    var lexeme: String
}

struct NumLit: Token {
    let span: Span
    let val: UInt

    var lexeme: String { String(val) }
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

// Miscelaneous
struct NewLine: Token {
    let span: Span

    var lexeme: String { "\n" }
}
