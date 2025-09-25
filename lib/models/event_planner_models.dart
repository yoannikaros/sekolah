import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

// part 'event_planner_models.g.dart'; // Commented out until generated

@JsonSerializable()
class EventPlanner {
  final String id;
  final String title;
  final String description;
  @JsonKey(name: 'event_date')
  final DateTime eventDate;
  @JsonKey(name: 'event_time')
  final String eventTime; // Format: "HH:mm"
  @JsonKey(name: 'school_id')
  final String schoolId;
  @JsonKey(name: 'class_code')
  final String classCode;
  final EventType type;
  final EventStatus status;
  @JsonKey(name: 'created_by')
  final String createdBy;
  @JsonKey(name: 'creator_name')
  final String creatorName;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final String? location;
  final List<EventParticipant> participants;
  final String? notes;
  final Map<String, dynamic>? metadata; // Additional data
  final List<String> tags;
  @JsonKey(name: 'challenged_school_id')
  final String? challengedSchoolId; // For inter-school challenges
  @JsonKey(name: 'challenged_school_name')
  final String? challengedSchoolName; // For inter-school challenges
  final EventVisibility visibility; // New visibility field
  @JsonKey(name: 'required_class_code')
  final String? requiredClassCode; // Required class code for internal_class visibility
  @JsonKey(name: 'votes_count')
  final int votesCount; // Number of votes for public events
  @JsonKey(name: 'voters')
  final List<EventVoter> voters; // List of voters for public events
  @JsonKey(name: 'challenge_accepted')
  final bool challengeAccepted; // Whether the challenge has been accepted
  @JsonKey(name: 'challenge_deadline')
  final DateTime? challengeDeadline; // Deadline for accepting the challenge

  const EventPlanner({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.eventTime,
    required this.schoolId,
    required this.classCode,
    required this.type,
    required this.status,
    required this.createdBy,
    required this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.location,
    this.participants = const [],
    this.notes,
    this.metadata,
    this.tags = const [],
    this.challengedSchoolId,
    this.challengedSchoolName,
    this.visibility = EventVisibility.school, // Default visibility
    this.requiredClassCode,
    this.votesCount = 0,
    this.voters = const [],
    this.challengeAccepted = false,
    this.challengeDeadline,
  });

  EventPlanner copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDate,
    String? eventTime,
    String? schoolId,
    String? classCode,
    EventType? type,
    EventStatus? status,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? location,
    List<EventParticipant>? participants,
    String? notes,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    String? challengedSchoolId,
    String? challengedSchoolName,
    EventVisibility? visibility,
    String? requiredClassCode,
    int? votesCount,
    List<EventVoter>? voters,
    bool? challengeAccepted,
    DateTime? challengeDeadline,
  }) {
    return EventPlanner(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      schoolId: schoolId ?? this.schoolId,
      classCode: classCode ?? this.classCode,
      type: type ?? this.type,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
      participants: participants ?? this.participants,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      challengedSchoolId: challengedSchoolId ?? this.challengedSchoolId,
      challengedSchoolName: challengedSchoolName ?? this.challengedSchoolName,
      visibility: visibility ?? this.visibility,
      requiredClassCode: requiredClassCode ?? this.requiredClassCode,
      votesCount: votesCount ?? this.votesCount,
      voters: voters ?? this.voters,
      challengeAccepted: challengeAccepted ?? this.challengeAccepted,
      challengeDeadline: challengeDeadline ?? this.challengeDeadline,
    );
  }

  // Manual fromJson and toJson methods instead of generated ones
  factory EventPlanner.fromJson(Map<String, dynamic> json) {
    return EventPlanner(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      eventTime: json['event_time'] as String,
      schoolId: json['school_id'] as String,
      classCode: json['class_code'] as String,
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] as String).replaceAll('_', ''),
        orElse: () => EventType.classActivity,
      ),
      status: EventStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] as String),
        orElse: () => EventStatus.planned,
      ),
      createdBy: json['created_by'] as String,
      creatorName: json['creator_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      location: json['location'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => EventParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      challengedSchoolId: json['challenged_school_id'] as String?,
      challengedSchoolName: json['challenged_school_name'] as String?,
      visibility: EventVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == (json['visibility'] as String? ?? 'school'),
        orElse: () => EventVisibility.school,
      ),
      requiredClassCode: json['required_class_code'] as String?,
      votesCount: json['votes_count'] as int? ?? 0,
      voters: (json['voters'] as List<dynamic>?)
              ?.map((e) => EventVoter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      challengeAccepted: json['challenge_accepted'] as bool? ?? false,
      challengeDeadline: json['challenge_deadline'] != null 
          ? DateTime.parse(json['challenge_deadline'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'event_time': eventTime,
      'school_id': schoolId,
      'class_code': classCode,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'created_by': createdBy,
      'creator_name': creatorName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'location': location,
      'participants': participants.map((e) => e.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
      'tags': tags,
      'challenged_school_id': challengedSchoolId,
      'challenged_school_name': challengedSchoolName,
      'visibility': visibility.toString().split('.').last,
      'required_class_code': requiredClassCode,
      'votes_count': votesCount,
      'voters': voters.map((e) => e.toJson()).toList(),
      'challenge_accepted': challengeAccepted,
      'challenge_deadline': challengeDeadline?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventPlanner &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.eventDate == eventDate &&
        other.eventTime == eventTime &&
        other.schoolId == schoolId &&
        other.classCode == classCode &&
        other.type == type &&
        other.status == status &&
        other.createdBy == createdBy &&
        other.creatorName == creatorName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive &&
        other.location == location &&
        listEquals(other.participants, participants) &&
        other.notes == notes &&
        other.metadata == metadata &&
        listEquals(other.tags, tags) &&
        other.challengedSchoolId == challengedSchoolId &&
        other.challengedSchoolName == challengedSchoolName &&
        other.visibility == visibility &&
        other.requiredClassCode == requiredClassCode &&
        other.votesCount == votesCount &&
        listEquals(other.voters, voters) &&
        other.challengeAccepted == challengeAccepted &&
        other.challengeDeadline == challengeDeadline;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      title,
      description,
      eventDate,
      eventTime,
      schoolId,
      classCode,
      type,
      status,
      createdBy,
      creatorName,
      createdAt,
      updatedAt,
      isActive,
      location,
      participants,
      notes,
      metadata,
      tags,
      challengedSchoolId,
      challengedSchoolName,
      visibility,
      requiredClassCode,
      votesCount,
      voters,
      challengeAccepted,
      challengeDeadline,
    ]);
  }

  @override
  String toString() {
    return 'EventPlanner(id: $id, title: $title, classCode: $classCode, type: $type, eventDate: $eventDate)';
  }
}

enum EventVisibility {
  @JsonValue('internal_class')
  internalClass, // Hanya untuk kelas tertentu (perlu kode kelas)
  
  @JsonValue('school')
  school, // Untuk seluruh sekolah
  
  @JsonValue('public')
  public, // Tantangan untuk sekolah lain (perlu voting minimal 14 siswa)
}

enum EventType {
  @JsonValue('parent_meeting')
  parentMeeting, // Pertemuan orang tua
  
  @JsonValue('inter_class_competition')
  interClassCompetition, // Lomba antar kelas
  
  @JsonValue('inter_school_challenge')
  interSchoolChallenge, // Tantangan antar sekolah
  
  @JsonValue('school_event')
  schoolEvent, // Event sekolah umum
  
  @JsonValue('class_activity')
  classActivity, // Kegiatan kelas
}

enum EventStatus {
  @JsonValue('planned')
  planned, // Direncanakan
  
  @JsonValue('confirmed')
  confirmed, // Dikonfirmasi
  
  @JsonValue('ongoing')
  ongoing, // Sedang berlangsung
  
  @JsonValue('completed')
  completed, // Selesai
  
  @JsonValue('cancelled')
  cancelled, // Dibatalkan
  
  @JsonValue('postponed')
  postponed, // Ditunda
}

// Model untuk voter dalam sistem voting tantangan antar sekolah
@JsonSerializable()
class EventVoter {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'user_name')
  final String userName;
  @JsonKey(name: 'school_id')
  final String schoolId;
  @JsonKey(name: 'school_name')
  final String schoolName;
  @JsonKey(name: 'voted_at')
  final DateTime votedAt;
  @JsonKey(name: 'vote_type')
  final String voteType; // 'accept' or 'reject'

  const EventVoter({
    required this.userId,
    required this.userName,
    required this.schoolId,
    required this.schoolName,
    required this.votedAt,
    this.voteType = 'accept',
  });

  factory EventVoter.fromJson(Map<String, dynamic> json) {
    return EventVoter(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      schoolId: json['school_id'] as String,
      schoolName: json['school_name'] as String,
      votedAt: DateTime.parse(json['voted_at'] as String),
      voteType: json['vote_type'] as String? ?? 'accept',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'school_id': schoolId,
      'school_name': schoolName,
      'voted_at': votedAt.toIso8601String(),
      'vote_type': voteType,
    };
  }
}

// Model untuk participant response (opsional untuk future enhancement)
@JsonSerializable()
class EventParticipant {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'user_name')
  final String userName;
  @JsonKey(name: 'user_role')
  final String userRole; // 'student', 'teacher', 'parent'
  @JsonKey(name: 'participation_status')
  final String participationStatus; // 'invited', 'confirmed', 'declined', 'attended'
  @JsonKey(name: 'joined_at')
  final DateTime? joinedAt;
  final String? notes;

  const EventParticipant({
    required this.userId,
    required this.userName,
    required this.userRole,
    this.participationStatus = 'invited',
    this.joinedAt,
    this.notes,
  });

  // Manual fromJson and toJson methods
  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userRole: json['user_role'] as String,
      participationStatus: json['participation_status'] as String? ?? 'invited',
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'participation_status': participationStatus,
      'joined_at': joinedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}