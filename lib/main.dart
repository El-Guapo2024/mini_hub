import 'package:flutter/material.dart';

import 'progress/attempt_scope.dart';
import 'progress/attempt_store.dart';
import 'ui/hub/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Storage must never be why the app won't start: an unreachable log costs the
  // recording of progress, not the ability to practise.
  AttemptStore? store;
  try {
    store = await AttemptStore.open();
  } on Object catch (error, stack) {
    debugPrint('could not open the attempt log, progress will not be saved');
    debugPrintStack(label: '$error', stackTrace: stack);
  }
  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.store});

  /// Absent in tests, which render the app without platform channels and so
  /// cannot reach the documents directory.
  final AttemptStore? store;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: "Mini Hub",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HubHome(),
    );
    final store = this.store;
    return store == null ? app : AttemptScope(store: store, child: app);
  }
}
