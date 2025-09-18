// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import TackLib

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

do {
    let vm = try Vm(src: file)
    vm.run()
} catch {
    guard let diag = error as? Diag else {
        fatalError("unknown error \(error)")
    }
    print(renderError(diag: diag, file: file))
}
