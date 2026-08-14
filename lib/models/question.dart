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
  });

  /// Stable, provenance-derived: `bh.<section>.q<n>`. Statistics rows key off
  /// this, so it must survive re-extraction of the source PDF.
  final String id;

  /// How the question is answered — `numeric`, `estimate`, `complex`, `base` —
  /// classified when the bank is generated rather than inspected at runtime.
  /// Attempts record it, so accuracy can be read per type across every topic.
  final String type;

  /// The prompt, as LaTeX.
  final String prompt;

  final Answer answer;

  /// Slug of the lesson this question belongs to.
  final String? topic;

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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'prompt': prompt,
    'answer': answer.toJson(),
    if (topic != null) 'topic': topic,
  };
}
