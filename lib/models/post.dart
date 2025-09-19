import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'user.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  final int id;
  final String title;
  final String description;
  final PostType type;
  @JsonKey(name: 'media_files')
  final List<MediaFile>? mediaFiles;
  @JsonKey(name: 'author_id')
  final int authorId;
  final User? author;
  @JsonKey(name: 'class_id')
  final int? classId;
  final String? subject;
  final List<String>? tags;
  final PostStatus status;
  @JsonKey(name: 'approved_by')
  final int? approvedBy;
  @JsonKey(name: 'approved_at')
  final DateTime? approvedAt;
  final List<int>? likes;
  final int views;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'likes_count')
  final int? likesCount;
  @JsonKey(name: 'comments_count')
  final int? commentsCount;
  final bool isLiked;

  Post({
    required this.id,
    required this.title,
    required this.description,
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
    required this.updatedAt,
    this.likesCount,
    this.commentsCount,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  bool get isLikedByUser => likes?.contains(authorId) ?? false;
  int get totalLikes => likes?.length ?? 0;
}

@JsonSerializable()
class MediaFile {
  final int id;
  final String filename;
  final String path;
  @JsonKey(name: 'thumbnail_path')
  final String? thumbnailPath;
  final String type;
  final String url;

  MediaFile({
    required this.id,
    required this.filename,
    required this.path,
    this.thumbnailPath,
    required this.type,
    required this.url,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) => _$MediaFileFromJson(json);
  Map<String, dynamic> toJson() => _$MediaFileToJson(this);
}

@JsonSerializable()
class Comment {
  final int id;
  @JsonKey(name: 'post_id')
  final int postId;
  @JsonKey(name: 'author_id')
  final int authorId;
  final User? author;
  final String content;
  @JsonKey(name: 'parent_comment_id')
  final int? parentCommentId;
  final CommentStatus status;
  @JsonKey(name: 'moderated_by')
  final int? moderatedBy;
  @JsonKey(name: 'moderated_at')
  final DateTime? moderatedAt;
  final List<int>? likes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<Comment>? replies;

  Comment({
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
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);

  bool get isLikedByUser => likes?.contains(authorId) ?? false;
  int get totalLikes => likes?.length ?? 0;
}

enum PostType {
  @JsonValue('artwork')
  artwork,
  @JsonValue('assignment')
  assignment,
  @JsonValue('project')
  project,
}

enum PostStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

enum CommentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

// Extension for CommentStatus
extension CommentStatusExtension on CommentStatus {
  String get displayName {
    switch (this) {
      case CommentStatus.pending:
        return 'Menunggu';
      case CommentStatus.approved:
        return 'Disetujui';
      case CommentStatus.rejected:
        return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case CommentStatus.pending:
        return Colors.orange;
      case CommentStatus.approved:
        return Colors.green;
      case CommentStatus.rejected:
        return Colors.red;
    }
  }
}

// Extension for PostType
extension PostTypeExtension on PostType {
  String get displayName {
    switch (this) {
      case PostType.artwork:
        return 'Karya Seni';
      case PostType.assignment:
        return 'Tugas';
      case PostType.project:
        return 'Proyek';
    }
  }

  IconData get icon {
    switch (this) {
      case PostType.artwork:
        return LucideIcons.palette;
      case PostType.assignment:
        return LucideIcons.fileText;
      case PostType.project:
        return LucideIcons.rocket;
    }
  }
}

// Extension for PostStatus
extension PostStatusExtension on PostStatus {
  String get displayName {
    switch (this) {
      case PostStatus.draft:
        return 'Draft';
      case PostStatus.pending:
        return 'Menunggu Persetujuan';
      case PostStatus.approved:
        return 'Disetujui';
      case PostStatus.rejected:
        return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case PostStatus.draft:
        return Colors.grey;
      case PostStatus.pending:
        return Colors.orange;
      case PostStatus.approved:
        return Colors.green;
      case PostStatus.rejected:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case PostStatus.draft:
        return LucideIcons.edit;
      case PostStatus.pending:
        return LucideIcons.clock;
      case PostStatus.approved:
        return LucideIcons.check;
      case PostStatus.rejected:
        return LucideIcons.x;
    }
  }
}