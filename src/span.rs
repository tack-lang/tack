use std::{cmp::Ordering, ops::Range};

use serde::{Deserialize, Serialize};

/// The `Span` type represents an area of a file.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, Serialize, Deserialize)]
pub struct Span {
    pub start: usize,
    pub end: usize,
}

impl Span {
    /// Creates a new `Span`. This span will start and end at the 0th byte, making it have a length of zero.
    #[inline(always)]
    pub fn new() -> Self {
        Self::new_from(0, 0)
    }

    /// Creates a new `Span` from a pair of start and end indexes. These indexes are indexes into a string by bytes.
    #[inline(always)]
    pub fn new_from(start: usize, end: usize) -> Self {
        Span { start, end }
    }

    /// Grows the span from the front. This moves the end value up by `amount`.
    #[inline(always)]
    pub fn grow_front(&mut self, amount: usize) {
        self.end += amount;
    }

    /// Grows the span from the back. This moves the start value back by `amount`.
    #[inline(always)]
    pub fn grow_back(&mut self, amount: usize) {
        self.start -= amount;
    }

    /// Shrinks the span from the back. This moves the start value up by `amount`.
    ///
    /// # Panics
    /// This method will panic if the size of the `Span` is less than `amount`, since a `Span`'s size can't be negative.
    #[inline(always)]
    pub fn shrink_back(&mut self, amount: usize) {
        if self.len() < amount {
            panic!("cannot create negative-size span");
        }
        self.start += amount;
    }

    /// Shrinks the span from the front. This moves the end value back by `amount`.
    ///
    /// # Panics
    /// This method will panic if the size of the `Span` is less than `amount`, since a `Span`'s size can't be negative.
    #[inline(always)]
    pub fn shrink_front(&mut self, amount: usize) {
        if self.len() < amount {
            panic!("cannot create negative-size span");
        }
        self.end -= amount;
    }

    /// Checks if a `Span`'s size is `0`. Returns `true` if `0`, and false if anything else.
    #[inline(always)]
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Gets the length of a `Span`.
    #[inline(always)]
    pub fn len(&self) -> usize {
        self.end - self.start
    }

    #[inline(always)]
    /// Resets `self` by changing the start to be the end, plus 1, and changing the end to be the start.
    /// The function also returns the old span.
    pub fn reset(&mut self) -> Self {
        let span = *self;
        self.start = self.end;
        span
    }
}

impl From<Span> for Range<usize> {
    #[inline(always)]
    fn from(val: Span) -> Self {
        val.start..val.end
    }
}

impl From<Range<usize>> for Span {
    #[inline(always)]
    fn from(value: Range<usize>) -> Self {
        Self::new_from(value.start, value.end)
    }
}

impl PartialOrd for Span {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        dual_order(self.start.cmp(&other.start), self.end.cmp(&other.end))
    }
}

fn dual_order(x: Ordering, y: Ordering) -> Option<Ordering> {
    match (x, y) {
        (x, y) if x == y => Some(x),
        (Ordering::Greater, Ordering::Less) | (Ordering::Less, Ordering::Greater) => None,
        (x, Ordering::Equal) => Some(x),
        (Ordering::Equal, x) => Some(x),
        _ => unreachable!(),
    }
}

#[test]
fn ordering_test() {
    use itertools::Itertools;
    let all = [Ordering::Greater, Ordering::Less, Ordering::Equal];
    for i in [all, all].iter().multi_cartesian_product() {
        print!("{:?}: ", (*i[0], *i[1]));
        let res = dual_order(*i[0], *i[1]);
        println!("{res:?}");
    }
}
