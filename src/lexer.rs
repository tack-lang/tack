use std::{
    ops::Range,
    str::{Chars, FromStr},
};

use codespan_reporting::diagnostic::Diagnostic;
use ordered_float::OrderedFloat;
use peek_again::{Peekable, PeekableIterator};

use crate::{
    diag::DiagExt,
    file::File,
    query::{QueryAccess, QueryDb},
    span::Span,
};

pub(crate) fn _lex(db: &QueryDb, file: File) -> Vec<Token> {
    let contents = db.contents(file);
    let lexer = Lexer::new(db, &contents, file);
    lexer.collect()
}

#[derive(Clone, Debug, Hash)]
pub struct Token {
    pub t_type: TokenType,
    pub span: Span,
}

impl Token {
    pub fn display(&self, db: &QueryDb) -> String {
        self.t_type.display(db)
    }
}

#[derive(Clone, Copy, Debug, Hash)]
pub enum TokenType {
    Ident(u64),

    // Delimeters
    OpenParen,
    CloseParen,
    OpenBracket,
    CloseBracket,
    OpenBrace,
    CloseBrace,
    OpenAngle,
    CloseAngle,

    // Literals
    String(u64),
    Number(OrderedFloat<f64>),

    // Special
    Lf,
    Comment,

    // Symbols
    Comma,
    Dot,
    Semicolon,

    // Arithmetic operators, and assignment operators
    Plus,
    PlusEq,
    Minus,
    MinusEq,
    Star,
    StarEq,
    Slash,
    SlashEq,
    Mod,
    ModEq,
    Eq,

    // Equality operators
    DoubleEq,
    BangEq,
    GreaterEq,
    LessEq,

    // Logic operators
    Bang,
    DoubleAmp,
    DoublePipe,

    // Bitwise operators, and assignment operators
    Amp, //   &: AND
    AmpEq,
    Pipe, //  |:  OR
    PipeEq,
    Carot, // ^: XOR
    CarotEq,
    Tilde, // ~: NOT

    // Keywords
    Fn,
    True,
    False,
    Identifier,
    Const,
    Var,
    Void,
}

impl TokenType {
    pub fn display(self, db: &QueryDb) -> String {
        match self {
            Self::Ident(str) => db.get_interned_string(str).unwrap().to_string(),

            Self::OpenParen => "(".to_string(),
            Self::CloseParen => ")".to_string(),
            Self::OpenBracket => "[".to_string(),
            Self::CloseBracket => "]".to_string(),
            Self::OpenBrace => "{".to_string(),
            Self::CloseBrace => "}".to_string(),
            Self::OpenAngle => "<".to_string(),
            Self::CloseAngle => ">".to_string(),

            Self::Number(n) => format!("{n}"),
            Self::String(str) => "\"".to_string() + &db.get_interned_string(str).unwrap() + "\"",

            Self::Lf => "<LINE FEED>".to_string(),
            Self::Comment => "<COMMENT>".to_string(),

            Self::Comma => ",".to_string(),
            Self::Dot => ".".to_string(),
            Self::Semicolon => ";".to_string(),

            Self::Plus => "+".to_string(),
            Self::PlusEq => "+=".to_string(),
            Self::Minus => "-".to_string(),
            Self::MinusEq => "-=".to_string(),
            Self::Star => "*".to_string(),
            Self::StarEq => "*=".to_string(),
            Self::Slash => "/".to_string(),
            Self::SlashEq => "/=".to_string(),
            Self::Mod => "%".to_string(),
            Self::ModEq => "%=".to_string(),
            Self::Eq => "=".to_string(),

            Self::DoubleEq => "==".to_string(),
            Self::BangEq => "!=".to_string(),
            Self::GreaterEq => ">=".to_string(),
            Self::LessEq => "<=".to_string(),

            Self::Bang => "!".to_string(),
            Self::DoubleAmp => "&&".to_string(),
            Self::DoublePipe => "||".to_string(),

            Self::Amp => "&".to_string(),
            Self::AmpEq => "&=".to_string(),
            Self::Pipe => "|".to_string(),
            Self::PipeEq => "|=".to_string(),
            Self::Carot => "^".to_string(),
            Self::CarotEq => "^=".to_string(),
            Self::Tilde => "~".to_string(),

            Self::Fn => "<FN>".to_string(),
            Self::True => "<TRUE>".to_string(),
            Self::False => "<FALSE>".to_string(),
            Self::Const => "<CONST>".to_string(),
            Self::Var => "<VAR>".to_string(),
            Self::Identifier => "<IDENTIFIER>".to_string(),
            Self::Void => "<VOID>".to_string(),
        }
    }
}

struct Lexer<'db> {
    db: &'db QueryDb,
    file: File,
    src: Peekable<Chars<'db>>,
    og_src: &'db str,
    span: Span,
}

impl<'db> Lexer<'db> {
    #[inline(always)]
    fn new(db: &'db QueryDb, src: &'db str, file: File) -> Self {
        Lexer {
            file,
            db,
            og_src: src,
            src: src.chars().peek_again(),
            span: Span::new(),
        }
    }

    #[inline(always)]
    fn next_char(&mut self) -> Option<char> {
        let char = self.src.next();
        if let Some(c) = char {
            self.span.grow_front(c.len_utf8()); // `Span` works by bytes, so adjust the span by the length of the character in bytes.
        }
        char
    }

    #[inline(always)]
    fn peek_char(&mut self) -> Option<char> {
        self.src.peek().get().copied()
    }

    #[inline(always)]
    fn at_eof(&mut self) -> bool {
        self.peek_char().is_none()
    }

    fn skip_whitespace(&mut self) {
        while matches!(self.peek_char(), Some(c) if c.is_whitespace() && c != '\n') {
            self.next_char();
        }

        self.span.start = self.span.end;
    }

    fn build_token(&mut self, t_type: TokenType) -> Token {
        Token {
            t_type,
            span: self.span.reset(),
        }
    }
}

impl<'db> Iterator for Lexer<'db> {
    type Item = Token;

    fn next(&mut self) -> Option<Self::Item> {
        self.skip_whitespace();
        if self.at_eof() {
            return None;
        }

        // Won't panic, we just made sure we weren't at EOF.
        match self.next_char().unwrap() {
            '\n' => Some(self.build_token(TokenType::Lf)),
            '(' => Some(self.build_token(TokenType::OpenParen)),
            ')' => Some(self.build_token(TokenType::CloseParen)),
            '[' => Some(self.build_token(TokenType::OpenBracket)),
            ']' => Some(self.build_token(TokenType::CloseBracket)),
            '{' => Some(self.build_token(TokenType::OpenBrace)),
            '}' => Some(self.build_token(TokenType::CloseBrace)),

            ',' => Some(self.build_token(TokenType::Comma)),
            '.' => Some(self.build_token(TokenType::Dot)),
            ';' => Some(self.build_token(TokenType::Semicolon)),

            '+' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::Plus)),
            '+' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::PlusEq))
            }
            '-' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::Minus)),
            '-' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::MinusEq))
            }
            '*' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::Star)),
            '*' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::StarEq))
            }
            '/' if self.peek_char() == Some('/') => {
                // Comment
                while let Some(c) = self.peek_char() {
                    if c == '\n' {
                        break;
                    }
                    self.next_char();
                }
                Some(self.build_token(TokenType::Comment))
            }
            '/' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::Slash)),
            '/' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::SlashEq))
            }
            '%' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::Mod)),
            '%' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::ModEq))
            }

            '!' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::Bang)),
            '!' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::BangEq))
            }
            '=' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::Eq)),
            '=' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::DoubleEq))
            }
            '<' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::OpenAngle)),
            '<' if self.peek_char() == Some('=') => Some(self.build_token(TokenType::LessEq)),
            '>' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::CloseAngle)),
            '>' if self.peek_char() == Some('=') => Some(self.build_token(TokenType::GreaterEq)),

            '&' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::AmpEq))
            }
            '&' if self.peek_char() == Some('&') => {
                self.next_char();
                Some(self.build_token(TokenType::DoubleAmp))
            }
            '&' if self.peek_char() != Some('&') => Some(self.build_token(TokenType::Amp)),

            '|' if self.peek_char() == Some('=') => {
                self.next_char();
                Some(self.build_token(TokenType::PipeEq))
            }
            '|' if self.peek_char() == Some('|') => {
                self.next_char();
                Some(self.build_token(TokenType::DoublePipe))
            }
            '|' if self.peek_char() != Some('|') => Some(self.build_token(TokenType::Pipe)),

            '^' if self.peek_char() == Some('=') => Some(self.build_token(TokenType::CarotEq)),
            '^' if self.peek_char() != Some('=') => Some(self.build_token(TokenType::Carot)),
            '~' => Some(self.build_token(TokenType::Tilde)),
            '"' => {
                while let Some(c) = self.peek_char() {
                    if c == '"' {
                        break;
                    }
                    self.next_char();
                }
                self.next_char();

                let contents = self.og_src;
                let mut range: Range<usize> = self.span.into();
                range.end -= 1; // Remove quotes
                range.start += 1;

                let ident = String::from_str(&contents[range]).unwrap(); // to_string() doesn't take advantage of the size, so this is more optimized
                let interned = self.db.intern_string(ident);
                Some(self.build_token(TokenType::String(interned)))
            }
            c if c.is_numeric() => {
                let mut ident = String::from(c);
                while let Some(c) = self.peek_char() {
                    if c.is_numeric() || c == '.' || c.eq_ignore_ascii_case(&'e') {
                        ident.push(c);
                    } else {
                        break;
                    }
                    self.next_char();
                }

                let res = ident.parse::<OrderedFloat<f64>>();
                if let Ok(n) = res {
                    Some(self.build_token(TokenType::Number(n)))
                } else {
                    Diagnostic::error()
                        .with_message("failed to parse number")
                        .with_span_primary(self.span, self.file)
                        .emit(self.db);
                    None
                }
            }
            c if c.is_alphabetic() || c == '_' => {
                while let Some(c) = self.peek_char() {
                    if c.is_alphanumeric() || c == '_' {
                        //ident.push(c);
                    } else {
                        break;
                    }
                    self.next_char();
                }

                let contents = self.og_src;
                let range: Range<usize> = self.span.into();

                let ident = String::from_str(&contents[range]).unwrap(); // to_string() doesn't take advantage of the size, so this is more optimized
                match ident.as_str() {
                    "fn" => Some(self.build_token(TokenType::Fn)),
                    "true" => Some(self.build_token(TokenType::True)),
                    "false" => Some(self.build_token(TokenType::False)),
                    "identifier" => Some(self.build_token(TokenType::Identifier)),
                    "const" => Some(self.build_token(TokenType::Const)),
                    "var" => Some(self.build_token(TokenType::Var)),
                    "void" => Some(self.build_token(TokenType::Void)),
                    _ => {
                        let interned = self.db.intern_string(ident);
                        Some(self.build_token(TokenType::Ident(interned)))
                    }
                }
            }
            c => {
                Diagnostic::error()
                    .with_message(format!("unexpected character `{c}`"))
                    .with_span_primary(self.span, self.file)
                    .emit(self.db);
                None
            }
        }
    }
}