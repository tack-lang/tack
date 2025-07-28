use std::collections::HashMap;

use crate::{file::File, lexer::Token};
use parking_lot::RwLock;
use serde::{Deserialize, Serialize};

use super::QueryDb;

impl Serialize for Box<QueryDb> {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let lex = self.lex.read();
        let strings = self.strings.read();
        let db = Box::new(SerializedQueryDb {
            lex: lex.clone(),
            strings: strings.clone(),
        });
        db.serialize(serializer)
    }
}

impl<'de> Deserialize<'de> for Box<QueryDb> {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let mut db = Box::new(QueryDb::default());
        let ser_db = SerializedQueryDb::deserialize(deserializer)?;
        db.lex = RwLock::new(ser_db.lex);
        db.strings = RwLock::new(ser_db.strings);
        Ok(db)
    }
}

#[derive(Serialize, Deserialize)]
struct SerializedQueryDb {
    lex: HashMap<File, Vec<Token>>,
    strings: HashMap<u64, String>,
}
