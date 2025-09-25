import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part 'mading_models.g.dart';

@JsonSerializable()
class MadingPost {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? documentUrl;
  final String authorId;
  final String authorName;
  final String schoolId;
  final String classCode;
  final MadingType type;
  final MadingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? dueDate; // untuk tugas terjadwal
  final List<MadingComment> comments;
  final int likesCount;
  final List<String> tags;
  final bool isPublished;
  final String? teacherId; // untuk tugas yang diberikan guru

  MadingPost({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.documentUrl,
    required this.authorId,
    required this.authorName,
    required this.schoolId,
    required this.classCode,
    required this.type,
    this.status = MadingStatus.draft,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.comments = const [],
    this.likesCount = 0,
    this.tags = const [],
    this.isPublished = false,
    this.teacherId,
  });

  MadingPost copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? documentUrl,
    String? authorId,
    String? authorName,
    String? schoolId,
    String? classCode,
    MadingType? type,
    MadingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    List<MadingComment>? comments,
    int? likesCount,
    List<String>? tags,
    bool? isPublished,
    String? teacherId,
  }) {
    return MadingPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      schoolId: schoolId ?? this.schoolId,
      classCode: classCode ?? this.classCode,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
      likesCount: likesCount ?? this.likesCount,
      tags: tags ?? this.tags,
      isPublished: isPublished ?? this.isPublished,
      teacherId: teacherId ?? this.teacherId,
    );
  }

  factory MadingPost.fromJson(Map<String, dynamic> json) =>
      _$MadingPostFromJson(json);

  Map<String, dynamic> toJson() => _$MadingPostToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MadingPost &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.documentUrl == documentUrl &&
        other.authorId == authorId &&
        other.authorName == authorName &&
        other.schoolId == schoolId &&
        other.classCode == classCode &&
        other.type == type &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.dueDate == dueDate &&
        listEquals(other.comments, comments) &&
        other.likesCount == likesCount &&
        listEquals(other.tags, tags) &&
        other.isPublished == isPublished &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      title,
      description,
      imageUrl,
      documentUrl,
      authorId,
      authorName,
      schoolId,
      classCode,
      type,
      status,
      createdAt,
      updatedAt,
      dueDate,
      comments,
      likesCount,
      tags,
      isPublished,
      teacherId,
    ]);
  }

  @override
  String toString() {
    return 'MadingPost(id: $id, title: $title, type: $type, status: $status, authorName: $authorName, classCode: $classCode)';
  }
}

@JsonSerializable()
class MadingComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isApproved; // untuk komentar terkurasi
  final String? moderatorId;
  final DateTime? approvedAt;

  MadingComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.isApproved = false,
    this.moderatorId,
    this.approvedAt,
  });

  MadingComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    bool? isApproved,
    String? moderatorId,
    DateTime? approvedAt,
  }) {
    return MadingComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
      moderatorId: moderatorId ?? this.moderatorId,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  factory MadingComment.fromJson(Map<String, dynamic> json) =>
      _$MadingCommentFromJson(json);

  Map<String, dynamic> toJson() => _$MadingCommentToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MadingComment &&
        other.id == id &&
        other.postId == postId &&
        other.authorId == authorId &&
        other.authorName == authorName &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.isApproved == isApproved &&
        other.moderatorId == moderatorId &&
        other.approvedAt == approvedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      postId,
      authorId,
      authorName,
      content,
      createdAt,
      isApproved,
      moderatorId,
      approvedAt,
    );
  }

  @override
  String toString() {
    return 'MadingComment(id: $id, authorName: $authorName, isApproved: $isApproved)';
  }
}

enum MadingType {
  @JsonValue('assignment')
  assignment, // tugas terjadwal dari guru
  @JsonValue('student_work')
  studentWork, // karya siswa
  @JsonValue('announcement')
  announcement, // pengumuman
}

enum MadingStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
  @JsonValue('archived')
  archived,
  @JsonValue('rejected')
  rejected,
}

@JsonSerializable()
class MadingFilter {
  final String? schoolId;
  final String? classCode;
  final MadingType? type;
  final MadingStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? authorId;
  final String? teacherId;
  final List<String>? tags;
  final bool? isPublished;

  MadingFilter({
    this.schoolId,
    this.classCode,
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.authorId,
    this.teacherId,
    this.tags,
    this.isPublished,
  });

  MadingFilter copyWith({
    String? schoolId,
    String? classCode,
    MadingType? type,
    MadingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? authorId,
    String? teacherId,
    List<String>? tags,
    bool? isPublished,
  }) {
    return MadingFilter(
      schoolId: schoolId ?? this.schoolId,
      classCode: classCode ?? this.classCode,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      authorId: authorId ?? this.authorId,
      teacherId: teacherId ?? this.teacherId,
      tags: tags ?? this.tags,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  factory MadingFilter.fromJson(Map<String, dynamic> json) =>
      _$MadingFilterFromJson(json);

  Map<String, dynamic> toJson() => _$MadingFilterToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MadingFilter &&
        other.schoolId == schoolId &&
        other.classCode == classCode &&
        other.type == type &&
        other.status == status &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.authorId == authorId &&
        other.teacherId == teacherId &&
        listEquals(other.tags, tags) &&
        other.isPublished == isPublished;
  }

  @override
  int get hashCode {
    return Object.hash(
      schoolId,
      classCode,
      type,
      status,
      startDate,
      endDate,
      authorId,
      teacherId,
      tags,
      isPublished,
    );
  }

  @override
  String toString() {
    return 'MadingFilter(schoolId: $schoolId, classCode: $classCode, type: $type, status: $status)';
  }
}

@JsonSerializable()
class MadingSummary {
  final int totalPosts;
  final int totalComments;
  final int totalTasks;
  final int totalSubmissions;
  final int pendingApprovals;
  final DateTime lastUpdated;

  MadingSummary({
    required this.totalPosts,
    required this.totalComments,
    required this.totalTasks,
    required this.totalSubmissions,
    required this.pendingApprovals,
    required this.lastUpdated,
  });

  factory MadingSummary.fromJson(Map<String, dynamic> json) =>
      _$MadingSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$MadingSummaryToJson(this);

  @override
  String toString() {
    return 'MadingSummary(totalPosts: $totalPosts, totalComments: $totalComments, totalTasks: $totalTasks, totalSubmissions: $totalSubmissions, pendingApprovals: $pendingApprovals, lastUpdated: $lastUpdated)';
  }
}