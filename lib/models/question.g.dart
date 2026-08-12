// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
  id: json['id'] as String,
  type: json['type'] as String,
  prompt: json['prompt'] as String,
  answer: json['answer'] as num,
);

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'prompt': instance.prompt,
  'answer': instance.answer,
};
