import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/ui/widgets/question_widget.dart';

/// Deleting while typing right to left, against the real keyboard controller.
///
/// Reported from the simulator: with right-to-left on, delete does nothing at
/// all. The keyboard's delete key calls `goBack(deleteMode: true)`, which takes
/// the character before the cursor — and right-to-left parks the cursor to the
/// left of everything entered, so there is never anything before it. The key
/// hit the start of the node and returned. A typo could only be undone by
/// clearing the whole answer.
void main() {
  /// What the keyboard does for one digit while typing right to left: enter it,
  /// then step back over it so the next one lands to its left. This is the
  /// sequence `QuestionWidget` drives through `onChanged`.
  void type(AnswerController controller, String digit) {
    controller.addLeaf(digit);
    controller.goBack();
  }

  String value(AnswerController controller) =>
      controller.currentEditingValue(placeholderWhenEmpty: false);

  test('delete takes the digit entered last', () {
    final controller = AnswerController()..rightToLeft = true;
    addTearDown(controller.dispose);

    // 2850 typed from its last digit, the order the manual's tricks give them.
    for (final digit in ['0', '5', '8', '2']) {
      type(controller, digit);
    }
    expect(value(controller), '2850');

    // The delete key. Before the fix this did nothing whatsoever.
    controller.goBack(deleteMode: true);
    expect(value(controller), '850', reason: 'the 2 entered last is gone');

    controller.goBack(deleteMode: true);
    expect(value(controller), '50');

    // And typing carries on from where it left off, still right to left.
    type(controller, '9');
    expect(value(controller), '950');
  });

  test('left to right still deletes the character before the cursor', () {
    final controller = AnswerController();
    addTearDown(controller.dispose);

    for (final digit in ['2', '8', '5', '0']) {
      controller.addLeaf(digit);
    }
    expect(value(controller), '2850');

    controller.goBack(deleteMode: true);
    expect(value(controller), '285', reason: 'the last one typed is still 0');
  });

  test('the arrow keys are not turned around by the mode', () {
    final controller = AnswerController()..rightToLeft = true;
    addTearDown(controller.dispose);

    for (final digit in ['0', '5']) {
      type(controller, digit);
    }
    expect(value(controller), '50');

    // goBack without deleteMode is the left arrow, and the step this widget
    // takes after every keystroke. Neither may delete anything.
    controller.goBack();
    controller.goNext();
    expect(value(controller), '50');
  });
}
