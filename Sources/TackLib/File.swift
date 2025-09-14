import Foundation

public struct File {
    let source: String
    let path: URL
    let ogPath: String?

    public init(path: String) throws {
        self.path = URL(fileURLWithPath: path)
        ogPath = path
        source = try String(contentsOf: self.path, encoding: .utf8)
    }

    public func getPath() -> String {
        if let str = ogPath {
            str
        } else {
            path.absoluteString
        }
    }

    func eofSpan() -> Span {
        Span(from: UInt(self.source.count), to: UInt(self.source.count))
    }
}
