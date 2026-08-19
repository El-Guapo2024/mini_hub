import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../config.dart';
import 'course.dart';
import 'ids.dart';
import 'question.dart';
import 'topic.dart';

/// Reads one asset as text. [rootBundle.loadString] in a running app.
typedef AssetLoader = Future<String> Function(String path);

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
  ContentRepository({ContentSource? source, AssetLoader? load})
    : source = source ?? AppConfig.current.content,
      _load = load ?? rootBundle.loadString;

  /// Which bank to read. Defaults to the build's configured source; tests and
  /// previews can point one at the other without a rebuild.
  final ContentSource source;

  /// How an asset's text is read. The bundle, except in tests that need to see
  /// what happens when a particular file will not load.
  final AssetLoader _load;

  /// Every course this build offers, in the order the index names them.
  ///
  /// A course that will not load is left out rather than taken as a reason to
  /// show none of them: the index and the asset manifest are maintained
  /// separately, so one course folder missing from `pubspec.yaml` used to mean
  /// a student saw an error instead of the courses that were fine. An
  /// unreadable index is still an error — there is nothing to show without it.
  ///
  /// Nothing here should ever fail in a shipped build. The bank is checked
  /// whole by `question_assets_test.dart` and `assets_registered_test.dart`,
  /// which is where a broken course is meant to be caught; this is what the
  /// student sees if one gets past them.
  Future<List<Course>> courses() async {
    final raw = await _load(source.indexPath);
    final index = jsonDecode(raw) as List<dynamic>;
    final courses = <Course>[];
    for (final entry in index.cast<Map<String, dynamic>>()) {
      final path = entry['path'] as String;
      try {
        courses.add(await _course(path));
      } on Object catch (error) {
        debugPrint('skipping the course at $path: $error');
      }
    }
    return courses;
  }

  Future<Course> _course(String folderPath) async {
    final path = _trimSlash(folderPath);
    final yaml = loadYaml(await _load('$path/course.yml'));
    return Course.fromJson(Map<String, dynamic>.from(yaml), path);
  }

  /// One topic of [course], by the slug the course lists.
  Future<Topic> topic(Course course, TopicId id) async {
    final path = course.pathFor(id);
    final yaml = loadYaml(await _load('$path/topic.yml'));
    return Topic.fromJson(Map<String, dynamic>.from(yaml), path);
  }

  /// The lesson markdown for [topic].
  Future<String> lesson(Topic topic) => _load(topic.lessonPath);

  /// [topic]'s questions, keyed by id for the markdown tags to resolve
  /// against. Empty for a lesson-only topic, which is a real state.
  Future<Map<QuestionId, Question>> questions(Topic topic) async {
    if (topic.questionIds.isEmpty) return const {};
    final raw = await _load(topic.questionsPath);
    final questions = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Question.fromJson);
    return {for (final question in questions) question.id: question};
  }

  static String _trimSlash(String path) =>
      path.endsWith('/') ? path.substring(0, path.length - 1) : path;
}
