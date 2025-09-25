import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

@JsonSerializable()
class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String type; // 'group', 'private'
  final Map<String, dynamic>? metadata;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.type = 'group',
    this.metadata,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime']?.toDate(),
      lastMessageSenderId: data['lastMessageSenderId'],
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      type: data['type'] ?? 'group',
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastMessageSenderId': lastMessageSenderId,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'type': type,
      'metadata': metadata,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class Message {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final String originalContent; // Untuk menyimpan pesan asli sebelum moderasi
  final MessageType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final bool isModerated; // Apakah pesan telah dimoderasi
  final List<String>? attachments;
  final String? replyToMessageId;
  final Map<String, MessageReadStatus> readStatus;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.originalContent,
    this.type = MessageType.text,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.isModerated = false,
    this.attachments,
    this.replyToMessageId,
    this.readStatus = const {},
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    Map<String, MessageReadStatus> readStatusMap = {};
    if (data['readStatus'] != null) {
      Map<String, dynamic> readStatusData = Map<String, dynamic>.from(data['readStatus']);
      readStatusData.forEach((key, value) {
        readStatusMap[key] = MessageReadStatus.fromMap(Map<String, dynamic>.from(value));
      });
    }

    return Message(
      id: doc.id,
      chatRoomId: data['chatRoomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      originalContent: data['originalContent'] ?? data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate(),
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      isModerated: data['isModerated'] ?? false,
      attachments: data['attachments'] != null ? List<String>.from(data['attachments']) : null,
      replyToMessageId: data['replyToMessageId'],
      readStatus: readStatusMap,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> readStatusMap = {};
    readStatus.forEach((key, value) {
      readStatusMap[key] = value.toMap();
    });

    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'originalContent': originalContent,
      'type': type.toString().split('.').last,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isModerated': isModerated,
      'attachments': attachments,
      'replyToMessageId': replyToMessageId,
      'readStatus': readStatusMap,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? senderName,
    String? content,
    String? originalContent,
    MessageType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    bool? isModerated,
    List<String>? attachments,
    String? replyToMessageId,
    Map<String, MessageReadStatus>? readStatus,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      originalContent: originalContent ?? this.originalContent,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isModerated: isModerated ?? this.isModerated,
      attachments: attachments ?? this.attachments,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      readStatus: readStatus ?? this.readStatus,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class MessageReadStatus {
  final bool isRead;
  final DateTime? readAt;
  final bool isDelivered;
  final DateTime? deliveredAt;

  MessageReadStatus({
    this.isRead = false,
    this.readAt,
    this.isDelivered = false,
    this.deliveredAt,
  });

  factory MessageReadStatus.fromJson(Map<String, dynamic> json) => _$MessageReadStatusFromJson(json);
  Map<String, dynamic> toJson() => _$MessageReadStatusToJson(this);

  factory MessageReadStatus.fromMap(Map<String, dynamic> map) {
    return MessageReadStatus(
      isRead: map['isRead'] ?? false,
      readAt: map['readAt']?.toDate(),
      isDelivered: map['isDelivered'] ?? false,
      deliveredAt: map['deliveredAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isRead': isRead,
      'readAt': readAt,
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt,
    };
  }

  MessageReadStatus copyWith({
    bool? isRead,
    DateTime? readAt,
    bool? isDelivered,
    DateTime? deliveredAt,
  }) {
    return MessageReadStatus(
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDelivered: isDelivered ?? this.isDelivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  system,
}

@JsonSerializable()
class TypingStatus {
  final String userId;
  final String userName;
  final String chatRoomId;
  final DateTime timestamp;

  TypingStatus({
    required this.userId,
    required this.userName,
    required this.chatRoomId,
    required this.timestamp,
  });

  factory TypingStatus.fromJson(Map<String, dynamic> json) => _$TypingStatusFromJson(json);
  Map<String, dynamic> toJson() => _$TypingStatusToJson(this);

  factory TypingStatus.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TypingStatus(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      chatRoomId: data['chatRoomId'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'chatRoomId': chatRoomId,
      'timestamp': timestamp,
    };
  }
}