import 'package:flutter/material.dart';

import '../hub/app_module.dart';

class PhysicsToolsApp implements AppModule {
  @override
  String get id => 'physics_tools';

  @override
  String get title => 'Physics Tools';

  @override
  IconData get icon => Icons.science;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Physics Tools')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
