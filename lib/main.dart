import 'package:flutter/material.dart';

import 'data/attempt_scope.dart';
import 'data/attempt_store.dart';
import 'hub/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Opened once at launch and read whole. Practice must not wait on storage,
  // so a log that fails to open yields an empty store rather than an error
  // screen — see AttemptStore.openAt.
  final store = await AttemptStore.open();
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
