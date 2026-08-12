import 'package:json_annotation/json_annotation.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  final String id;
  final String title;
  final String icon;
  @JsonKey(name: 'topics')
  final List<String> topicIds;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late String folderPath;

  Course({
    required this.id,
    required this.title,
    required this.icon,
    required this.topicIds,
    this.folderPath = '',
  });

  factory Course.fromJson(Map<String, dynamic> json, String folderPath) {
    final course = _$CourseFromJson(json);
    course.folderPath = folderPath;
    return course;
  }

  Map<String, dynamic> toJson() => _$CourseToJson(this);
}
