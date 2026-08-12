import 'package:flutter/material.dart';
import '../hub/app_module.dart';

class RoboticsApp implements AppModule {
  @override
  String get id => 'robotics';

  @override
  String get title => 'Robotics';

  @override
  IconData get icon => Icons.smart_toy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Robotics')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}
