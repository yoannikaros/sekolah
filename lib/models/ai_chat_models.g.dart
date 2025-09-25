// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIChatConfig _$AIChatConfigFromJson(Map<String, dynamic> json) => AIChatConfig(
  id: json['id'] as String,
  apiKey: json['apiKey'] as String,
  model: json['model'] as String? ?? 'gpt-3.5-turbo',
  temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
  maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 1000,
  systemPrompt: json['systemPrompt'] as String,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  createdBy: json['createdBy'] as String,
);

Map<String, dynamic> _$AIChatConfigToJson(AIChatConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'apiKey': instance.apiKey,
      'model': instance.model,
      'temperature': instance.temperature,
      'maxTokens': instance.maxTokens,
      'systemPrompt': instance.systemPrompt,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'createdBy': instance.createdBy,
    };

AIChatMessage _$AIChatMessageFromJson(Map<String, dynamic> json) =>
    AIChatMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      message: json['message'] as String,
      response: json['response'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type:
          $enumDecodeNullable(_$AIChatMessageTypeEnumMap, json['type']) ??
          AIChatMessageType.general,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AIChatMessageToJson(AIChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'message': instance.message,
      'response': instance.response,
      'createdAt': instance.createdAt.toIso8601String(),
      'type': _$AIChatMessageTypeEnumMap[instance.type]!,
      'metadata': instance.metadata,
    };

const _$AIChatMessageTypeEnumMap = {
  AIChatMessageType.general: 'general',
  AIChatMessageType.studyTips: 'studyTips',
  AIChatMessageType.antiBullying: 'antiBullying',
  AIChatMessageType.socialMediaLiteracy: 'socialMediaLiteracy',
};

AIChatSession _$AIChatSessionFromJson(Map<String, dynamic> json) =>
    AIChatSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => AIChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt:
          json['endedAt'] == null
              ? null
              : DateTime.parse(json['endedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AIChatSessionToJson(AIChatSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'messages': instance.messages,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'metadata': instance.metadata,
    };
