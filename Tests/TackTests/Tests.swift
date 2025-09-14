import Testing
@testable import TackLib

@Test
func sanityCheck() {
    let result = 2 + 2
    #expect(result == 4)
}
