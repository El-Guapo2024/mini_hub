import 'package:flutter/material.dart';

import '../../content/content_repository.dart';
import '../../content/course.dart';
import '../../content/topic.dart';
import '../../progress/attempt_scope.dart';
import '../widgets/screen_state.dart';
import 'topic_screen.dart';

class TopicListScreen extends StatefulWidget {
  final Course course;

  const TopicListScreen({super.key, required this.course});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  final ContentRepository content = ContentRepository();
  List<Topic> topics = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Object? failure;

  Future<void> loadData() async {
    try {
      // Concurrently: each topic is its own file, and one waiting on another
      // only adds up.
      final result = await Future.wait([
        for (final topicId in widget.course.topicIds)
          content.topic(widget.course, topicId),
      ]);
      if (!mounted) return;
      setState(() => topics = result);
    } catch (error) {
      // Without this a broken topic file leaves an empty list, which reads as
      // a course with no lessons rather than one that failed to load.
      if (!mounted) return;
      setState(() => failure = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        title: Text(widget.course.title),
      ),
      body: failure != null
          ? ScreenMessage.failure(failure!)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                // questionIds is what the topic file already knows, so the count
                // needs no questions.json read per row.
                final total = topic.questionIds.length;
                final done =
                    AttemptScope.maybeOf(
                      context,
                    )?.progressFor(topic.id).count ??
                    0;
                return Card(
                  color: Colors.grey.shade900,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade700,
                      child: const Icon(Icons.bolt, color: Colors.white),
                    ),
                    title: Text(
                      topic.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: total == 0
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              done == total
                                  ? 'done · $total questions'
                                  : '$done of $total done',
                              style: TextStyle(
                                color: done == total
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white54,
                              ),
                            ),
                          ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TopicScreen(topic: topic),
                        ),
                      );
                      // Coming back from practice, the counts have moved.
                      if (mounted) setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}
