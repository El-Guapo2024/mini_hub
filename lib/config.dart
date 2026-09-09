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

/// The Chinese reader's settings. Its assets are named here and nowhere
/// else, per the rule above; the voice values are the ones someone will
/// actually want to tune.
class ChineseConfig {
  /// CC-CEDICT, as shipped upstream (via Wen Reader, MIT).
  static const String cedictAsset = 'assets/chinese/cedict_ts.u8';

  /// The bundled epub.js page the reader WebView loads.
  static const String readerPage = 'assets/chinese/epubjs/reader.html';

  /// The companion's model — the project doc's cost/nuance decision.
  /// The Mac-side Agent SDK companion (tutor_server/). With no API key in
  /// the Keychain, questions go here instead; 127.0.0.1 reaches the Mac
  /// from the simulator.
  static const String tutorServer = 'http://127.0.0.1:8790';

  static const String ttsLanguage = 'zh-CN';

  /// Slower than the OS default (0.5): a learner's reading speed.
  static const double ttsRate = 0.45;
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

  /// The name this build was given for its content source, whether or not it
  /// names one.
  static const String requestedContent = String.fromEnvironment(
    'CONTENT',
    defaultValue: 'real',
  );

  /// Why this build cannot be configured, or null if it can.
  ///
  /// Checked rather than thrown, because [current] is a lazy static and the
  /// first thing to touch it is a repository built in a field initializer —
  /// before any `initState`, and so outside the `try` that would have shown
  /// the failure. Thrown there it reached nothing but Flutter's own handler,
  /// and the student got a blank screen.
  static String? get configurationError {
    const names = ContentSource.values;
    if (names.any((source) => source.name == requestedContent)) return null;
    return 'CONTENT was built as "$requestedContent", which is not one of '
        '${names.map((source) => source.name).join(', ')}.';
  }

  /// The configuration this build runs with. Read once, at startup, so the
  /// app cannot behave as though two different settings were in force.
  ///
  /// Falls back to the real bank where the build named a source that does not
  /// exist; [configurationError] is what says so, and main refuses to start on
  /// it. The fallback keeps a bad flag from throwing out of a field
  /// initializer somewhere far from the cause.
  static final AppConfig current = AppConfig(
    content: configurationError == null
        ? ContentSource.byName(requestedContent)
        : ContentSource.real,
  );
}
