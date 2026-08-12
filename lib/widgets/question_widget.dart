import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_keyboard/math_keyboard.dart';

import '../models/question.dart';

const _surface = Color(0xFF121212);
const _accent = Colors.tealAccent;
const _correct = Color(0xFF4CAF50);
const _wrong = Color(0xFFE57373);

enum _Result { correct, wrong }

class QuestionWidget extends StatefulWidget {
  const QuestionWidget({super.key, required this.question});

  final Question question;

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  final _controller = MathFieldEditingController();
  _Result? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check(String tex) {
    final correct = widget.question.answer.accepts(tex);
    setState(() => _result = correct ? _Result.correct : _Result.wrong);
  }

  void _clearResult(String _) {
    if (_result != null) setState(() => _result = null);
  }

  Color get _borderColor => switch (_result) {
    _Result.correct => _correct,
    _Result.wrong => _wrong,
    null => _accent,
  };

  Widget? get _resultIcon => switch (_result) {
    _Result.correct => const Icon(Icons.check, color: _correct, size: 20),
    _Result.wrong => const Icon(Icons.close, color: _wrong, size: 20),
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Math.tex(
                widget.question.prompt,
                textStyle: const TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      onSurface: Colors.white,
                      secondary: _accent,
                    ),
                  ),
                  child: MathField(
                    controller: _controller,
                    keyboardType: MathKeyboardType.expression,
                    variables: const [],
                    onSubmitted: _check,
                    onChanged: _clearResult,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Answer',
                      hintStyle: const TextStyle(color: Colors.white38),
                      suffixIcon: _resultIcon,
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _result == null
                              ? Colors.white24
                              : _borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _borderColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 14,
          top: 0,
          child: Container(
            color: _surface,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: const Text(
              'Question',
              style: TextStyle(
                color: _accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
