import 'package:flutter/material.dart';
import 'package:math_keyboard/math_keyboard.dart';

import '../../content/content_repository.dart';
import '../../content/question.dart';
import '../../content/topic.dart';
import '../../progress/attempt_scope.dart';
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
              children: [
                _Lesson(markdown: text),
                _Practice(questions: pool),
              ],
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

const _green = Color(0xFF4CAF50);

/// One question at a time, like a deck of cards.
///
/// A [PageView] rather than a list: only the current card and its neighbour
/// exist, so a topic with 59 questions never builds 59 math fields, and the
/// student sees one problem instead of a wall of them.
class _Practice extends StatefulWidget {
  const _Practice({required this.questions});

  final List<Question> questions;

  @override
  State<_Practice> createState() => _PracticeState();
}

class _PracticeState extends State<_Practice> {
  final _pages = PageController();
  int _current = 0;

  /// How many of the topic's questions have ever been answered correctly.
  ///
  /// Read from the log rather than counted as the session goes, so it is the
  /// same number after a restart as before one.
  int get _done {
    final store = AttemptScope.maybeOf(context);
    if (store == null) return 0;
    return widget.questions.where((q) => store.isDone(q.id)).length;
  }

  bool _isDone(Question question) =>
      AttemptScope.maybeOf(context)?.isDone(question.id) ?? false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    setState(() {});
    if (_current >= widget.questions.length - 1) return;
    _pages.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions;
    if (questions.isEmpty) {
      return const _Message('no questions for this topic yet');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isDone(questions[_current]))
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle, size: 16, color: _green),
                ),
              Text(
                '${_current + 1} of ${questions.length}   ·   '
                '$_done done',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: questions.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder: (context, index) {
              final question = questions[index];
              // Keyed by id so a card keeps its own answer and result while
              // the deck is swiped back and forth. Given the whole page
              // rather than a scroll view: the question centres itself in
              // what it is given, and there is only ever one.
              return QuestionView(
                key: ValueKey(question.id.value),
                question: question,
                onCorrect: _next,
              );
            },
          ),
        ),
      ],
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
