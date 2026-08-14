import 'answer.dart';

/// One question from the bank.
///
/// Serialization is hand-written rather than generated: the answer is a sealed
/// hierarchy chosen by a `type` discriminator, which json_serializable cannot
/// express without a custom converter anyway.
class Question {
  const Question({
    required this.id,
    required this.prompt,
    required this.answer,
    required this.topic,
  });

  /// Stable, provenance-derived: `bh.<section>.q<n>`. Statistics rows key off
  /// this, so it must survive re-extraction of the source PDF.
  final String id;

  /// How the question is answered. Attempts record it, so progress can be read
  /// per shape. It is the answer's own classification, not a second field that
  /// could disagree with it.
  QuestionType get type => answer.kind;

  /// The prompt, as LaTeX.
  final String prompt;

  final Answer answer;

  /// Slug of the lesson this question belongs to. Required, because an attempt
  /// without one cannot be counted towards any lesson's progress.
  final String topic;

  factory Question.fromJson(Map<String, dynamic> json) {
    final answer = Answer.fromJson(json['answer'] as Map<String, dynamic>);
    return Question(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      answer: answer,
      topic: json['topic'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'prompt': prompt,
    'topic': topic,
    'answer': answer.toJson(),
  };
}
