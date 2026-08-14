import 'package:flutter/widgets.dart';

import 'attempt_store.dart';

/// Makes the attempt log reachable from a question without threading it down
/// by hand.
///
/// Questions are built deep inside rendered markdown, several widgets below
/// anything that knows about storage, so passing a store through every
/// constructor would mean touching the whole lesson-rendering path.
///
/// [maybeOf] returns null when no scope is present, which is the normal case in
/// tests and in any preview that renders a question outside the app. A question
/// with nowhere to record still grades correctly; it just forgets.
class AttemptScope extends InheritedWidget {
  const AttemptScope({super.key, required this.store, required super.child});

  final AttemptStore store;

  static AttemptStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AttemptScope>()?.store;

  @override
  bool updateShouldNotify(AttemptScope oldWidget) => store != oldWidget.store;
}
