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
/// An [InheritedNotifier] rather than a plain [InheritedWidget]: one store
/// instance is threaded through the whole app and never replaced, so comparing
/// the two would have meant this never notified anyone. Rebuilds are driven by
/// the store recording an attempt instead.
class AttemptScope extends InheritedNotifier<AttemptStore> {
  const AttemptScope({
    super.key,
    required AttemptStore store,
    required super.child,
  }) : super(notifier: store);

  static AttemptStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AttemptScope>()?.notifier;
}
