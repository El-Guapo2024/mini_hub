import 'package:flutter/services.dart';
import 'loader.dart';

class LessonLoader implements Loader<String> {
  @override
  Future<String> load(String lessonPath) async {
    return rootBundle.loadString(lessonPath);
  }
}
