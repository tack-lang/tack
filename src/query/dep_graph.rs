use crate::file::File;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Node {
    pub query: Query,
    pub deps: Vec<Node>,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Copy)]
pub enum Query {
    Lex(File),

    String(u64),

    Contents(File),
    Path(File),
    LineStarts(File),
}
