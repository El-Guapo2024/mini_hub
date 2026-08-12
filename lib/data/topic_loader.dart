import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/topic.dart';
import 'loader.dart';

class TopicLoader implements Loader<Topic> {
  @override
  Future<Topic> load(String folderPath) async {
    final cleanPath = folderPath.replaceAll(RegExp(r'/$'), '');
    final raw = await rootBundle.loadString('$cleanPath/topic.yml');
    final yamlMap = loadYaml(raw);
    final jsonMap = Map<String, dynamic>.from(yamlMap);
    return Topic.fromJson(jsonMap, cleanPath);
  }
}
