import 'package:flutter/material.dart';
import '../hub/app_module.dart';

class ProjectsApp implements AppModule {
  @override
  String get id => 'projects';

  @override
  String get title => 'Projects';

  @override
  IconData get icon => Icons.folder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
