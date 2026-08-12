import 'package:json_annotation/json_annotation.dart';

part 'topic.g.dart';

@JsonSerializable()
class Topic {
  final String id;
  final String title;
  final String logo;
  @JsonKey(name: 'questionIds')
  final List<String> questionIds;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late String lessonPath;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late String questionsPath;

  Topic({
    required this.id,
    required this.title,
    required this.logo,
    required this.questionIds,
    this.lessonPath = '',
    this.questionsPath = '',
  });

  factory Topic.fromJson(Map<String, dynamic> json, String folderPath) {
    final topic = _$TopicFromJson(json);
    topic.lessonPath = '$folderPath/lesson.md';
    topic.questionsPath = '$folderPath/questions.json';
    return topic;
  }

  Map<String, dynamic> toJson() => _$TopicToJson(this);
}
