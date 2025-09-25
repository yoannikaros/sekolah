// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_media_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialMediaPost _$SocialMediaPostFromJson(
  Map<String, dynamic> json,
) => SocialMediaPost(
  id: json['id'] as String,
  authorId: json['authorId'] as String,
  authorName: json['authorName'] as String,
  authorAvatar: json['authorAvatar'] as String?,
  content: json['content'] as String,
  originalContent: json['originalContent'] as String,
  type: $enumDecodeNullable(_$PostTypeEnumMap, json['type']) ?? PostType.status,
  classCode: json['classCode'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  isEdited: json['isEdited'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  isModerated: json['isModerated'] as bool? ?? false,
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
  likedBy:
      (json['likedBy'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SocialMediaPostToJson(SocialMediaPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorAvatar': instance.authorAvatar,
      'content': instance.content,
      'originalContent': instance.originalContent,
      'type': _$PostTypeEnumMap[instance.type]!,
      'classCode': instance.classCode,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isEdited': instance.isEdited,
      'isDeleted': instance.isDeleted,
      'isModerated': instance.isModerated,
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'likedBy': instance.likedBy,
      'metadata': instance.metadata,
    };

const _$PostTypeEnumMap = {PostType.topic: 'topic', PostType.status: 'status'};

PostComment _$PostCommentFromJson(Map<String, dynamic> json) => PostComment(
  id: json['id'] as String,
  postId: json['postId'] as String,
  authorId: json['authorId'] as String,
  authorName: json['authorName'] as String,
  authorAvatar: json['authorAvatar'] as String?,
  content: json['content'] as String,
  originalContent: json['originalContent'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  isEdited: json['isEdited'] as bool? ?? false,
  isDeleted: json['isDeleted'] as bool? ?? false,
  isModerated: json['isModerated'] as bool? ?? false,
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  likedBy:
      (json['likedBy'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  replyToCommentId: json['replyToCommentId'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PostCommentToJson(PostComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorAvatar': instance.authorAvatar,
      'content': instance.content,
      'originalContent': instance.originalContent,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isEdited': instance.isEdited,
      'isDeleted': instance.isDeleted,
      'isModerated': instance.isModerated,
      'likesCount': instance.likesCount,
      'likedBy': instance.likedBy,
      'replyToCommentId': instance.replyToCommentId,
      'metadata': instance.metadata,
    };

PostLike _$PostLikeFromJson(Map<String, dynamic> json) => PostLike(
  id: json['id'] as String,
  postId: json['postId'] as String,
  commentId: json['commentId'] as String?,
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PostLikeToJson(PostLike instance) => <String, dynamic>{
  'id': instance.id,
  'postId': instance.postId,
  'commentId': instance.commentId,
  'userId': instance.userId,
  'userName': instance.userName,
  'createdAt': instance.createdAt.toIso8601String(),
};

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  name: json['name'] as String,
  avatar: json['avatar'] as String?,
  bio: json['bio'] as String?,
  classCode: json['classCode'] as String?,
  email: json['email'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
  followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
  postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'bio': instance.bio,
      'classCode': instance.classCode,
      'email': instance.email,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
      'postsCount': instance.postsCount,
      'isActive': instance.isActive,
      'metadata': instance.metadata,
    };

UserFollow _$UserFollowFromJson(Map<String, dynamic> json) => UserFollow(
  id: json['id'] as String,
  followerId: json['followerId'] as String,
  followingId: json['followingId'] as String,
  followerName: json['followerName'] as String,
  followingName: json['followingName'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$UserFollowToJson(UserFollow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'followerId': instance.followerId,
      'followingId': instance.followingId,
      'followerName': instance.followerName,
      'followingName': instance.followingName,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
    };
