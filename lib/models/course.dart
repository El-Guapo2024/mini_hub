/// A course, and where on disk it lives.
///
/// Serialization is hand-written: the folder path is not in the file, it is
/// where the file was found, and a generated constructor cannot require what
/// it cannot read.
class Course {
  const Course({
    required this.id,
    required this.title,
    required this.icon,
    required this.topicIds,
    required this.folderPath,
  });

  final String id;
  final String title;
  final String icon;

  /// Slugs of the topics this course offers, in the order they are taught.
  final List<String> topicIds;

  /// The directory the course was loaded from, with no trailing slash. Every
  /// topic path is built from it.
  final String folderPath;

  factory Course.fromJson(Map<String, dynamic> json, String folderPath) =>
      Course(
        id: json['id'] as String,
        title: json['title'] as String,
        icon: json['icon'] as String,
        topicIds: (json['topics'] as List<dynamic>).cast<String>(),
        folderPath: folderPath,
      );

  String pathFor(String topicId) => '$folderPath/$topicId';
}
