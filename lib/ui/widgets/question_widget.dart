import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_keyboard/math_keyboard.dart';

import '../../config.dart';
import '../../content/answer.dart';
import '../../content/question.dart';
import '../../progress/attempt_scope.dart';
import '../../progress/attempt_store.dart';

const _accent = Colors.tealAccent;
const _correct = Color(0xFF4CAF50);
const _wrong = Color(0xFFE57373);

enum _Result { correct, wrong }

/// Whether the cursor should step back over what was just entered.
///
/// True only for an insertion: a deletion or a cursor move must be left alone,
/// or backspacing would walk the cursor the wrong way through the answer.
bool stepsBack({
  required bool rightToLeft,
  required String before,
  required String after,
}) => rightToLeft && after.length > before.length;

class QuestionWidget extends StatefulWidget {
  const QuestionWidget({
    super.key,
    required this.question,
    this.onCorrect,
    this.onSkip,
    this.rightToLeft = false,
  });

  final Question question;

  /// Type the answer from its last digit to its first.
  ///
  /// Several of the manual's tricks hand you digits in that order — the 11
  /// trick gives the ones digit first, then works leftwards — so writing left
  /// to right means holding the whole answer in your head before entering any
  /// of it.
  final bool rightToLeft;

  /// Called once the student has had a moment to see they were right. Null
  /// where there is nowhere to go next, which is why it is not required.
  final VoidCallback? onCorrect;

  /// Leaves the question unanswered and moves on. Null on the last card, and
  /// wherever there is nowhere to go, which is what hides the control.
  ///
  /// It sits with the question rather than up in the counter row, because
  /// the counter row is dropped when the pane is short -- which is to say
  /// whenever the maths keyboard is up, which is to say while practising.
  final VoidCallback? onSkip;

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

/// A controller that deletes in the direction the answer is being typed.
///
/// The keyboard's delete key removes the character before the cursor. Typing
/// right to left parks the cursor to the left of everything entered so the next
/// digit lands to its left — which leaves nothing before the cursor for delete
/// to take, so it did nothing at all. A typo could only be undone by clearing
/// the whole answer and starting again.
class AnswerController extends MathFieldEditingController {
  /// Whether the answer is being typed from its last digit to its first.
  bool rightToLeft = false;

  @override
  void goBack({bool deleteMode = false}) {
    // Only the delete key is turned around. The left arrow and the step back
    // this widget takes after each keystroke both mean "go left" and still do.
    if (!rightToLeft || !deleteMode) {
      super.goBack(deleteMode: deleteMode);
      return;
    }
    // Step over the digit entered last and take it, which puts the cursor back
    // where it was, ready for the next one.
    goNext();
    super.goBack(deleteMode: true);
  }
}

class _QuestionWidgetState extends State<QuestionWidget> {
  final _controller = AnswerController();
  _Result? _result;

  /// Held so it can be cancelled: a card answered right and then swiped away
  /// would otherwise still advance the deck 700ms later, from wherever the
  /// student had got to by then.
  Timer? _advancing;

  /// Starts at the first keystroke, not at build: a question sitting on screen
  /// while the student reads the lesson above it isn't time spent solving.
  DateTime? _startedAt;

  /// What [_check] last graded. A submit that arrives again with the input
  /// unchanged is the same answer arriving twice — a double tap, or a keyboard
  /// sending the event twice — not a second attempt. Each one built its own
  /// [Attempt] with its own id, so the store could not tell them apart and one
  /// answer was recorded, and counted, twice.
  String? _graded;

  /// Set when a write fails. The student is told, because the alternative is a
  /// screen full of green checks that a restart quietly takes back.
  bool _recordingFailed = false;

  @override
  void initState() {
    super.initState();
    _controller.rightToLeft = widget.rightToLeft;
  }

  @override
  void didUpdateWidget(QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The toggle sits above this widget, so the direction can change under a
    // card that is already half answered.
    _controller.rightToLeft = widget.rightToLeft;
  }

  @override
  void dispose() {
    _advancing?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _check(String tex) {
    if (_result != null && tex == _graded) return;

    final correct = widget.question.answer.accepts(tex);
    _graded = tex;
    setState(() => _result = correct ? _Result.correct : _Result.wrong);
    _record(tex, correct);
    _startedAt = null;
    if (correct) _advance();
  }

  /// Moves on, after long enough to read the green. Advancing the instant the
  /// last digit lands would leave the student unsure what they had just been
  /// told.
  void _advance() {
    final onCorrect = widget.onCorrect;
    if (onCorrect == null) return;
    // Answering twice inside the window — correcting a typo, say — must not
    // queue two hops.
    _advancing?.cancel();
    _advancing = Timer(AppConfig.current.advanceAfter, onCorrect);
  }

  void _record(String tex, bool correct) {
    final store = AttemptScope.maybeOf(context);
    // No scope means nothing to record to — a test, or a question previewed
    // outside the app. Grading still works; it just isn't remembered.
    if (store == null) return;

    final started = _startedAt;
    final elapsed = started == null ? null : DateTime.now().difference(started);

    final attempt = Attempt(
      questionId: widget.question.id,
      topic: widget.question.topic,
      type: widget.question.type,
      correct: correct,
      at: DateTime.now().toUtc(),
      given: tex,
      // A negative duration means the clock moved backwards mid-answer — an
      // NTP correction, say. That is not a fast answer, and averaging it in
      // would make the log say something that never happened.
      elapsed:
          elapsed == null ||
              elapsed.isNegative ||
              elapsed > AppConfig.current.maxAnswerTime
          ? null
          : elapsed,
    );

    // Not awaited: grading is already on screen and the write must not hold it
    // up. A failure is logged rather than thrown — the store has already taken
    // the attempt back out of memory, so what is shown stays true, and losing
    // one row is not worth interrupting practice for.
    unawaited(
      store.record(attempt).catchError((Object error) {
        debugPrint('could not record an attempt: $error');
        // Grading stays as it is — it was right about the answer. What the
        // student is told is that this one will not be remembered.
        if (mounted) setState(() => _recordingFailed = true);
      }),
    );
  }

  /// The value as it was at the last change, to tell an insertion from a
  /// deletion or a cursor move.
  String _previous = '';

  void _onChanged(String tex) {
    _startedAt ??= DateTime.now();
    if (_result != null) {
      // Editing after a correct answer takes back the hop it queued. The green
      // is already gone; being moved to the next question anyway, mid-word,
      // reads as the deck losing track of where the student is.
      _advancing?.cancel();
      setState(() => _result = null);
    }

    // Step back over what was just typed, so the next character lands to its
    // left. Moving the cursor does not change the value, so this cannot
    // trigger itself.
    if (stepsBack(
      rightToLeft: widget.rightToLeft,
      before: _previous,
      after: tex,
    )) {
      _controller.goBack();
    }
    _previous = tex;
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

  /// The grading rule, while the question is still open.
  ///
  /// A miss used to print `Answer: 54` under the field. It was the fastest
  /// way out of a question, which is the problem: the answer arrived before
  /// the student had a second go at working it out, and a bank this size is
  /// no use if the way through it is reading the answers. A wrong attempt
  /// now leaves the question exactly as it was, minus the attempt. Skip is
  /// the way past one that will not come — see the practice screen.
  Widget? get _footer {
    if (_recordingFailed) {
      return const Text(
        'Progress is not being saved on this device',
        style: TextStyle(color: _wrong, fontSize: 12),
      );
    }
    // Shown again after a miss, unlike the answer: that an estimate is an
    // estimate, or that a fraction wants lowest terms, is the rule the
    // attempt is graded by rather than what it grades to. Hidden once it is
    // right, where there is nothing left to aim at.
    final hint = widget.question.answer.inputHint;
    if (hint == null || _result == _Result.correct) return null;
    return Text(
      hint,
      // white60 for the same reason as the placeholder: this is the only place
      // an estimate says it is one, or a fraction says it wants lowest terms.
      style: const TextStyle(color: Colors.white60, fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) => switch (widget.question.answer) {
    // Every answer in the bank is given by typing a value; they differ only in
    // how that value is graded, which the answer itself decides. Switching on
    // the sealed Answer means a new shape fails to compile here until it has
    // been given an input, rather than reaching a student as a wrong one.
    NumericAnswer() ||
    ApproxAnswer() ||
    ComplexAnswer() ||
    FractionAnswer() ||
    BaseAnswer() ||
    ChoiceAnswer() => _typedAnswer(context),
  };

  Widget _typedAnswer(BuildContext context) {
    // The card is the screen: one question, centred, with room to think. It
    // used to be a bordered block titled "Question", which made sense when it
    // sat inside a lesson among prose and needed to announce itself.
    // Centred when there is room and scrollable when there is not. The card's
    // height is the prompt plus a fixed 40 and 48 of spacing, and the pane it
    // sits in is what is left after the tab bar and the math keyboard — 160pt
    // on an 800x600 window, which the card overran by half a pixel. Half a
    // pixel still paints the striped overflow banner across the question, and
    // anything that makes the card taller, a larger text scale most of all,
    // overruns it by more.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: _card(context),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        // The scroll view above leaves the height unbounded, so the column
        // sizes to its children — and the minimum the box below it imposes is
        // the pane's own height, which is what keeps the card centred whenever
        // there is room to centre it.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rendered math does not wrap, and real prompts run wider than a
          // phone — `(*) 32 \times 64 \times 16 \div 48 =` overflows a
          // 393pt screen. Scrolling the prompt keeps it readable instead of
          // clipping the right-hand side, which would hide the operator.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              widget.question.prompt,
              textStyle: const TextStyle(fontSize: 34, color: Colors.white),
            ),
          ),
          const SizedBox(height: 40),
          Theme(
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
              onChanged: _onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Answer',
                // white38 on this background is 3.44:1, under the 4.5:1 a
                // reader needs at this size. The placeholder is the only
                // thing in the field before an answer is typed, so it is the
                // one piece of text that cannot afford to be faint.
                hintStyle: const TextStyle(color: Colors.white60),
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
                    // The border is what says where to type, and white24 is
                    // 1.94:1 against this background — under the 3:1 a control
                    // needs to be made out at all. white38 is 3.39:1.
                    color: _result == null ? Colors.white38 : _borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _borderColor, width: 1.5),
                ),
              ),
            ),
          ),
          // Reserved whether or not there is a footer, so the field does not
          // jump up the screen the moment an answer is graded. Skip shares
          // the row for the same reason: space already held open cannot
          // shift anything by being filled.
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(child: _footer ?? const SizedBox.shrink()),
                  if (widget.onSkip != null)
                    TextButton(
                      onPressed: widget.onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white60,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Skip', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
