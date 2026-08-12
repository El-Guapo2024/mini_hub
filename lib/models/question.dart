import 'answer.dart';

/// One question from the bank.
///
/// Serialization is hand-written rather than generated: the answer is a sealed
/// hierarchy chosen by a `type` discriminator, which json_serializable cannot
/// express without a custom converter anyway.
class Question {
  const Question({
    required this.id,
    required this.type,
    required this.prompt,
    required this.answer,
    this.topic,
    this.derived = false,
    this.corrected = false,
  });

  /// Stable, provenance-derived: `bh.<section>.q<n>`. Statistics rows key off
  /// this, so it must survive re-extraction of the source PDF.
  final String id;

  /// The question's shape, for filtering and per-type statistics.
  final String type;

  /// The prompt, as LaTeX.
  final String prompt;

  final Answer answer;

  /// Slug of the lesson this question belongs to.
  final String? topic;

  /// True when the manual printed no answer and this one was derived.
  final bool derived;

  /// True when the answer intentionally differs from what the manual prints,
  /// because the printed one was verified wrong against the source page.
  final bool corrected;

  factory Question.fromJson(Map<String, dynamic> json) {
    final raw = json['answer'];
    // A bare number is the pre-existing shape; anything richer arrives as a
    // nested object carrying its own type.
    final answer = raw is Map<String, dynamic>
        ? Answer.fromJson(raw)
        : Answer.fromJson({'type': 'numeric', 'answer': raw});
    return Question(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'numerical',
      prompt: json['prompt'] as String,
      answer: answer,
      topic: json['topic'] as String?,
      derived: json['derived'] as bool? ?? false,
      corrected: json['corrected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'prompt': prompt,
    'answer': answer.toJson(),
    if (topic != null) 'topic': topic,
    if (derived) 'derived': true,
    if (corrected) 'corrected': true,
  };
}
