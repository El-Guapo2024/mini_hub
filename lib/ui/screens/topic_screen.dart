import 'package:flutter/material.dart';
import 'package:math_keyboard/math_keyboard.dart';

import '../../content/content_repository.dart';
import '../../content/question.dart';
import '../../content/topic.dart';
import '../widgets/lesson_view.dart';
import '../widgets/question_view.dart';

/// A topic, as two separate things: the lesson to read and the questions to
/// practise.
///
/// They used to be one scrolling page, with questions embedded in the lesson
/// through a markdown syntax of our own. Splitting them removes that syntax
/// entirely — the lesson is plain markdown, and a question goes straight from
/// `questions.json` to a widget with no parser in between.
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.topic});

  final Topic topic;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final ContentRepository content = ContentRepository();

  String? lesson;
  List<Question>? questions;
  Object? failure;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final lessonMarkdown = await content.lesson(widget.topic);
      final pool = await content.questions(widget.topic);
      if (!mounted) return;
      setState(() {
        lesson = lessonMarkdown;
        questions = pool.values.toList();
      });
    } catch (error) {
      // Without this the screen shows an empty lesson, which reads exactly
      // like a topic that has no content rather than one that failed to load.
      if (!mounted) return;
      setState(() => failure = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: MathKeyboardViewInsets(
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.grey.shade900,
            foregroundColor: Colors.white,
            title: Text(widget.topic.title),
            centerTitle: true,
            bottom: const TabBar(
              indicatorColor: Colors.tealAccent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'Lesson'),
                Tab(text: 'Practice'),
              ],
            ),
          ),
          body: switch ((failure, lesson, questions)) {
            (final Object error, _, _) => _Message('could not load: $error'),
            (_, final String text, final List<Question> pool) => TabBarView(
              children: [_Lesson(markdown: text), _Practice(questions: pool)],
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _Lesson extends StatelessWidget {
  const _Lesson({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LessonView(markdown: markdown),
    );
  }
}

class _Practice extends StatelessWidget {
  const _Practice({required this.questions});

  final List<Question> questions;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const _Message('no questions for this topic yet');
    }
    // Built lazily, so a topic with 59 questions only ever holds the fields
    // that are on screen.
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: questions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final question = questions[index];
        return QuestionView(key: ValueKey(question.id.value), question: question);
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }
}
