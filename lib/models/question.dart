import 'package:json_annotation/json_annotation.dart';

part 'question.g.dart';

@JsonSerializable()
class Question {
  final String id;
  final String type; // only 'numerical' supported for now
  final String prompt; // latex expression, e.g. "7 + 5 = ?"
  final num answer;

  Question({
    required this.id,
    required this.type,
    required this.prompt,
    required this.answer,
  });

  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}
