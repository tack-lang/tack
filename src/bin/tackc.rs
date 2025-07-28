use std::{fs, io, path::PathBuf};

use clap::Parser;
use tack::{file::File, lexer::lex, query::QueryDb};

#[derive(Parser)]
struct Args {
    path: Option<PathBuf>,
}

fn main() {
    let res = secondary();
    if let Err(e) = res {
        println!("{e}");
    }
}

fn secondary() -> io::Result<()> {
    let db = Box::new(QueryDb::default());
    let args = Args::parse();
    let path = args
        .path
        .unwrap_or(PathBuf::from("tack-tests/hello-world/main.tck"));
    let contents = fs::read_to_string(&path)?;

    let example_file = File::new(&db, contents, path);
    let tokens = lex(&db, example_file);
    if db.emit_diags() {
        return Ok(());
    }

    for i in &*tokens {
        println!("{}", i.display(&db));
    }

    Ok(())
}
