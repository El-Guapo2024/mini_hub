import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/content_repository.dart';

/// The course index and `pubspec.yaml`'s asset list are maintained separately,
/// so they can disagree. When they do, a student should still get the courses
/// that are fine rather than an error page instead of all of them.
void main() {
  const index = '''
    [{"path": "assets/content/good"}, {"path": "assets/content/broken"}]
  ''';

  const goodCourse = '''
id: number_sense
title: Number Sense
icon: functions
topics:
  - adding
''';

  ContentRepository repositoryWhere(Map<String, String> assets) =>
      ContentRepository(
        load: (path) async {
          final asset = assets[path];
          if (asset == null) {
            throw FlutterError('Unable to load asset: "$path".');
          }
          return asset;
        },
      );

  test('a course whose folder is missing is left out, not fatal', () async {
    final content = repositoryWhere({
      'assets/content/courses.json': index,
      'assets/content/good/course.yml': goodCourse,
      // Nothing at assets/content/broken/course.yml: the folder was never
      // added to the asset list.
    });

    final courses = await content.courses();

    expect(courses, hasLength(1));
    expect(courses.single.title, 'Number Sense');
  });

  test('a course with malformed yaml is left out too', () async {
    final content = repositoryWhere({
      'assets/content/courses.json': index,
      'assets/content/good/course.yml': goodCourse,
      'assets/content/broken/course.yml': 'title: [unclosed',
    });

    expect(await content.courses(), hasLength(1));
  });

  test('an unreadable index is still an error', () async {
    // There is no partial answer here — without the index there is nothing to
    // show, and an empty grid would read as "there are no courses".
    expect(repositoryWhere(const {}).courses(), throwsA(isA<FlutterError>()));
  });

  test('every course loads when nothing is broken', () async {
    final content = repositoryWhere({
      'assets/content/courses.json': index,
      'assets/content/good/course.yml': goodCourse,
      'assets/content/broken/course.yml': goodCourse,
    });

    expect(await content.courses(), hasLength(2));
  });
}
