import 'package:flutter/material.dart';

import '../../content/content_repository.dart';
import '../../content/course.dart';
import '../../content/topic.dart';
import '../../progress/attempt_scope.dart';
import '../theme.dart';
import '../widgets/screen_state.dart';
import 'topic_screen.dart';

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key, required this.course});

  final Course course;

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  final ContentRepository content = ContentRepository();
  List<Topic> topics = [];
  Object? failure;

  @override
  void initState() {
    super.initState();
    loadData();
  }

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
      appBar: AppBar(title: Text(widget.course.title)),
      body: failure != null
          ? ScreenMessage.failure(failure!)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, index) => _TopicCard(topic: topics[index]),
            ),
    );
  }
}

/// Reads its own count from the log. It depends on [AttemptScope], so it
/// rebuilds when an attempt is recorded — the list no longer has to refresh
/// itself on the way back from practice.
class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    // questionIds is what the topic file already knows, so the count needs no
    // questions.json read per row.
    final total = topic.questionIds.length;
    final store = AttemptScope.maybeOf(context);
    final done = store?.progressFor(topic.id).count ?? 0;
    final finished = total > 0 && done == total;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade700,
          child: const Icon(Icons.bolt, color: Colors.white),
        ),
        title: Text(
          topic.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: total == 0
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  finished ? 'done · $total questions' : '$done of $total done',
                  style: TextStyle(color: finished ? correct : Colors.white54),
                ),
              ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        // Only from the visible route: a second tap landing before the push
        // completes would stack the same topic twice, and the student would
        // have to press back through both.
        onTap: () {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TopicScreen(topic: topic)),
          );
        },
      ),
    );
  }
}
