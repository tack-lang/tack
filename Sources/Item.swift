enum Item {
    case constant(Constant)
}

struct Constant {
    let name: Identifier
    let value: Expression
}
