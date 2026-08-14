import 'ids.dart';

/// A lesson, and where on disk it lives.
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.logo,
    required this.questionIds,
    required this.folderPath,
  });

  final TopicId id;
  final String title;
  final String logo;

  /// Ids of this topic's questions. Empty means a lesson with no practice,
  /// which is a real state: seven topics cover material the manual never set
  /// problems for.
  final List<QuestionId> questionIds;

  /// The directory the topic was loaded from, with no trailing slash.
  final String folderPath;

  String get lessonPath => '$folderPath/lesson.md';
  String get questionsPath => '$folderPath/questions.json';

  factory Topic.fromJson(Map<String, dynamic> json, String folderPath) => Topic(
    id: TopicId(json['id'] as String),
    title: json['title'] as String,
    logo: json['logo'] as String,
    questionIds: [
      for (final id in (json['questionIds'] as List<dynamic>?) ?? const [])
        QuestionId(id as String),
    ],
    folderPath: folderPath,
  );
}
