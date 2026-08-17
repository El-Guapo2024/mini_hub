/// Every value that tunes the app, in one place.
///
/// These are decisions, not facts: numbers someone might reasonably want to
/// change without reading the code that uses them. Scattered through the files
/// that happen to read them, they are impossible to review together — you
/// cannot tell what the app assumes without finding all of them first.
///
/// What does *not* belong here: grading rules, which are properties of a
/// question and live on its answer; and colours, which are theme.
library;

/// Where the app reads its content from.
///
/// Every path the app loads — course, topic, lesson, questions — is derived
/// from an entry in the index, so this is the whole switch. Nothing else names
/// an asset directory, and nothing else should: a second hardcoded path is how
/// a build ends up half real and half sample.
enum ContentSource {
  /// The shipped bank. What a build serves unless told otherwise.
  real('assets/content/courses.json'),

  /// A small stand-in course for demos and screenshots, so neither of those
  /// needs the real bank to be finished or correct.
  sample('assets/sample/courses.json');

  const ContentSource(this.indexPath);

  /// The JSON file naming every course this source offers.
  final String indexPath;

  /// Throws on a name that is not a source. A typo in a build flag silently
  /// serving the real bank is the kind of default that hides itself.
  static ContentSource byName(String name) => values.byName(name);
}

/// The app's settings, read once at startup.
///
/// Defaults are overridden at build time, so a demo build needs no edit to a
/// source file:
///
///     flutter run --dart-define=CONTENT=sample
class AppConfig {
  const AppConfig({
    this.content = ContentSource.real,
    this.databaseFile = 'attempts.db',
    this.maxAnswerTime = const Duration(minutes: 1),
    this.advanceAfter = const Duration(milliseconds: 700),
  });

  /// Which bank the build serves.
  final ContentSource content;

  /// The attempt log, inside the app's documents directory.
  final String databaseFile;

  /// Number sense is a timed event, so an answer taken this long is not really
  /// an answer. Attempts slower than this record no time at all, rather than
  /// letting a question left open overnight wreck the averages.
  final Duration maxAnswerTime;

  /// How long a correct answer stays on screen before practice moves to the
  /// next card. Long enough to register the green, short enough not to be a
  /// wait.
  final Duration advanceAfter;

  /// The configuration this build runs with. Read once, at startup, so the
  /// app cannot behave as though two different settings were in force.
  static final AppConfig current = AppConfig(
    content: ContentSource.byName(
      const String.fromEnvironment('CONTENT', defaultValue: 'real'),
    ),
  );
}
