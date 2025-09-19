// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulletin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulletinPost _$BulletinPostFromJson(Map<String, dynamic> json) => BulletinPost(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  type: $enumDecode(_$BulletinPostTypeEnumMap, json['type']),
  mediaFiles:
      (json['media_files'] as List<dynamic>?)
          ?.map((e) => BulletinMediaFile.fromJson(e as Map<String, dynamic>))
          .toList(),
  authorId: (json['author_id'] as num).toInt(),
  author:
      json['author'] == null
          ? null
          : User.fromJson(json['author'] as Map<String, dynamic>),
  classId: (json['class_id'] as num?)?.toInt(),
  subject: json['subject'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  status: $enumDecode(_$BulletinPostStatusEnumMap, json['status']),
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
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  likesCount: (json['likes_count'] as num).toInt(),
  commentsCount: (json['comments_count'] as num).toInt(),
  isLiked: json['is_liked'] as bool,
);

Map<String, dynamic> _$BulletinPostToJson(BulletinPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$BulletinPostTypeEnumMap[instance.type]!,
      'media_files': instance.mediaFiles,
      'author_id': instance.authorId,
      'author': instance.author,
      'class_id': instance.classId,
      'subject': instance.subject,
      'tags': instance.tags,
      'status': _$BulletinPostStatusEnumMap[instance.status]!,
      'approved_by': instance.approvedBy,
      'approved_at': instance.approvedAt?.toIso8601String(),
      'likes': instance.likes,
      'views': instance.views,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'likes_count': instance.likesCount,
      'comments_count': instance.commentsCount,
      'is_liked': instance.isLiked,
    };

const _$BulletinPostTypeEnumMap = {
  BulletinPostType.artwork: 'artwork',
  BulletinPostType.assignment: 'assignment',
  BulletinPostType.project: 'project',
};

const _$BulletinPostStatusEnumMap = {
  BulletinPostStatus.draft: 'draft',
  BulletinPostStatus.pending: 'pending',
  BulletinPostStatus.approved: 'approved',
  BulletinPostStatus.rejected: 'rejected',
};

BulletinMediaFile _$BulletinMediaFileFromJson(Map<String, dynamic> json) =>
    BulletinMediaFile(
      filename: json['filename'] as String,
      path: json['path'] as String,
      type: json['type'] as String,
      size: (json['size'] as num).toInt(),
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );

Map<String, dynamic> _$BulletinMediaFileToJson(BulletinMediaFile instance) =>
    <String, dynamic>{
      'filename': instance.filename,
      'path': instance.path,
      'type': instance.type,
      'size': instance.size,
      'uploaded_at': instance.uploadedAt.toIso8601String(),
    };

BulletinComment _$BulletinCommentFromJson(Map<String, dynamic> json) =>
    BulletinComment(
      id: (json['id'] as num).toInt(),
      postId: (json['post_id'] as num).toInt(),
      authorId: (json['author_id'] as num).toInt(),
      author:
          json['author'] == null
              ? null
              : User.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      parentCommentId: (json['parent_comment_id'] as num?)?.toInt(),
      status: $enumDecode(_$BulletinCommentStatusEnumMap, json['status']),
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
      likesCount: (json['likes_count'] as num).toInt(),
      isLiked: json['is_liked'] as bool,
    );

Map<String, dynamic> _$BulletinCommentToJson(BulletinComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'post_id': instance.postId,
      'author_id': instance.authorId,
      'author': instance.author,
      'content': instance.content,
      'parent_comment_id': instance.parentCommentId,
      'status': _$BulletinCommentStatusEnumMap[instance.status]!,
      'moderated_by': instance.moderatedBy,
      'moderated_at': instance.moderatedAt?.toIso8601String(),
      'likes': instance.likes,
      'created_at': instance.createdAt.toIso8601String(),
      'likes_count': instance.likesCount,
      'is_liked': instance.isLiked,
    };

const _$BulletinCommentStatusEnumMap = {
  BulletinCommentStatus.pending: 'pending',
  BulletinCommentStatus.approved: 'approved',
  BulletinCommentStatus.rejected: 'rejected',
};

CreateBulletinPostRequest _$CreateBulletinPostRequestFromJson(
  Map<String, dynamic> json,
) => CreateBulletinPostRequest(
  title: json['title'] as String,
  description: json['description'] as String?,
  type: $enumDecode(_$BulletinPostTypeEnumMap, json['type']),
  classId: (json['class_id'] as num?)?.toInt(),
  subject: json['subject'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$CreateBulletinPostRequestToJson(
  CreateBulletinPostRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'type': _$BulletinPostTypeEnumMap[instance.type]!,
  'class_id': instance.classId,
  'subject': instance.subject,
  'tags': instance.tags,
};

UpdateBulletinPostRequest _$UpdateBulletinPostRequestFromJson(
  Map<String, dynamic> json,
) => UpdateBulletinPostRequest(
  title: json['title'] as String,
  description: json['description'] as String?,
  type: $enumDecode(_$BulletinPostTypeEnumMap, json['type']),
  classId: (json['class_id'] as num?)?.toInt(),
  subject: json['subject'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$UpdateBulletinPostRequestToJson(
  UpdateBulletinPostRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'type': _$BulletinPostTypeEnumMap[instance.type]!,
  'class_id': instance.classId,
  'subject': instance.subject,
  'tags': instance.tags,
};

CreateBulletinCommentRequest _$CreateBulletinCommentRequestFromJson(
  Map<String, dynamic> json,
) => CreateBulletinCommentRequest(
  content: json['content'] as String,
  parentCommentId: (json['parent_comment_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateBulletinCommentRequestToJson(
  CreateBulletinCommentRequest instance,
) => <String, dynamic>{
  'content': instance.content,
  'parent_comment_id': instance.parentCommentId,
};

ModerateBulletinPostRequest _$ModerateBulletinPostRequestFromJson(
  Map<String, dynamic> json,
) => ModerateBulletinPostRequest(
  status: $enumDecode(_$BulletinPostStatusEnumMap, json['status']),
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$ModerateBulletinPostRequestToJson(
  ModerateBulletinPostRequest instance,
) => <String, dynamic>{
  'status': _$BulletinPostStatusEnumMap[instance.status]!,
  'reason': instance.reason,
};

BulletinPostResponse _$BulletinPostResponseFromJson(
  Map<String, dynamic> json,
) => BulletinPostResponse(
  post: BulletinPost.fromJson(json['post'] as Map<String, dynamic>),
  message: json['message'] as String,
);

Map<String, dynamic> _$BulletinPostResponseToJson(
  BulletinPostResponse instance,
) => <String, dynamic>{'post': instance.post, 'message': instance.message};

BulletinPostsResponse _$BulletinPostsResponseFromJson(
  Map<String, dynamic> json,
) => BulletinPostsResponse(
  posts:
      (json['posts'] as List<dynamic>)
          .map((e) => BulletinPost.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
);

Map<String, dynamic> _$BulletinPostsResponseToJson(
  BulletinPostsResponse instance,
) => <String, dynamic>{
  'posts': instance.posts,
  'total': instance.total,
  'page': instance.page,
  'per_page': instance.perPage,
};

BulletinCommentsResponse _$BulletinCommentsResponseFromJson(
  Map<String, dynamic> json,
) => BulletinCommentsResponse(
  comments:
      (json['comments'] as List<dynamic>)
          .map((e) => BulletinComment.fromJson(e as Map<String, dynamic>))
          .toList(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$BulletinCommentsResponseToJson(
  BulletinCommentsResponse instance,
) => <String, dynamic>{'comments': instance.comments, 'total': instance.total};
