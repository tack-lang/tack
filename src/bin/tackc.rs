use std::{fs, io, path::PathBuf};

use clap::Parser;
use log::trace;
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
    clang_log::init(log::Level::Trace, "tackc");
    let args = Args::parse();
    let path = args
        .path
        .unwrap_or(PathBuf::from("tack-tests/hello-world/main.tck"));
    let db = if let Some(path) = path.parent()
        && let Ok(bytes) = fs::read(path.join("db.bin"))
    {
        let res = postcard::from_bytes(&bytes);
        if let Ok(db) = res {
            trace!("db cache hit");
            db
        } else if let Err(e) = res {
            trace!("db cache miss: {e}");
            Box::new(QueryDb::default())
        } else {
            unreachable!()
        }
    } else {
        trace!("db cache miss");
        Box::new(QueryDb::default())
    };
    let contents = fs::read_to_string(&path)?;

    let example_file = File::new(&db, contents, path.clone());
    let tokens = lex(&db, example_file);
    if db.emit_diags() {
        return Ok(());
    }

    for i in &*tokens {
        println!("{}", i.display(&db));
    }

    if let Ok(bytes) = postcard::to_allocvec(&db)
        && let Some(path) = path.parent()
    {
        let db_path = path.to_path_buf().join("db.bin");
        fs::write(db_path, bytes)?;
    }

    Ok(())
}
