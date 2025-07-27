use codespan_reporting::diagnostic::{Diagnostic, Label, Severity};

use crate::{file::File, query::QueryDb, span::Span};

pub trait DiagExt {
    fn with_span_primary(self, span: Span, file: File) -> Self;
    fn with_span_secondary(self, span: Span, file: File) -> Self;
    fn emit(self, db: &QueryDb);
}

impl DiagExt for Diagnostic<File> {
    fn with_span_primary(self, span: Span, file: File) -> Self {
        self.with_label(Label::primary(file, span))
    }

    fn with_span_secondary(self, span: Span, file: File) -> Self {
        self.with_label(Label::secondary(file, span))
    }

    fn emit(self, db: &QueryDb) {
        match self.severity {
            Severity::Help | Severity::Note => db.push_info(self),
            Severity::Bug => db.push_bug(self),
            Severity::Error => db.push_error(self),
            Severity::Warning => db.push_warning(self),
        }
    }
}
