use std::{
    hash::{DefaultHasher, Hash, Hasher},
    path::{Path, PathBuf},
};

use codespan_reporting::files;

use crate::query::{QueryAccess, QueryDb};

#[derive(Clone, Copy)]
pub struct File {
    hash: u64,
}

impl File {
    /// Creates a new [`File`], with the given contents.
    pub fn new(db: &QueryDb, contents: String, path: PathBuf) -> File {
        let mut hasher = DefaultHasher::new();
        contents.hash(&mut hasher);
        let hash = hasher.finish();
        let file = File { hash };
        let line_starts = files::line_starts(&contents).collect();
        let res = db.insert_file(
            file,
            InternFile {
                contents,
                path,
                line_starts,
            },
        );
        assert!(res.is_none(), "hash collision!"); // If Some, then we've reached a hash collision
        file
    }

    pub fn contents<'db>(&self, db: &'db QueryDb) -> QueryAccess<'db, str> {
        // If None, that means that this would be an incorrectly built file.
        QueryAccess::map(db.try_file(self).unwrap(), |x| x.contents.as_str())
    }

    pub fn path<'db>(&self, db: &'db QueryDb) -> QueryAccess<'db, Path> {
        // If None, that means that this would be an incorrectly built file.
        QueryAccess::map(db.try_file(self).unwrap(), |x| x.path.as_path())
    }

    pub fn line_starts<'db>(&self, db: &'db QueryDb) -> QueryAccess<'db, [usize]> {
        // If None, that means that this would be an incorrectly built file.
        QueryAccess::map(db.try_file(self).unwrap(), |x| x.line_starts.as_slice())
    }

    /// Return the starting byte index of the line with the specified line index.
    /// Convenience method that already generates errors if necessary.
    pub(crate) fn line_start(
        &self,
        db: &QueryDb,
        line_index: usize,
    ) -> Result<usize, files::Error> {
        use core::cmp::Ordering;
        let lock = db.try_file(self).unwrap();

        match line_index.cmp(&lock.line_starts.len()) {
            Ordering::Less => Ok(lock
                .line_starts
                .get(line_index)
                .cloned()
                .expect("failed despite previous check")),
            Ordering::Equal => Ok(lock.contents.as_str().len()),
            Ordering::Greater => Err(files::Error::LineTooLarge {
                given: line_index,
                max: lock.line_starts.len() - 1,
            }),
        }
    }
}

impl Hash for File {
    #[inline(always)]
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        state.write_u64(self.hash);
    }
}

impl PartialEq for File {
    #[inline(always)]
    fn eq(&self, other: &Self) -> bool {
        self.hash == other.hash
    }
}

impl Eq for File {}

pub struct InternFile {
    contents: String,
    path: PathBuf,
    line_starts: Vec<usize>,
}
