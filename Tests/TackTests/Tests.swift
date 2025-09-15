import Testing
@testable import TackLib

@Test
func sanityCheck() {
    let result = 2 + 3
    #expect(result == 5)
}
