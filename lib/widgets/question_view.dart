import 'package:flutter/material.dart';

import '../models/question.dart';
import 'question_widget.dart';

class QuestionView extends StatelessWidget {
  const QuestionView({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return switch (question.type) {
      'numerical' => QuestionWidget(question: question),
      _ => Text(
        'unsupported question type: ${question.type}',
        style: const TextStyle(color: Colors.redAccent),
      ),
    };
  }
}
