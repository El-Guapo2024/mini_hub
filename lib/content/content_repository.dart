import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../config.dart';
import 'course.dart';
import 'ids.dart';
import 'question.dart';
import 'topic.dart';

/// Reads the shipped content: courses, topics, lessons, questions.
///
/// One class rather than five loaders behind a `Loader<T>` interface. That
/// interface promised a shared shape it did not have — every implementation's
/// `load(String path)` meant something different, one a directory, one a file,
/// one the index — so nothing could be written against it and the type gave a
/// caller no help in passing the right kind of path. Here each method names
/// what it takes.
///
/// Everything is read-only. Progress is written elsewhere, to SQLite.
class ContentRepository {
  ContentRepository({ContentSource? source})
    : source = source ?? AppConfig.current.content;

  /// Which bank to read. Defaults to the build's configured source; tests and
  /// previews can point one at the other without a rebuild.
  final ContentSource source;

  /// Every course this build offers, in the order the index names them.
  Future<List<Course>> courses() async {
    final raw = await rootBundle.loadString(source.indexPath);
    final index = jsonDecode(raw) as List<dynamic>;
    return [
      for (final entry in index.cast<Map<String, dynamic>>())
        await _course(entry['path'] as String),
    ];
  }

  Future<Course> _course(String folderPath) async {
    final path = _trimSlash(folderPath);
    final yaml = loadYaml(await rootBundle.loadString('$path/course.yml'));
    return Course.fromJson(Map<String, dynamic>.from(yaml), path);
  }

  /// One topic of [course], by the slug the course lists.
  Future<Topic> topic(Course course, TopicId id) async {
    final path = course.pathFor(id);
    final yaml = loadYaml(await rootBundle.loadString('$path/topic.yml'));
    return Topic.fromJson(Map<String, dynamic>.from(yaml), path);
  }

  /// The lesson markdown for [topic].
  Future<String> lesson(Topic topic) => rootBundle.loadString(topic.lessonPath);

  /// [topic]'s questions, keyed by id for the markdown tags to resolve
  /// against. Empty for a lesson-only topic, which is a real state.
  Future<Map<QuestionId, Question>> questions(Topic topic) async {
    if (topic.questionIds.isEmpty) return const {};
    final raw = await rootBundle.loadString(topic.questionsPath);
    final questions = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Question.fromJson);
    return {for (final question in questions) question.id: question};
  }

  static String _trimSlash(String path) =>
      path.endsWith('/') ? path.substring(0, path.length - 1) : path;
}
