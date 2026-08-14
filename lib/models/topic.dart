/// A lesson, and where on disk it lives.
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.logo,
    required this.questionIds,
    required this.folderPath,
  });

  final String id;
  final String title;
  final String logo;

  /// Ids of this topic's questions. Empty means a lesson with no practice,
  /// which is a real state: seven topics cover material the manual never set
  /// problems for.
  final List<String> questionIds;

  /// The directory the topic was loaded from, with no trailing slash.
  final String folderPath;

  String get lessonPath => '$folderPath/lesson.md';
  String get questionsPath => '$folderPath/questions.json';

  factory Topic.fromJson(Map<String, dynamic> json, String folderPath) => Topic(
    id: json['id'] as String,
    title: json['title'] as String,
    logo: json['logo'] as String,
    questionIds:
        (json['questionIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    folderPath: folderPath,
  );
}
