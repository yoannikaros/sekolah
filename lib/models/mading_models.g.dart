// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mading_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MadingPost _$MadingPostFromJson(Map<String, dynamic> json) => MadingPost(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  imageUrl: json['imageUrl'] as String?,
  documentUrl: json['documentUrl'] as String?,
  authorId: json['authorId'] as String,
  authorName: json['authorName'] as String,
  schoolId: json['schoolId'] as String,
  classCode: json['classCode'] as String,
  type: $enumDecode(_$MadingTypeEnumMap, json['type']),
  status:
      $enumDecodeNullable(_$MadingStatusEnumMap, json['status']) ??
      MadingStatus.draft,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  dueDate:
      json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
  comments:
      (json['comments'] as List<dynamic>?)
          ?.map((e) => MadingComment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isPublished: json['isPublished'] as bool? ?? false,
  teacherId: json['teacherId'] as String?,
);

Map<String, dynamic> _$MadingPostToJson(MadingPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'documentUrl': instance.documentUrl,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'schoolId': instance.schoolId,
      'classCode': instance.classCode,
      'type': _$MadingTypeEnumMap[instance.type]!,
      'status': _$MadingStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'dueDate': instance.dueDate?.toIso8601String(),
      'comments': instance.comments,
      'likesCount': instance.likesCount,
      'tags': instance.tags,
      'isPublished': instance.isPublished,
      'teacherId': instance.teacherId,
    };

const _$MadingTypeEnumMap = {
  MadingType.assignment: 'assignment',
  MadingType.studentWork: 'student_work',
  MadingType.announcement: 'announcement',
};

const _$MadingStatusEnumMap = {
  MadingStatus.draft: 'draft',
  MadingStatus.published: 'published',
  MadingStatus.archived: 'archived',
  MadingStatus.rejected: 'rejected',
};

MadingComment _$MadingCommentFromJson(Map<String, dynamic> json) =>
    MadingComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isApproved: json['isApproved'] as bool? ?? false,
      moderatorId: json['moderatorId'] as String?,
      approvedAt:
          json['approvedAt'] == null
              ? null
              : DateTime.parse(json['approvedAt'] as String),
    );

Map<String, dynamic> _$MadingCommentToJson(MadingComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'isApproved': instance.isApproved,
      'moderatorId': instance.moderatorId,
      'approvedAt': instance.approvedAt?.toIso8601String(),
    };

MadingFilter _$MadingFilterFromJson(Map<String, dynamic> json) => MadingFilter(
  schoolId: json['schoolId'] as String?,
  classCode: json['classCode'] as String?,
  type: $enumDecodeNullable(_$MadingTypeEnumMap, json['type']),
  status: $enumDecodeNullable(_$MadingStatusEnumMap, json['status']),
  startDate:
      json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
  endDate:
      json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
  authorId: json['authorId'] as String?,
  teacherId: json['teacherId'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  isPublished: json['isPublished'] as bool?,
);

Map<String, dynamic> _$MadingFilterToJson(MadingFilter instance) =>
    <String, dynamic>{
      'schoolId': instance.schoolId,
      'classCode': instance.classCode,
      'type': _$MadingTypeEnumMap[instance.type],
      'status': _$MadingStatusEnumMap[instance.status],
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'authorId': instance.authorId,
      'teacherId': instance.teacherId,
      'tags': instance.tags,
      'isPublished': instance.isPublished,
    };

MadingSummary _$MadingSummaryFromJson(Map<String, dynamic> json) =>
    MadingSummary(
      totalPosts: (json['totalPosts'] as num).toInt(),
      totalComments: (json['totalComments'] as num).toInt(),
      totalTasks: (json['totalTasks'] as num).toInt(),
      totalSubmissions: (json['totalSubmissions'] as num).toInt(),
      pendingApprovals: (json['pendingApprovals'] as num).toInt(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$MadingSummaryToJson(MadingSummary instance) =>
    <String, dynamic>{
      'totalPosts': instance.totalPosts,
      'totalComments': instance.totalComments,
      'totalTasks': instance.totalTasks,
      'totalSubmissions': instance.totalSubmissions,
      'pendingApprovals': instance.pendingApprovals,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
