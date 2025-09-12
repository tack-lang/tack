// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
        print(items, separator: separator, terminator: terminator)
    #endif
}

func todo() -> Never {
    fatalError("not yet implemented")
}

func unreachable() -> Never {
    fatalError("unreachable code reached")
}

// Check if a file path argument was provided
guard CommandLine.arguments.count > 1 else {
    print("Error: Please provide a file path as an argument.")
    exit(1)
}

// Get the file path from the first argument (index 1)
let filePath = CommandLine.arguments[1]

var file: File
do {
    file = try File(path: filePath)
} catch {
    print("Error reading file at \"\(filePath)\": \(error.localizedDescription)")
    exit(1)
}

var lexer = Lexer(src: file)
var parser = Parser(lexer: lexer)
do {
    var env = Environment()
    try env.declareVariable(named: "world", as: .string)
    try env.setVariable(named: "world", to: .string("World!"))

    while let term = try parser.term() {
        print("\(term): \(try term.value(withEnv: env))")
    }
} catch {
    guard let error = error as? Diag else {
        // Crash program if unknown error
        throw error
    }

    print("\(renderError(diag: error, file: file))")
}
