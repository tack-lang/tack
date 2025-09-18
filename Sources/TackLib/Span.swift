public struct Span: Sendable, Equatable {
    var start: UInt
    var end: UInt

    public init() {
        start = 0
        end = 0
    }

    // swiftlint:disable identifier_name
    public init(from: UInt, to: UInt) {
        start = from
        end = to
    }

    public mutating func growFront(by: UInt) {
        end += by
    }

    public mutating func growBack(by: UInt) {
        start -= by
    }

    public mutating func shrinkFront(by: UInt) {
        end -= by
    }

    public mutating func shrinkBack(by: UInt) {
        start += by
    }
    // swiftlint:enable identifier_name

    public mutating func reset() -> Self {
        let old = self
        start = end
        return old
    }

    public func len() -> UInt {
        end - start
    }

    public func isEmpty() -> Bool {
        len() == 0
    }

    // swiftlint:disable:next identifier_name
    public func apply(to: String) -> Substring {
        let start = to.index(to.startIndex, offsetBy: Int(start))
        let end = to.index(to.startIndex, offsetBy: Int(end))

        return to[start ..< end]
    }
}
