import 'package:flutter/material.dart';

import 'config.dart';
import 'progress/attempt_scope.dart';
import 'progress/attempt_store.dart';
import 'ui/hub/home.dart';
import 'ui/theme.dart';
import 'ui/widgets/screen_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Before anything reads the configuration. A build flag naming a content
  // source that does not exist used to throw out of the first repository
  // built, which happens in a field initializer — past every try in the app —
  // so the student got a blank screen, and the log blamed storage, because
  // opening the log was simply the first thing to read the configuration.
  final misconfigured = AppConfig.configurationError;
  if (misconfigured != null) {
    runApp(MisconfiguredApp(reason: misconfigured));
    return;
  }

  // Storage must never be why the app won't start: an unreachable log costs the
  // recording of progress, not the ability to practise.
  AttemptStore? store;
  var storageFailed = false;
  try {
    store = await AttemptStore.open();
  } on Object catch (error, stack) {
    storageFailed = true;
    debugPrint('could not open the attempt log, progress will not be saved');
    debugPrintStack(label: '$error', stackTrace: stack);
  }
  runApp(MyApp(store: store, storageFailed: storageFailed));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.store, this.storageFailed = false});

  /// Absent in tests, which render the app without platform channels and so
  /// cannot reach the documents directory.
  final AttemptStore? store;

  /// Whether the log could not be opened at all.
  ///
  /// Told apart from simply having no store, which is also what a test or a
  /// preview has. Only a real failure is worth saying out loud — and it is
  /// worth saying, because otherwise a student practises a whole session,
  /// sees every answer marked right, and finds nothing counted afterwards.
  final bool storageFailed;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: "Mini Hub",
      theme: appTheme,
      // The corner ribbon serves nobody: it tells a developer what they
      // already know, and it sits across App Store screenshots, which the
      // simulator can only ever produce in debug — release and profile are
      // both refused for simulators, so there is no build mode that hides
      // it for us.
      debugShowCheckedModeBanner: false,
      home: const HubHome(),
      builder: storageFailed
          ? (context, child) => _NotSaving(child: child)
          : null,
    );
    final store = this.store;
    return store == null ? app : AttemptScope(store: store, child: app);
  }
}

/// The app, with a line above it saying nothing is being recorded.
///
/// Placed over every screen rather than on the question, because it is true of
/// the whole session and was true before the first answer was given.
class _NotSaving extends StatelessWidget {
  const _NotSaving({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(
        color: Colors.orange.shade900,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Progress is not being saved on this device',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange.shade50, fontSize: 13),
            ),
          ),
        ),
      ),
      Expanded(child: child ?? const SizedBox.shrink()),
    ],
  );
}

/// What a build with an unusable configuration shows instead of starting.
///
/// A whole screen, because there is nothing else the app could usefully do,
/// and the flag that caused it is named so it can be corrected.
class MisconfiguredApp extends StatelessWidget {
  const MisconfiguredApp({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: "Mini Hub",
    theme: appTheme,
    home: Scaffold(body: ScreenMessage(reason)),
  );
}
