import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:math_keyboard/math_keyboard.dart';

import '../data/lesson_loader.dart';
import '../data/question_pool_loader.dart';
import '../markdown/question_markdown.dart';
import '../models/ids.dart';
import '../models/question.dart';
import '../models/topic.dart';

class TopicScreen extends StatefulWidget {
  final Topic topic;

  const TopicScreen({super.key, required this.topic});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final LessonLoader lessonLoader = LessonLoader();
  final QuestionPoolLoader questionLoader = QuestionPoolLoader();
  String lessonMarkdown = '';
  Map<QuestionId, Question> questionPool = {};

  @override
  void initState() {
    super.initState();
    loadLesson();
    loadQuestions();
  }

  Future<void> loadLesson() async {
    final raw = await lessonLoader.load(widget.topic.lessonPath);
    setState(() {
      lessonMarkdown = raw;
    });
  }

  Future<void> loadQuestions() async {
    // A topic declares its questions in topic.yml; lesson-only topics list none.
    if (widget.topic.questionIds.isEmpty) return;
    final questions = await questionLoader.load(widget.topic.questionsPath);
    if (!mounted) return;
    setState(() {
      questionPool = {for (final q in questions) q.id: q};
    });
  }

  @override
  Widget build(BuildContext context) {
    return MathKeyboardViewInsets(
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
          title: Text(widget.topic.title),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: MarkdownBody(
            data: lessonMarkdown,
            extensionSet: md.ExtensionSet(
              [LatexBlockSyntax(), QuestionBlockSyntax()],
              [LatexInlineSyntax()],
            ),
            builders: {
              'latex': LatexElementBuilder(
                textStyle: const TextStyle(color: Colors.white),
              ),
              'question': QuestionElementBuilder(pool: questionPool),
            },
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
              ),
              h1: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
              code: TextStyle(
                color: Colors.tealAccent.shade100,
                backgroundColor: Colors.grey.shade800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
