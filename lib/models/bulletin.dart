import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'bulletin.g.dart';

@JsonSerializable()
class BulletinPost {
  final int id;
  final String title;
  final String? description;
  final BulletinPostType type;
  @JsonKey(name: 'media_files')
  final List<BulletinMediaFile>? mediaFiles;
  @JsonKey(name: 'author_id')
  final int authorId;
  final User? author;
  @JsonKey(name: 'class_id')
  final int? classId;
  final String? subject;
  final List<String>? tags;
  final BulletinPostStatus status;
  @JsonKey(name: 'approved_by')
  final int? approvedBy;
  @JsonKey(name: 'approved_at')
  final DateTime? approvedAt;
  final List<int>? likes;
  final int views;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'likes_count')
  final int likesCount;
  @JsonKey(name: 'comments_count')
  final int commentsCount;
  @JsonKey(name: 'is_liked')
  final bool isLiked;

  BulletinPost({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.mediaFiles,
    required this.authorId,
    this.author,
    this.classId,
    this.subject,
    this.tags,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.likes,
    required this.views,
    required this.createdAt,
    this.updatedAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
  });

  factory BulletinPost.fromJson(Map<String, dynamic> json) => _$BulletinPostFromJson(json);
  Map<String, dynamic> toJson() => _$BulletinPostToJson(this);
}

@JsonSerializable()
class BulletinMediaFile {
  final String filename;
  final String path;
  final String type;
  final int size;
  @JsonKey(name: 'uploaded_at')
  final DateTime uploadedAt;

  BulletinMediaFile({
    required this.filename,
    required this.path,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  factory BulletinMediaFile.fromJson(Map<String, dynamic> json) => _$BulletinMediaFileFromJson(json);
  Map<String, dynamic> toJson() => _$BulletinMediaFileToJson(this);
}

@JsonSerializable()
class BulletinComment {
  final int id;
  @JsonKey(name: 'post_id')
  final int postId;
  @JsonKey(name: 'author_id')
  final int authorId;
  final User? author;
  final String content;
  @JsonKey(name: 'parent_comment_id')
  final int? parentCommentId;
  final BulletinCommentStatus status;
  @JsonKey(name: 'moderated_by')
  final int? moderatedBy;
  @JsonKey(name: 'moderated_at')
  final DateTime? moderatedAt;
  final List<int>? likes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'likes_count')
  final int likesCount;
  @JsonKey(name: 'is_liked')
  final bool isLiked;

  BulletinComment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.author,
    required this.content,
    this.parentCommentId,
    required this.status,
    this.moderatedBy,
    this.moderatedAt,
    this.likes,
    required this.createdAt,
    required this.likesCount,
    required this.isLiked,
  });

  factory BulletinComment.fromJson(Map<String, dynamic> json) => _$BulletinCommentFromJson(json);
  Map<String, dynamic> toJson() => _$BulletinCommentToJson(this);
}

@JsonSerializable()
class CreateBulletinPostRequest {
  final String title;
  final String? description;
  final BulletinPostType type;
  @JsonKey(name: 'class_id')
  final int? classId;
  final String? subject;
  final List<String>? tags;

  CreateBulletinPostRequest({
    required this.title,
    this.description,
    required this.type,
    this.classId,
    this.subject,
    this.tags,
  });

  factory CreateBulletinPostRequest.fromJson(Map<String, dynamic> json) => _$CreateBulletinPostRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBulletinPostRequestToJson(this);
}

@JsonSerializable()
class UpdateBulletinPostRequest {
  final String title;
  final String? description;
  final BulletinPostType type;
  @JsonKey(name: 'class_id')
  final int? classId;
  final String? subject;
  final List<String>? tags;

  UpdateBulletinPostRequest({
    required this.title,
    this.description,
    required this.type,
    this.classId,
    this.subject,
    this.tags,
  });

  factory UpdateBulletinPostRequest.fromJson(Map<String, dynamic> json) => _$UpdateBulletinPostRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateBulletinPostRequestToJson(this);
}

@JsonSerializable()
class CreateBulletinCommentRequest {
  final String content;
  @JsonKey(name: 'parent_comment_id')
  final int? parentCommentId;

  CreateBulletinCommentRequest({
    required this.content,
    this.parentCommentId,
  });

  factory CreateBulletinCommentRequest.fromJson(Map<String, dynamic> json) => _$CreateBulletinCommentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateBulletinCommentRequestToJson(this);
}

@JsonSerializable()
class ModerateBulletinPostRequest {
  final BulletinPostStatus status;
  final String? reason;

  ModerateBulletinPostRequest({
    required this.status,
    this.reason,
  });

  factory ModerateBulletinPostRequest.fromJson(Map<String, dynamic> json) => _$ModerateBulletinPostRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ModerateBulletinPostRequestToJson(this);
}

@JsonSerializable()
class BulletinPostResponse {
  final BulletinPost post;
  final String message;

  BulletinPostResponse({
    required this.post,
    required this.message,
  });

  factory BulletinPostResponse.fromJson(Map<String, dynamic> json) => _$BulletinPostResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BulletinPostResponseToJson(this);
}

@JsonSerializable()
class BulletinPostsResponse {
  final List<BulletinPost> posts;
  final int total;
  final int page;
  @JsonKey(name: 'per_page')
  final int perPage;

  BulletinPostsResponse({
    required this.posts,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory BulletinPostsResponse.fromJson(Map<String, dynamic> json) => _$BulletinPostsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BulletinPostsResponseToJson(this);
}

@JsonSerializable()
class BulletinCommentsResponse {
  final List<BulletinComment> comments;
  final int total;

  BulletinCommentsResponse({
    required this.comments,
    required this.total,
  });

  factory BulletinCommentsResponse.fromJson(Map<String, dynamic> json) => _$BulletinCommentsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BulletinCommentsResponseToJson(this);
}

enum BulletinPostType {
  @JsonValue('artwork')
  artwork,
  @JsonValue('assignment')
  assignment,
  @JsonValue('project')
  project,
}

enum BulletinPostStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

enum BulletinCommentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}