import 'package:flutter/material.dart';

import '../models/question.dart';
import 'question_widget.dart';

class QuestionView extends StatelessWidget {
  const QuestionView({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return switch (question.type) {
      // Every type in the bank is answered by typing a value; they differ only
      // in how that value is graded, which the answer itself decides. The
      // default arm is kept for input kinds that genuinely differ later.
      'numeric' ||
      'estimate' ||
      'complex' ||
      'base' ||
      'numerical' => QuestionWidget(question: question),
      _ => Text(
        'unsupported question type: ${question.type}',
        style: const TextStyle(color: Colors.redAccent),
      ),
    };
  }
}
