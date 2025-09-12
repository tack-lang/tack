struct Span {
    var start: UInt
    var end: UInt

    init() {
        start = 0
        end = 0
    }

    init(from: UInt, to: UInt) {
        start = from
        end = to
    }

    // swiftlint:disable identifier_name
    mutating func growFront(by: UInt) {
        end += by
    }

    mutating func growBack(by: UInt) {
        start -= by
    }

    mutating func shrinkFront(by: UInt) {
        end -= by
    }

    mutating func shrinkBack(by: UInt) {
        start += by
    }
    // swiftlint:enable identifier_name

    mutating func reset() -> Self {
        let old = self
        start = end
        return old
    }

    func len() -> UInt {
        end - start
    }

    func isEmpty() -> Bool {
        len() == 0
    }

    // swiftlint:disable identifier_name
    func apply(to: String) -> Substring {
        let start = to.index(to.startIndex, offsetBy: Int(start))
        let end = to.index(to.startIndex, offsetBy: Int(end))

        return to[start ..< end]
    }
    // swiftlint:enable identifier_name
}
