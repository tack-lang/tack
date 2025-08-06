use std::{
    collections::{HashMap, hash_map::Entry},
    fmt::Display,
    hash::{DefaultHasher, Hash, Hasher},
    ops::Deref,
    path::Path,
};

use codespan_reporting::{
    diagnostic::Diagnostic,
    files::Files,
    term::{
        self, Config,
        termcolor::{ColorChoice, StandardStream},
    },
};
use parking_lot::{MappedRwLockReadGuard, RwLock, RwLockReadGuard};

use crate::{
    file::{File, InternFile},
    lexer::Token,
};

#[derive(Default)]
/// This struct is very large, so it is reccommended that you build it on the heap instead of the stack.
pub struct QueryDb {
    /// File contents
    files: RwLock<HashMap<File, InternFile>>,
    /// Interned strings
    strings: RwLock<HashMap<u64, String>>,


    /// Error diagnostic messages
    error: RwLock<Vec<Diagnostic<File>>>,
    /// Warning diagnostic messages
    warning: RwLock<Vec<Diagnostic<File>>>,
    /// Info diagnostic messages
    info: RwLock<Vec<Diagnostic<File>>>,
    /// Bug diagnostic messages
    bug: RwLock<Vec<Diagnostic<File>>>,
}

impl QueryDb {
    /// Attempts to retrieve a value from the given map, based on the key.
    /// If there is no value, this function will return [`None`].
    fn try_get<'db, K: Eq + Hash, V>(
        map: &'db RwLock<HashMap<K, V>>,
        key: &K,
    ) -> Option<QueryAccess<'db, V>> {
        let lock = map.read();

        RwLockReadGuard::try_map(lock, |map| map.get(key))
            .ok()
            .map(QueryAccess::new)
    }

    /// Inserts a key-value pair into the given map, as long as there is not an existing value.
    /// If a value is already there, this function will do nothing, and return [`Some(val)`](Some).
    fn insert<K: Eq + Hash, V>(map: &RwLock<HashMap<K, V>>, key: K, val: V) -> Option<V> {
        let mut lock = map.write();

        if let Entry::Vacant(e) = lock.entry(key) {
            e.insert(val);
            None
        } else {
            Some(val)
        }
    }

    /// Attempts to retrieve a value from the `file` map, based on the key.
    /// If there is no value, this function will return [`None`].
    #[inline(always)]
    pub fn try_file(&self, key: &File) -> Option<QueryAccess<'_, InternFile>> {
        Self::try_get(&self.files, key)
    }

    /// Inserts a key-value pair into the `file` map, as long as there is not an existing value.
    /// If a value is already there, this function will do nothing, and return `Some(val)`.
    #[inline(always)]
    pub fn insert_file(&self, key: File, val: InternFile) -> Option<InternFile> {
        Self::insert(&self.files, key, val)
    }

    /// Interns a new string and returns the interned ID.
    pub fn intern_string(&self, string: String) -> u64 {
        let mut lock = self.strings.write();
        let mut hasher = DefaultHasher::new();
        string.hash(&mut hasher);
        let hash = hasher.finish(); // Use hash as key
        lock.insert(hash, string); // Ignore if the String is already there
        hash
    }

    pub fn get_interned_string(&self, id: u64) -> Option<QueryAccess<'_, str>> {
        Self::try_get(&self.strings, &id).map(|x| QueryAccess::map(x, |x| x.as_str()))
    }

    /// Pushes an error to the list of errors.
    pub fn push_error(&self, error: Diagnostic<File>) {
        self.error.write().push(error);
    }

    /// Takes the list of errors.
    pub fn take_error(&self) -> Vec<Diagnostic<File>> {
        self.error.write().drain(..).collect()
    }

    /// Pushes a warning to the list of warnings.
    pub fn push_warning(&self, warning: Diagnostic<File>) {
        self.warning.write().push(warning);
    }

    /// Takes the list of warnings.
    pub fn take_warning(&self) -> Vec<Diagnostic<File>> {
        self.warning.write().drain(..).collect()
    }

    /// Pushes an info message to the list of info messages.
    pub fn push_info(&self, msg: Diagnostic<File>) {
        self.info.write().push(msg);
    }

    /// Takes the list of info messages.
    pub fn take_info(&self) -> Vec<Diagnostic<File>> {
        self.info.write().drain(..).collect()
    }

    /// Pushes a bug to the list of bugs.
    pub fn push_bug(&self, msg: Diagnostic<File>) {
        self.bug.write().push(msg);
    }

    /// Takes the list of bugs.
    pub fn take_bug(&self) -> Vec<Diagnostic<File>> {
        self.bug.write().drain(..).collect()
    }

    /// Takes a list of all diagnostic messages.
    pub fn take_diags(&self) -> Vec<Diagnostic<File>> {
        let mut vec = self.take_bug();
        vec.append(&mut self.take_error());
        vec.append(&mut self.take_warning());
        vec.append(&mut self.take_info());
        vec
    }

    /// Emits all diagnostic messages onto stderr, returning true if errors were emitted.
    pub fn emit_diags(&self) -> bool {
        let diags = self.take_diags();
        let ret = !diags.is_empty();
        let mut writer = StandardStream::stderr(ColorChoice::Always);
        for i in diags {
            term::emit(&mut writer, &Config::default(), self, &i).unwrap();
        }
        ret
    }
}

impl<'db> Files<'db> for QueryDb {
    type FileId = File;
    type Name = QueryAccess<'db, Path>;
    type Source = QueryAccess<'db, str>;

    fn name(&'db self, id: Self::FileId) -> Result<Self::Name, codespan_reporting::files::Error> {
        Ok(id.path(self))
    }

    fn source(
        &'db self,
        id: Self::FileId,
    ) -> Result<Self::Source, codespan_reporting::files::Error> {
        Ok(id.contents(self))
    }

    fn line_index(
        &'db self,
        id: Self::FileId,
        byte_index: usize,
    ) -> Result<usize, codespan_reporting::files::Error> {
        Ok(id
            .line_starts(self)
            .binary_search(&byte_index)
            .unwrap_or_else(|next_line| next_line - 1))
    }

    fn line_range(
        &'db self,
        id: Self::FileId,
        line_index: usize,
    ) -> Result<std::ops::Range<usize>, codespan_reporting::files::Error> {
        let line_start = id.line_start(self, line_index)?;
        let next_line_start = id.line_start(self, line_index + 1)?;

        Ok(line_start..next_line_start)
    }
}

pub struct QueryAccess<'db, T: ?Sized> {
    inner: MappedRwLockReadGuard<'db, T>,
}

impl<'db, T: ?Sized> QueryAccess<'db, T> {
    #[inline(always)]
    fn new(inner: MappedRwLockReadGuard<'db, T>) -> Self {
        QueryAccess { inner }
    }

    /// Maps the inner value of the [`QueryAccess`] struct to be a different value.
    #[inline(always)]
    pub fn map<U: ?Sized>(s: Self, f: impl FnOnce(&T) -> &U) -> QueryAccess<'db, U> {
        QueryAccess::new(MappedRwLockReadGuard::map(s.inner, f))
    }

    /// Attempts to map the inner value of the [`QueryAccess`] struct to be a different value.
    /// If the closure fails, the function will return an [`Err`] variant containing the original [`QueryAccess`].
    #[inline(always)]
    pub fn try_map<U: ?Sized>(
        s: Self,
        f: impl FnOnce(&T) -> Option<&U>,
    ) -> Result<QueryAccess<'db, U>, Self> {
        match MappedRwLockReadGuard::try_map(s.inner, f) {
            Ok(guard) => Ok(QueryAccess::new(guard)),
            Err(guard) => Err(QueryAccess::new(guard)),
        }
    }
}

impl<'db, T: ?Sized> Deref for QueryAccess<'db, T> {
    type Target = T;

    #[inline(always)]
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl<'db> Display for QueryAccess<'db, Path> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.display())
    }
}

impl<'db, T: ?Sized> AsRef<T> for QueryAccess<'db, T> {
    fn as_ref(&self) -> &T {
        self
    }
}
