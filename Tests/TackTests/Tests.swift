import Foundation
import Testing

@testable import TackLib

func getTest(_ name: String) throws -> Vm {
    let url = try #require(
        Bundle.module.url(forResource: name, withExtension: "tck", subdirectory: "tests"))

    let file = try File(path: url)
    let vm = try Vm(src: file)
    return vm
}

@Test
func nativeSanityCheck() {
    let result = 2 + 3
    #expect(result == 5)
}

@Test
func sanityCheck() throws {
    let vm = try getTest("sanity")
    let value = try vm.runFunc(named: "main")
    #expect(value == Value.u32(5))
}

@Test
func complexSanityCheck() throws {
    let vm = try getTest("complexSanity")
    let value = try vm.runFunc(named: "main")
    #expect(value == Value.double(0.693))
}
