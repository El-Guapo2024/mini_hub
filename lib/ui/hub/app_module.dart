import 'package:flutter/material.dart';

/// One tile on the hub, and the screen behind it.
abstract class AppModule {
  String get title;
  IconData get icon;
  Widget build(BuildContext context);
}

/// A tile that names something not built yet.
///
/// Five of these used to be five files, identical but for a word. What they
/// have in common is that they do nothing, which is not worth a class each.
class ComingSoon implements AppModule {
  const ComingSoon(this.title, this.icon);

  @override
  final String title;

  @override
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: Text('Coming soon')),
  );
}
