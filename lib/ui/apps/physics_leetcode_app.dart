import 'package:flutter/material.dart';

import '../hub/app_module.dart';

class PhysicsLeetcodeApp implements AppModule {
  @override
  String get id => 'physics_leetcode';

  @override
  String get title => 'Physics LeetCode';

  @override
  IconData get icon => Icons.functions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Physics LeetCode')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
