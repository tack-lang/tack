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
