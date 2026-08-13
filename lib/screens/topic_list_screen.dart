import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/topic.dart';
import '../data/topic_loader.dart';
import 'topic_screen.dart';

class TopicListScreen extends StatefulWidget {
  final Course course;

  const TopicListScreen({super.key, required this.course});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  final TopicLoader topicLoader = TopicLoader();
  List<Topic> topics = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final result = <Topic>[];
    for (final topicId in widget.course.topicIds) {
      result.add(
        await topicLoader.load('${widget.course.folderPath}/$topicId'),
      );
    }
    setState(() {
      topics = result;
    });
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
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
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopicScreen(topic: topic),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
