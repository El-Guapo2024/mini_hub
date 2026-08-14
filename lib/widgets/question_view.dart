import 'package:flutter/material.dart';

import '../models/answer.dart';
import '../models/question.dart';
import 'question_widget.dart';

/// Chooses the input for a question from the shape of its answer.
///
/// Switching on the sealed [Answer] rather than a string means a new answer
/// type fails to compile here until it has been given an input, instead of
/// reaching a student as an error message.
class QuestionView extends StatelessWidget {
  const QuestionView({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return switch (question.answer) {
      // Every answer in the bank is given by typing a value; they differ only
      // in how that value is graded, which the answer itself decides.
      NumericAnswer() ||
      ApproxAnswer() ||
      ComplexAnswer() ||
      FractionAnswer() ||
      BaseAnswer() => QuestionWidget(question: question),
    };
  }
}
