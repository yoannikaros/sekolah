import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ai_chat_models.g.dart';

@JsonSerializable()
class AIChatConfig {
  final String id;
  final String apiKey;
  final String model; // gpt-3.5-turbo, gpt-4, etc.
  final double temperature;
  final int maxTokens;
  final String systemPrompt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  AIChatConfig({
    required this.id,
    required this.apiKey,
    this.model = 'gpt-3.5-turbo',
    this.temperature = 0.7,
    this.maxTokens = 1000,
    required this.systemPrompt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory AIChatConfig.fromJson(Map<String, dynamic> json) => _$AIChatConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AIChatConfigToJson(this);

  factory AIChatConfig.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AIChatConfig(
      id: doc.id,
      apiKey: data['apiKey'] ?? '',
      model: data['model'] ?? 'gpt-3.5-turbo',
      temperature: (data['temperature'] ?? 0.7).toDouble(),
      maxTokens: data['maxTokens'] ?? 1000,
      systemPrompt: data['systemPrompt'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'apiKey': apiKey,
      'model': model,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'systemPrompt': systemPrompt,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
    };
  }

  AIChatConfig copyWith({
    String? id,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return AIChatConfig(
      id: id ?? this.id,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Default system prompt untuk wali kelas
  static String get defaultSystemPrompt => '''
Anda adalah seorang wali kelas yang berpengalaman dan peduli terhadap siswa-siswa Anda. Tugas Anda adalah:

1. MEMBERIKAN TIPS BELAJAR:
   - Berikan strategi belajar yang efektif dan sesuai dengan tingkat siswa
   - Sarankan teknik mengatur waktu dan manajemen tugas
   - Berikan motivasi untuk semangat belajar
   - Jelaskan cara mengatasi kesulitan belajar

2. ANTI-BULLYING:
   - Berikan edukasi tentang bahaya bullying
   - Ajarkan cara menghadapi situasi bullying
   - Berikan dukungan emosional kepada siswa yang mengalami bullying
   - Jelaskan pentingnya menghormati perbedaan dan keberagaman

3. LITERASI MEDIA SOSIAL:
   - Ajarkan penggunaan media sosial yang bijak dan aman
   - Berikan tips mengenali berita hoax dan informasi palsu
   - Jelaskan pentingnya privasi dan keamanan digital
   - Ajarkan etika berkomunikasi di dunia digital

GAYA KOMUNIKASI:
- Gunakan bahasa yang ramah, hangat, dan mudah dipahami
- Berikan contoh konkret dan relevan dengan kehidupan siswa
- Tunjukkan empati dan pengertian
- Dorong siswa untuk bertanya dan berdiskusi
- Selalu berikan dukungan positif

BATASAN:
- Jangan memberikan nasihat medis atau psikologis yang mendalam
- Arahkan ke konselor sekolah jika ada masalah serius
- Jangan membahas topik yang tidak pantas untuk siswa
- Fokus pada peran sebagai wali kelas yang mendidik dan membimbing

Jawab semua pertanyaan dengan penuh perhatian dan kasih sayang seperti seorang wali kelas yang baik.
''';
}

@JsonSerializable()
class AIChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final String response;
  final DateTime createdAt;
  final AIChatMessageType type;
  final Map<String, dynamic>? metadata;

  AIChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.response,
    required this.createdAt,
    this.type = AIChatMessageType.general,
    this.metadata,
  });

  factory AIChatMessage.fromJson(Map<String, dynamic> json) => _$AIChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$AIChatMessageToJson(this);

  factory AIChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AIChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      message: data['message'] ?? '',
      response: data['response'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      type: AIChatMessageType.values.firstWhere(
        (e) => e.toString() == 'AIChatMessageType.${data['type']}',
        orElse: () => AIChatMessageType.general,
      ),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'response': response,
      'createdAt': createdAt,
      'type': type.toString().split('.').last,
      'metadata': metadata,
    };
  }

  AIChatMessage copyWith({
    String? id,
    String? userId,
    String? userName,
    String? message,
    String? response,
    DateTime? createdAt,
    AIChatMessageType? type,
    Map<String, dynamic>? metadata,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum AIChatMessageType {
  general,
  studyTips,
  antiBullying,
  socialMediaLiteracy,
}

@JsonSerializable()
class AIChatSession {
  final String id;
  final String userId;
  final String userName;
  final List<AIChatMessage> messages;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  AIChatSession({
    required this.id,
    required this.userId,
    required this.userName,
    this.messages = const [],
    required this.startedAt,
    this.endedAt,
    this.isActive = true,
    this.metadata,
  });

  factory AIChatSession.fromJson(Map<String, dynamic> json) => _$AIChatSessionFromJson(json);
  Map<String, dynamic> toJson() => _$AIChatSessionToJson(this);

  factory AIChatSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<AIChatMessage> messagesList = [];
    if (data['messages'] != null) {
      messagesList = (data['messages'] as List)
          .map((msg) => AIChatMessage.fromJson(Map<String, dynamic>.from(msg)))
          .toList();
    }

    return AIChatSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      messages: messagesList,
      startedAt: data['startedAt']?.toDate() ?? DateTime.now(),
      endedAt: data['endedAt']?.toDate(),
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'startedAt': startedAt,
      'endedAt': endedAt,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  AIChatSession copyWith({
    String? id,
    String? userId,
    String? userName,
    List<AIChatMessage>? messages,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AIChatSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      messages: messages ?? this.messages,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}