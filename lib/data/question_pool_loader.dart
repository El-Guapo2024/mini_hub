import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';
import 'loader.dart';

class QuestionPoolLoader implements Loader<List<Question>> {
  @override
  Future<List<Question>> load(String path) async {
    final raw = await rootBundle.loadString(path);
    final List<dynamic> parsed = jsonDecode(raw);
    return parsed.map((e) => Question.fromJson(e)).toList();
  }
}
