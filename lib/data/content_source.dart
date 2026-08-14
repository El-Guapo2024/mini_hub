/// Where the app reads its content from.
///
/// Every path the app loads — course, topic, lesson, questions — is derived
/// from an entry in the index, so this one file is the whole switch. Nothing
/// else names an asset directory, and nothing else should: a second hardcoded
/// path is how a build ends up half real and half sample.
enum ContentSource {
  /// The shipped bank. What a build serves unless told otherwise.
  real('assets/content/courses.json'),

  /// A small stand-in course for demos and screenshots, so neither of those
  /// needs the real bank to be finished or correct.
  sample('assets/sample/courses.json');

  const ContentSource(this.indexPath);

  /// The JSON file naming every course this source offers.
  final String indexPath;

  /// Chosen at build time: `flutter run --dart-define=CONTENT=sample`.
  /// An unrecognised name falls back to [real] rather than failing to start,
  /// since a typo here should not look like the content is missing.
  static final ContentSource current = values.firstWhere(
    (source) => source.name == _selected,
    orElse: () => real,
  );

  static const _selected = String.fromEnvironment(
    'CONTENT',
    defaultValue: 'real',
  );
}
