import Testing
@testable import Tack

struct MyTests {
    @Test func sanityCheck() {
        let result = 1 + 2
        #expect(result == 3)
    }
}
