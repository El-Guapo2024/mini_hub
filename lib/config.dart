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

  static ContentSource byName(String name) =>
      values.firstWhere((source) => source.name == name, orElse: () => real);
}

/// The app's settings, read once at startup.
///
/// Defaults are overridden at build time, so a demo build or an experiment in
/// the review tuning needs no edit to a source file:
///
///     flutter run --dart-define=CONTENT=sample --dart-define=ROLLING_WINDOW=20
class AppConfig {
  const AppConfig({
    this.content = ContentSource.real,
    this.databaseFile = 'attempts.db',
    this.rollingWindow = 10,
    this.staleAfterDays = 30,
    this.weaknessWeight = 0.6,
    this.maxAnswerTime = const Duration(minutes: 1),
  });

  /// Which bank the build serves. An unrecognised name falls back to the real
  /// one rather than failing to start: a typo in a build flag should not look
  /// like the content is missing.
  final ContentSource content;

  /// The attempt log, inside the app's documents directory.
  final String databaseFile;

  /// How many recent attempts a topic's current accuracy is measured over.
  /// Lifetime accuracy lags for weeks after a student has actually improved.
  final int rollingWindow;

  /// Days after which a lesson counts as fully stale and is due for review.
  final int staleAfterDays;

  /// How much review priority is weakness rather than staleness, 0 to 1. At
  /// 0.6 a weak topic outranks a merely old one, but not forever.
  final double weaknessWeight;

  /// Number sense is a timed event, so an answer taken this long is not really
  /// an answer. Attempts slower than this record no time at all, rather than
  /// letting a question left open overnight wreck the averages.
  final Duration maxAnswerTime;

  double get stalenessWeight => 1 - weaknessWeight;

  /// The configuration this build runs with. Read once, at startup, so the
  /// app cannot behave as though two different settings were in force.
  static final AppConfig current = AppConfig(
    content: ContentSource.byName(
      const String.fromEnvironment('CONTENT', defaultValue: 'real'),
    ),
    rollingWindow: const int.fromEnvironment(
      'ROLLING_WINDOW',
      defaultValue: 10,
    ),
    staleAfterDays: const int.fromEnvironment(
      'STALE_AFTER_DAYS',
      defaultValue: 30,
    ),
    // As a percent, because there is no double.fromEnvironment.
    weaknessWeight:
        const int.fromEnvironment('WEAKNESS_PERCENT', defaultValue: 60) / 100,
  );
}
