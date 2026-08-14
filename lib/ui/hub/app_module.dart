import 'package:flutter/material.dart';

abstract class AppModule {
  String get id;
  String get title;
  IconData get icon;
  Widget build(BuildContext context);
}
