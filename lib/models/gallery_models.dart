import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part 'gallery_models.g.dart';

@JsonSerializable()
class GalleryPhoto {
  final String id;
  final String title;
  final String description;
  final String originalImageUrl;
  final String watermarkedImageUrl;
  final String thumbnailUrl;
  final String schoolId;
  final String classCode;
  final String albumId;
  final String uploadedBy;
  final String uploaderName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata; // untuk menyimpan info tambahan seperti ukuran file, dimensi, dll
  final List<String> tags;

  GalleryPhoto({
    required this.id,
    required this.title,
    required this.description,
    required this.originalImageUrl,
    required this.watermarkedImageUrl,
    required this.thumbnailUrl,
    required this.schoolId,
    required this.classCode,
    required this.albumId,
    required this.uploadedBy,
    required this.uploaderName,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.metadata,
    this.tags = const [],
  });

  GalleryPhoto copyWith({
    String? id,
    String? title,
    String? description,
    String? originalImageUrl,
    String? watermarkedImageUrl,
    String? thumbnailUrl,
    String? schoolId,
    String? classCode,
    String? albumId,
    String? uploadedBy,
    String? uploaderName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) {
    return GalleryPhoto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      originalImageUrl: originalImageUrl ?? this.originalImageUrl,
      watermarkedImageUrl: watermarkedImageUrl ?? this.watermarkedImageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      schoolId: schoolId ?? this.schoolId,
      classCode: classCode ?? this.classCode,
      albumId: albumId ?? this.albumId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploaderName: uploaderName ?? this.uploaderName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
    );
  }

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) =>
      _$GalleryPhotoFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryPhotoToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryPhoto &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.originalImageUrl == originalImageUrl &&
        other.watermarkedImageUrl == watermarkedImageUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.schoolId == schoolId &&
        other.classCode == classCode &&
        other.albumId == albumId &&
        other.uploadedBy == uploadedBy &&
        other.uploaderName == uploaderName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive &&
        mapEquals(other.metadata, metadata) &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      originalImageUrl,
      watermarkedImageUrl,
      thumbnailUrl,
      schoolId,
      classCode,
      albumId,
      uploadedBy,
      uploaderName,
      createdAt,
      updatedAt,
      isActive,
      metadata,
      tags,
    );
  }

  @override
  String toString() {
    return 'GalleryPhoto(id: $id, title: $title, classCode: $classCode, albumId: $albumId)';
  }
}

@JsonSerializable()
class GalleryAlbum {
  final String id;
  final String name;
  final String description;
  final String schoolId;
  final String classCode;
  final String coverImageUrl;
  final String createdBy;
  final String creatorName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int photoCount;
  final List<String> tags;

  GalleryAlbum({
    required this.id,
    required this.name,
    required this.description,
    required this.schoolId,
    required this.classCode,
    required this.coverImageUrl,
    required this.createdBy,
    required this.creatorName,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.photoCount = 0,
    this.tags = const [],
  });

  GalleryAlbum copyWith({
    String? id,
    String? name,
    String? description,
    String? schoolId,
    String? classCode,
    String? coverImageUrl,
    String? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? photoCount,
    List<String>? tags,
  }) {
    return GalleryAlbum(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schoolId: schoolId ?? this.schoolId,
      classCode: classCode ?? this.classCode,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      photoCount: photoCount ?? this.photoCount,
      tags: tags ?? this.tags,
    );
  }

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) =>
      _$GalleryAlbumFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAlbumToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryAlbum &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.schoolId == schoolId &&
        other.classCode == classCode &&
        other.coverImageUrl == coverImageUrl &&
        other.createdBy == createdBy &&
        other.creatorName == creatorName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive &&
        other.photoCount == photoCount &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      schoolId,
      classCode,
      coverImageUrl,
      createdBy,
      creatorName,
      createdAt,
      updatedAt,
      isActive,
      photoCount,
      tags,
    );
  }

  @override
  String toString() {
    return 'GalleryAlbum(id: $id, name: $name, classCode: $classCode, photoCount: $photoCount)';
  }
}

enum GalleryPhotoStatus {
  @JsonValue('processing')
  processing,
  @JsonValue('ready')
  ready,
  @JsonValue('failed')
  failed,
}

@JsonSerializable()
class GalleryUploadRequest {
  final String title;
  final String description;
  final String albumId;
  final String classCode;
  final List<String> tags;

  GalleryUploadRequest({
    required this.title,
    required this.description,
    required this.albumId,
    required this.classCode,
    this.tags = const [],
  });

  factory GalleryUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$GalleryUploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryUploadRequestToJson(this);
}

@JsonSerializable()
class GalleryAlbumRequest {
  final String name;
  final String description;
  final String classCode;
  final List<String> tags;

  GalleryAlbumRequest({
    required this.name,
    required this.description,
    required this.classCode,
    this.tags = const [],
  });

  factory GalleryAlbumRequest.fromJson(Map<String, dynamic> json) =>
      _$GalleryAlbumRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAlbumRequestToJson(this);
}

@JsonSerializable()
class GalleryLike {
  final String id;
  final String photoId;
  final String studentId;
  final String studentName;
  final String schoolId;
  final DateTime createdAt;

  GalleryLike({
    required this.id,
    required this.photoId,
    required this.studentId,
    required this.studentName,
    required this.schoolId,
    required this.createdAt,
  });

  GalleryLike copyWith({
    String? id,
    String? photoId,
    String? studentId,
    String? studentName,
    String? schoolId,
    DateTime? createdAt,
  }) {
    return GalleryLike(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory GalleryLike.fromJson(Map<String, dynamic> json) =>
      _$GalleryLikeFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryLikeToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryLike &&
        other.id == id &&
        other.photoId == photoId &&
        other.studentId == studentId &&
        other.studentName == studentName &&
        other.schoolId == schoolId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      photoId,
      studentId,
      studentName,
      schoolId,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'GalleryLike(id: $id, photoId: $photoId, studentId: $studentId)';
  }
}

@JsonSerializable()
class GalleryComment {
  final String id;
  final String photoId;
  final String studentId;
  final String studentName;
  final String schoolId;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  GalleryComment({
    required this.id,
    required this.photoId,
    required this.studentId,
    required this.studentName,
    required this.schoolId,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  GalleryComment copyWith({
    String? id,
    String? photoId,
    String? studentId,
    String? studentName,
    String? schoolId,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return GalleryComment(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      schoolId: schoolId ?? this.schoolId,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory GalleryComment.fromJson(Map<String, dynamic> json) =>
      _$GalleryCommentFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryCommentToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryComment &&
        other.id == id &&
        other.photoId == photoId &&
        other.studentId == studentId &&
        other.studentName == studentName &&
        other.schoolId == schoolId &&
        other.comment == comment &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      photoId,
      studentId,
      studentName,
      schoolId,
      comment,
      createdAt,
      updatedAt,
      isActive,
    );
  }

  @override
  String toString() {
    return 'GalleryComment(id: $id, photoId: $photoId, studentId: $studentId, comment: $comment)';
  }
}

@JsonSerializable()
class GalleryPhotoWithStats {
  final GalleryPhoto photo;
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;
  final List<GalleryLike> likes;
  final List<GalleryComment> comments;

  GalleryPhotoWithStats({
    required this.photo,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByCurrentUser,
    this.likes = const [],
    this.comments = const [],
  });

  GalleryPhotoWithStats copyWith({
    GalleryPhoto? photo,
    int? likeCount,
    int? commentCount,
    bool? isLikedByCurrentUser,
    List<GalleryLike>? likes,
    List<GalleryComment>? comments,
  }) {
    return GalleryPhotoWithStats(
      photo: photo ?? this.photo,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }

  factory GalleryPhotoWithStats.fromJson(Map<String, dynamic> json) =>
      _$GalleryPhotoWithStatsFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryPhotoWithStatsToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GalleryPhotoWithStats &&
        other.photo == photo &&
        other.likeCount == likeCount &&
        other.commentCount == commentCount &&
        other.isLikedByCurrentUser == isLikedByCurrentUser &&
        listEquals(other.likes, likes) &&
        listEquals(other.comments, comments);
  }

  @override
  int get hashCode {
    return Object.hash(
      photo,
      likeCount,
      commentCount,
      isLikedByCurrentUser,
      likes,
      comments,
    );
  }

  @override
  String toString() {
    return 'GalleryPhotoWithStats(photoId: ${photo.id}, likes: $likeCount, comments: $commentCount)';
  }
}