// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoom _$ChatRoomFromJson(Map<String, dynamic> json) => ChatRoom(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  participants:
      (json['participants'] as List<dynamic>).map((e) => e as String).toList(),
  lastMessage: json['lastMessage'] as String?,
  lastMessageTime:
      json['lastMessageTime'] == null
          ? null
          : DateTime.parse(json['lastMessageTime'] as String),
  lastMessageSenderId: json['lastMessageSenderId'] as String?,
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  type: json['type'] as String? ?? 'group',
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChatRoomToJson(ChatRoom instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'participants': instance.participants,
  'lastMessage': instance.lastMessage,
  'lastMessageTime': instance.lastMessageTime?.toIso8601String(),
  'lastMessageSenderId': instance.lastMessageSenderId,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
  'type': instance.type,
  'metadata': instance.metadata,
};

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  chatRoomId: json['chatRoomId'] as String,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  content: json['content'] as String,
  originalContent: json['originalContent'] as String,
  type:
      $enumDecodeNullable(_$MessageTypeEnumMap, json['type']) ??
      MessageType.text,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  isEdited: json['isEdited'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  isModerated: json['isModerated'] as bool? ?? false,
  attachments:
      (json['attachments'] as List<dynamic>?)?.map((e) => e as String).toList(),
  replyToMessageId: json['replyToMessageId'] as String?,
  readStatus:
      (json['readStatus'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, MessageReadStatus.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'chatRoomId': instance.chatRoomId,
  'senderId': instance.senderId,
  'senderName': instance.senderName,
  'content': instance.content,
  'originalContent': instance.originalContent,
  'type': _$MessageTypeEnumMap[instance.type]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'isEdited': instance.isEdited,
  'isDeleted': instance.isDeleted,
  'isModerated': instance.isModerated,
  'attachments': instance.attachments,
  'replyToMessageId': instance.replyToMessageId,
  'readStatus': instance.readStatus,
  'metadata': instance.metadata,
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.file: 'file',
  MessageType.audio: 'audio',
  MessageType.video: 'video',
  MessageType.system: 'system',
};

MessageReadStatus _$MessageReadStatusFromJson(Map<String, dynamic> json) =>
    MessageReadStatus(
      isRead: json['isRead'] as bool? ?? false,
      readAt:
          json['readAt'] == null
              ? null
              : DateTime.parse(json['readAt'] as String),
      isDelivered: json['isDelivered'] as bool? ?? false,
      deliveredAt:
          json['deliveredAt'] == null
              ? null
              : DateTime.parse(json['deliveredAt'] as String),
    );

Map<String, dynamic> _$MessageReadStatusToJson(MessageReadStatus instance) =>
    <String, dynamic>{
      'isRead': instance.isRead,
      'readAt': instance.readAt?.toIso8601String(),
      'isDelivered': instance.isDelivered,
      'deliveredAt': instance.deliveredAt?.toIso8601String(),
    };

TypingStatus _$TypingStatusFromJson(Map<String, dynamic> json) => TypingStatus(
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  chatRoomId: json['chatRoomId'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$TypingStatusToJson(TypingStatus instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userName': instance.userName,
      'chatRoomId': instance.chatRoomId,
      'timestamp': instance.timestamp.toIso8601String(),
    };
