import 'package:flutter/material.dart';
import '../hub/app_module.dart';

class NotesApp implements AppModule {
  @override
  String get id => 'notes';

  @override
  String get title => 'Notes';

  @override
  IconData get icon => Icons.note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
