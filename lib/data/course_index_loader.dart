import 'dart:convert';
import 'package:flutter/services.dart';
import 'loader.dart';

class CourseIndexLoader implements Loader<List<String>> {
  @override
  Future<List<String>> load(String path) async {
    final raw = await rootBundle.loadString(path);
    final List<dynamic> parsed = jsonDecode(raw);
    return parsed.map<String>((e) => e['path'] as String).toList();
  }
}
