import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/course.dart';
import 'loader.dart';

class CourseLoader implements Loader<Course> {
  @override
  Future<Course> load(String folderPath) async {
    final cleanPath = folderPath.replaceAll(RegExp(r'/$'), '');
    final raw = await rootBundle.loadString('$cleanPath/course.yml');
    final yamlMap = loadYaml(raw);
    final jsonMap = Map<String, dynamic>.from(yamlMap);
    return Course.fromJson(jsonMap, cleanPath);
  }
}
