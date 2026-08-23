import 'dart:math';

import 'package:flutter/material.dart';
import 'package:math_keyboard/math_keyboard.dart';

import '../../content/content_repository.dart';
import '../../content/question.dart';
import '../../content/topic.dart';
import '../../progress/attempt_scope.dart';
import '../widgets/lesson_view.dart';
import '../widgets/question_widget.dart';
import '../theme.dart';
import '../widgets/screen_state.dart';

/// Whether the practice deck is shuffled. Always true in the app.
///
/// A test that types a particular answer has to know which question it is
/// answering, and a shuffled deck means it cannot. Turning the shuffle off
/// leaves the deck in printed order — which questions it holds, and the fact
/// that answered ones are left out of it, are unchanged.
@visibleForTesting
bool debugShufflePractice = true;

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
          appBar: AppBar(
            title: Text(widget.topic.title),
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
            (final Object error, _, _) => ScreenMessage.failure(error),
            (_, final String text, final List<Question> pool) => TabBarView(
              children: [
                _Lesson(markdown: text),
                _Practice(questions: pool),
              ],
            ),
            _ => const ScreenLoading(),
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
  late final PageController _pages;
  int _current = 0;

  /// The questions this sitting will ask, in the order it will ask them.
  ///
  /// What is left to do, shuffled. The deck used to be every question in
  /// printed order, opening at the first one every time — so a student who had
  /// done forty had to swipe past all forty to reach where they were, and saw
  /// the same problems in the same order at every sitting.
  late final List<Question> _deck;

  /// Whether the deck has been dealt. Dealt once and then left alone: taking a
  /// question out the moment it is answered would slide the next card under the
  /// student's thumb, and reshuffling on a rebuild would lose their place.
  bool _dealt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dealt) return;
    _dealt = true;

    final store = AttemptScope.maybeOf(context);
    final remaining = store == null
        ? [...widget.questions]
        : widget.questions.where((q) => !store.isDone(q.id)).toList();

    // Everything answered leaves nothing to deal, and an empty deck is a dead
    // end — so a finished topic deals the whole set again rather than refusing
    // to open. Practising it once more is the only reason to be back.
    _deck = remaining.isEmpty ? [...widget.questions] : remaining;
    if (debugShufflePractice) _deck.shuffle(_shuffler);
    _pages = PageController();
  }

  /// Left unseeded, so the order differs from sitting to sitting rather than
  /// being a second fixed order the student learns instead of the first.
  static final _shuffler = Random();

  /// Kept here rather than on the card, so choosing it once holds for the
  /// whole session instead of resetting at every swipe.
  bool _rightToLeft = false;

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

  /// How many times the deck has changed page. Captured when a card is built
  /// and checked when its pause elapses, so a student who swipes away and back
  /// inside the pause is not moved on by the answer they gave before leaving —
  /// they came back to that card deliberately.
  int _pageChanges = 0;

  /// Moves on from [index], a moment after it was answered right.
  ///
  /// The card that asked is named, because a [PageView] keeps its neighbour
  /// alive: answer one and swipe on before the pause is up, and the card left
  /// behind would otherwise advance the deck again from wherever you now are.
  void _advanceFrom(int index, int changesWhenAsked) {
    setState(() {});
    if (changesWhenAsked != _pageChanges) return;
    if (index != _current || _current >= _deck.length - 1) return;
    _pages.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const ScreenMessage('no questions for this topic yet');
    }
    // The deck, not the topic: what is shown, counted and swiped through is
    // what is left to do. So "3 of 12 · 76 done" is third card of twelve still
    // to answer, seventy-six of the topic answered altogether.
    final questions = _deck;

    // The counter is dropped rather than overrun when the pane is too short to
    // hold it. Mid-animation the keyboard leaves this as little as six pixels,
    // and a fixed-height row in a column that short overflowed by 46 — a
    // striped banner across the practice pane for as long as the keyboard took
    // to settle. Nothing legible fits in six pixels anyway.
    return LayoutBuilder(
      builder: (context, constraints) =>
          _pane(questions, showCounter: constraints.maxHeight > _counterNeeds),
    );
  }

  /// Room the counter row wants before it is worth showing at all.
  static const _counterNeeds = 80.0;

  Widget _pane(List<Question> questions, {required bool showCounter}) {
    return Column(
      children: [
        if (showCounter)
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 8, top: 4),
            child: Row(
              children: [
                if (_isDone(questions[_current]))
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    // Labelled, because the tick is the only thing that says
                    // this one has already been answered — read aloud, an
                    // unlabelled icon says nothing at all.
                    child: Semantics(
                      label: 'Answered correctly',
                      child: Icon(Icons.check_circle, size: 16, color: correct),
                    ),
                  ),
                Text(
                  '${_current + 1} of ${questions.length}   ·   $_done done',
                  style: const TextStyle(color: Colors.white54),
                ),
                const Spacer(),
                // Several tricks give you the ones digit first, so typing from
                // the right lets the student write digits as they work them out.
                // Announced as the switch it is: the tooltip alone says what the
                // button is called but not which way it is currently set, and
                // the colour that carries that is no help read aloud.
                // One node carrying the name, the state and the tap together.
                // Without the container it has none of its own and they merge
                // upwards into a node covering the whole pane, fused with the
                // counter beside it; without the merge they split, and the
                // button a reader stops on is the half with no name.
                MergeSemantics(
                  child: Semantics(
                    container: true,
                    toggled: _rightToLeft,
                    label: 'Type right to left',
                    child: IconButton(
                      onPressed: () =>
                          setState(() => _rightToLeft = !_rightToLeft),
                      icon: const Icon(Icons.swap_horiz, size: 20),
                      color: _rightToLeft ? Colors.tealAccent : Colors.white54,
                      tooltip: _rightToLeft
                          ? 'Typing right to left'
                          : 'Typing left to right',
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: questions.length,
            onPageChanged: (index) => setState(() {
              _current = index;
              _pageChanges++;
            }),
            itemBuilder: (context, index) {
              final question = questions[index];
              final changesWhenBuilt = _pageChanges;
              // Keyed by id so a recycled slot never shows the previous
              // card's typed answer or result. Swiping more than one card
              // away does discard that state — the alternative is keeping all
              // 59 math fields alive, which is what the PageView avoids.
              //
              // Given the whole page rather than a scroll view: the question
              // centres itself in what it is given, and there is only one.
              return QuestionWidget(
                key: ValueKey(question.id.value),
                question: question,
                onCorrect: () => _advanceFrom(index, changesWhenBuilt),
                rightToLeft: _rightToLeft,
              );
            },
          ),
        ),
      ],
    );
  }
}
