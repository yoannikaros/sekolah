import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_media_models.g.dart';

enum PostType {
  @JsonValue('topic')
  topic,
  @JsonValue('status')
  status,
}

@JsonSerializable()
class SocialMediaPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String originalContent; // Untuk menyimpan konten asli sebelum moderasi
  final PostType type;
  final String? classCode; // Kode kelas untuk filtering
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final bool isModerated; // Apakah post telah dimoderasi
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final Map<String, dynamic>? metadata;

  SocialMediaPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.originalContent,
    this.type = PostType.status,
    this.classCode,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.isModerated = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.metadata,
  });

  factory SocialMediaPost.fromJson(Map<String, dynamic> json) => _$SocialMediaPostFromJson(json);
  Map<String, dynamic> toJson() => _$SocialMediaPostToJson(this);

  factory SocialMediaPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SocialMediaPost(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      content: data['content'] ?? '',
      originalContent: data['originalContent'] ?? data['content'] ?? '',
      type: PostType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => PostType.status,
      ),
      classCode: data['classCode'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate(),
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      isModerated: data['isModerated'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'originalContent': originalContent,
      'type': type.toString().split('.').last,
      'classCode': classCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isModerated': isModerated,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'metadata': metadata,
    };
  }

  SocialMediaPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    String? originalContent,
    PostType? type,
    String? classCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    bool? isModerated,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    Map<String, dynamic>? metadata,
  }) {
    return SocialMediaPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      originalContent: originalContent ?? this.originalContent,
      type: type ?? this.type,
      classCode: classCode ?? this.classCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isModerated: isModerated ?? this.isModerated,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String originalContent; // Untuk menyimpan komentar asli sebelum moderasi
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final bool isModerated; // Apakah komentar telah dimoderasi
  final int likesCount;
  final List<String> likedBy;
  final String? replyToCommentId; // Untuk reply ke komentar lain
  final Map<String, dynamic>? metadata;

  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.originalContent,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.isModerated = false,
    this.likesCount = 0,
    this.likedBy = const [],
    this.replyToCommentId,
    this.metadata,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => _$PostCommentFromJson(json);
  Map<String, dynamic> toJson() => _$PostCommentToJson(this);

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      content: data['content'] ?? '',
      originalContent: data['originalContent'] ?? data['content'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate(),
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      isModerated: data['isModerated'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      replyToCommentId: data['replyToCommentId'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'originalContent': originalContent,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isModerated': isModerated,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'replyToCommentId': replyToCommentId,
      'metadata': metadata,
    };
  }

  PostComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    String? originalContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    bool? isModerated,
    int? likesCount,
    List<String>? likedBy,
    String? replyToCommentId,
    Map<String, dynamic>? metadata,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      originalContent: originalContent ?? this.originalContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isModerated: isModerated ?? this.isModerated,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      replyToCommentId: replyToCommentId ?? this.replyToCommentId,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class PostLike {
  final String id;
  final String postId;
  final String? commentId; // Null jika like untuk post, ada value jika like untuk comment
  final String userId;
  final String userName;
  final DateTime createdAt;

  PostLike({
    required this.id,
    required this.postId,
    this.commentId,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory PostLike.fromJson(Map<String, dynamic> json) => _$PostLikeFromJson(json);
  Map<String, dynamic> toJson() => _$PostLikeToJson(this);

  factory PostLike.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostLike(
      id: doc.id,
      postId: data['postId'] ?? '',
      commentId: data['commentId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'commentId': commentId,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt,
    };
  }
}

@JsonSerializable()
class UserProfile {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;
  final String? classCode;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.bio,
    this.classCode,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isActive = true,
    this.metadata,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] ?? '',
      avatar: data['avatar'],
      bio: data['bio'],
      classCode: data['classCode'],
      email: data['email'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'classCode': classCode,
      'email': email,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? avatar,
    String? bio,
    String? classCode,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      classCode: classCode ?? this.classCode,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class UserFollow {
  final String id;
  final String followerId; // User yang melakukan follow
  final String followingId; // User yang di-follow
  final String followerName;
  final String followingName;
  final DateTime createdAt;
  final bool isActive;

  UserFollow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.followerName,
    required this.followingName,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserFollow.fromJson(Map<String, dynamic> json) => _$UserFollowFromJson(json);
  Map<String, dynamic> toJson() => _$UserFollowToJson(this);

  factory UserFollow.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserFollow(
      id: doc.id,
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      followerName: data['followerName'] ?? '',
      followingName: data['followingName'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'followerName': followerName,
      'followingName': followingName,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}