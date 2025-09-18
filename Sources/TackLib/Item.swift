public enum Item {
    case constant(Constant)
}

public struct Constant {
    public let name: Identifier
    public let value: any Expression
}
