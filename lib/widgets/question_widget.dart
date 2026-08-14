import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_keyboard/math_keyboard.dart';

import '../config.dart';
import '../data/attempt_scope.dart';
import '../data/attempt_store.dart';
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

  /// Starts at the first keystroke, not at build: a question sitting on screen
  /// while the student reads the lesson above it isn't time spent solving.
  DateTime? _startedAt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check(String tex) {
    final correct = widget.question.answer.accepts(tex);
    setState(() => _result = correct ? _Result.correct : _Result.wrong);
    _record(tex, correct);
    _startedAt = null;
  }

  void _record(String tex, bool correct) {
    final store = AttemptScope.maybeOf(context);
    // No scope means nothing to record to — a test, or a question previewed
    // outside the app. Grading still works; it just isn't remembered.
    if (store == null) return;

    final started = _startedAt;
    final elapsed = started == null ? null : DateTime.now().difference(started);

    store.record(
      Attempt(
        questionId: widget.question.id,
        topic: widget.question.topic,
        type: widget.question.type,
        correct: correct,
        at: DateTime.now().toUtc(),
        given: tex,
        elapsedMs: elapsed == null || elapsed > AppConfig.current.maxAnswerTime
            ? null
            : elapsed.inMilliseconds,
      ),
    );
  }

  void _clearResult(String _) {
    _startedAt ??= DateTime.now();
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

  /// The grading rule before an attempt, the correct answer after a wrong one.
  Widget? get _footer {
    final answer = widget.question.answer;
    if (_result == _Result.wrong) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Answer: ',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Math.tex(
            answer.display,
            textStyle: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      );
    }
    final hint = answer.inputHint;
    if (hint == null || _result != null) return null;
    return Text(
      hint,
      style: const TextStyle(color: Colors.white38, fontSize: 12),
    );
  }

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
              // Rendered math does not wrap, and real prompts run wider than a
              // phone — `(*) 32 \times 64 \times 16 \div 48 =` overflows a
              // 393pt screen. Scrolling the prompt keeps it readable instead of
              // clipping the right-hand side, which would hide the operator.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Math.tex(
                  widget.question.prompt,
                  textStyle: const TextStyle(fontSize: 24, color: Colors.white),
                ),
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
                    // Complex answers put `i` on the keyboard; without it the
                    // student has no way to enter one at all.
                    variables: widget.question.answer.inputVariables,
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
              if (_footer != null) ...[const SizedBox(height: 8), _footer!],
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
