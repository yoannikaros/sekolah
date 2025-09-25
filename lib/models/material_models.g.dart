// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Material _$MaterialFromJson(Map<String, dynamic> json) => Material(
  id: json['id'] as String,
  subjectId: json['subjectId'] as String,
  classCodeId: json['classCodeId'] as String,
  teacherId: json['teacherId'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  youtubeEmbedUrl: json['youtubeEmbedUrl'] as String?,
  comments:
      (json['comments'] as List<dynamic>?)
          ?.map((e) => MaterialComment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  isPublished: json['isPublished'] as bool? ?? false,
  publishedAt:
      json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  thumbnailUrl: json['thumbnailUrl'] as String?,
);

Map<String, dynamic> _$MaterialToJson(Material instance) => <String, dynamic>{
  'id': instance.id,
  'subjectId': instance.subjectId,
  'classCodeId': instance.classCodeId,
  'teacherId': instance.teacherId,
  'title': instance.title,
  'content': instance.content,
  'youtubeEmbedUrl': instance.youtubeEmbedUrl,
  'comments': instance.comments,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
  'isPublished': instance.isPublished,
  'publishedAt': instance.publishedAt?.toIso8601String(),
  'sortOrder': instance.sortOrder,
  'tags': instance.tags,
  'thumbnailUrl': instance.thumbnailUrl,
};

MaterialComment _$MaterialCommentFromJson(Map<String, dynamic> json) =>
    MaterialComment(
      id: json['id'] as String,
      materialId: json['materialId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorType: json['authorType'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      parentCommentId: json['parentCommentId'] as String?,
      attachmentUrls:
          (json['attachmentUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MaterialCommentToJson(MaterialComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'materialId': instance.materialId,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorType': instance.authorType,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
      'parentCommentId': instance.parentCommentId,
      'attachmentUrls': instance.attachmentUrls,
    };

MaterialFilter _$MaterialFilterFromJson(Map<String, dynamic> json) =>
    MaterialFilter(
      subjectId: json['subjectId'] as String?,
      classCodeId: json['classCodeId'] as String?,
      teacherId: json['teacherId'] as String?,
      isPublished: json['isPublished'] as bool?,
      isActive: json['isActive'] as bool?,
      startDate:
          json['startDate'] == null
              ? null
              : DateTime.parse(json['startDate'] as String),
      endDate:
          json['endDate'] == null
              ? null
              : DateTime.parse(json['endDate'] as String),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      searchQuery: json['searchQuery'] as String?,
    );

Map<String, dynamic> _$MaterialFilterToJson(MaterialFilter instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'classCodeId': instance.classCodeId,
      'teacherId': instance.teacherId,
      'isPublished': instance.isPublished,
      'isActive': instance.isActive,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'tags': instance.tags,
      'searchQuery': instance.searchQuery,
    };
