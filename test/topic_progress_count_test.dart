import 'package:flutter_test/flutter_test.dart';
import 'package:mini_hub/content/ids.dart';
import 'package:mini_hub/ui/screens/topic_list_screen.dart';

/// The count a topic row shows is over the questions that topic declares.
///
/// Its total comes from topic.yml and the log holds whatever was answered, so
/// taking the log's own count for the topic let a row read "done" while a
/// question the topic declares had never been answered.
void main() {
  const declared = [QuestionId('sq.q1'), QuestionId('sq.q2')];

  test('counts only what the topic declares', () {
    // Answered, but not one of this topic's questions.
    expect(doneCount(declared, {const QuestionId('sq.elsewhere')}), 0);

    expect(
      doneCount(declared, {
        const QuestionId('sq.q1'),
        const QuestionId('sq.elsewhere'),
      }),
      1,
      reason: 'the stray answer does not count towards the topic',
    );
  });

  test('a topic is finished only when its own questions are', () {
    expect(doneCount(declared, {...declared}), declared.length);
  });

  test('nothing answered counts nothing', () {
    expect(doneCount(declared, const {}), 0);
    expect(doneCount(const [], const {}), 0);
  });
}
