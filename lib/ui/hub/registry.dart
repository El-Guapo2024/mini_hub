import 'package:flutter/material.dart';

import '../apps/course_app.dart';
import 'app_module.dart';

final List<AppModule> registry = [
  CourseApp(),
  const ComingSoon('Robotics', Icons.smart_toy),
  const ComingSoon('Physics Tools', Icons.science),
  const ComingSoon('Physics LeetCode', Icons.functions),
  const ComingSoon('Notes', Icons.note),
  const ComingSoon('Projects', Icons.folder),
];
