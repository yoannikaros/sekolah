// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$PostTypeEnumMap, json['type']),
  mediaFiles:
      (json['media_files'] as List<dynamic>?)
          ?.map((e) => MediaFile.fromJson(e as Map<String, dynamic>))
          .toList(),
  authorId: (json['author_id'] as num).toInt(),
  author:
      json['author'] == null
          ? null
          : User.fromJson(json['author'] as Map<String, dynamic>),
  classId: (json['class_id'] as num?)?.toInt(),
  subject: json['subject'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  status: $enumDecode(_$PostStatusEnumMap, json['status']),
  approvedBy: (json['approved_by'] as num?)?.toInt(),
  approvedAt:
      json['approved_at'] == null
          ? null
          : DateTime.parse(json['approved_at'] as String),
  likes:
      (json['likes'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  views: (json['views'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  likesCount: (json['likes_count'] as num?)?.toInt(),
  commentsCount: (json['comments_count'] as num?)?.toInt(),
  isLiked: json['isLiked'] as bool? ?? false,
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'type': _$PostTypeEnumMap[instance.type]!,
  'media_files': instance.mediaFiles,
  'author_id': instance.authorId,
  'author': instance.author,
  'class_id': instance.classId,
  'subject': instance.subject,
  'tags': instance.tags,
  'status': _$PostStatusEnumMap[instance.status]!,
  'approved_by': instance.approvedBy,
  'approved_at': instance.approvedAt?.toIso8601String(),
  'likes': instance.likes,
  'views': instance.views,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'likes_count': instance.likesCount,
  'comments_count': instance.commentsCount,
  'isLiked': instance.isLiked,
};

const _$PostTypeEnumMap = {
  PostType.artwork: 'artwork',
  PostType.assignment: 'assignment',
  PostType.project: 'project',
};

const _$PostStatusEnumMap = {
  PostStatus.draft: 'draft',
  PostStatus.pending: 'pending',
  PostStatus.approved: 'approved',
  PostStatus.rejected: 'rejected',
};

MediaFile _$MediaFileFromJson(Map<String, dynamic> json) => MediaFile(
  id: (json['id'] as num).toInt(),
  filename: json['filename'] as String,
  path: json['path'] as String,
  thumbnailPath: json['thumbnail_path'] as String?,
  type: json['type'] as String,
  url: json['url'] as String,
);

Map<String, dynamic> _$MediaFileToJson(MediaFile instance) => <String, dynamic>{
  'id': instance.id,
  'filename': instance.filename,
  'path': instance.path,
  'thumbnail_path': instance.thumbnailPath,
  'type': instance.type,
  'url': instance.url,
};

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  id: (json['id'] as num).toInt(),
  postId: (json['post_id'] as num).toInt(),
  authorId: (json['author_id'] as num).toInt(),
  author:
      json['author'] == null
          ? null
          : User.fromJson(json['author'] as Map<String, dynamic>),
  content: json['content'] as String,
  parentCommentId: (json['parent_comment_id'] as num?)?.toInt(),
  status: $enumDecode(_$CommentStatusEnumMap, json['status']),
  moderatedBy: (json['moderated_by'] as num?)?.toInt(),
  moderatedAt:
      json['moderated_at'] == null
          ? null
          : DateTime.parse(json['moderated_at'] as String),
  likes:
      (json['likes'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  createdAt: DateTime.parse(json['created_at'] as String),
  replies:
      (json['replies'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'id': instance.id,
  'post_id': instance.postId,
  'author_id': instance.authorId,
  'author': instance.author,
  'content': instance.content,
  'parent_comment_id': instance.parentCommentId,
  'status': _$CommentStatusEnumMap[instance.status]!,
  'moderated_by': instance.moderatedBy,
  'moderated_at': instance.moderatedAt?.toIso8601String(),
  'likes': instance.likes,
  'created_at': instance.createdAt.toIso8601String(),
  'replies': instance.replies,
};

const _$CommentStatusEnumMap = {
  CommentStatus.pending: 'pending',
  CommentStatus.approved: 'approved',
  CommentStatus.rejected: 'rejected',
};
