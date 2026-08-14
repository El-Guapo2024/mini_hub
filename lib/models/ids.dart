/// Identifiers, as types rather than bare strings.
///
/// A question id and a topic slug are both strings, are passed side by side,
/// and mean entirely different things — `isDone(topic)` and
/// `progressFor(questionId)` would both have compiled and both silently
/// reported no progress. These are zero-cost at runtime: an extension type
/// erases to its representation, so nothing is allocated and nothing is
/// slower. They are deliberately not `implements String`, which would allow
/// the substitution they exist to prevent.
library;

/// Identifies one question, e.g. `bh.1.2.1.q1`. Provenance-derived and stable
/// across re-extraction, because the attempt log keys off it.
extension type const QuestionId(String value) {}

/// Identifies one lesson, e.g. `multiplying_by_11_trick`. The directory name
/// on disk and the slug attempts are grouped by.
extension type const TopicId(String value) {}
