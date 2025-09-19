import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

@JsonSerializable()
class Photo {
  final int id;
  @JsonKey(name: 'album_id')
  final int albumId;
  final String filename;
  @JsonKey(name: 'original_name')
  final String originalName;
  final String path;
  @JsonKey(name: 'thumbnail_path')
  final String? thumbnailPath;
  @JsonKey(name: 'watermarked_path')
  final String? watermarkedPath;
  final int size;
  final int? width;
  final int? height;
  @JsonKey(name: 'uploaded_by')
  final int uploadedBy;
  final String? caption;
  final List<String>? tags;
  final List<int>? likes;
  final int views;
  @JsonKey(name: 'uploaded_at')
  final DateTime uploadedAt;
  // From JOIN query in server.js
  @JsonKey(name: 'uploader_name')
  final String? uploaderName;
  // Computed fields (not from API)
  @JsonKey(name: 'likes_count')
  final int? likesCount;
  @JsonKey(name: 'is_liked')
  final bool? isLiked;

  Photo({
    required this.id,
    required this.albumId,
    required this.filename,
    required this.originalName,
    required this.path,
    this.thumbnailPath,
    this.watermarkedPath,
    required this.size,
    this.width,
    this.height,
    required this.uploadedBy,
    this.caption,
    this.tags,
    this.likes,
    required this.views,
    required this.uploadedAt,
    this.uploaderName,
    this.likesCount,
    this.isLiked,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoToJson(this);

  Photo copyWith({
    int? id,
    int? albumId,
    String? filename,
    String? originalName,
    String? path,
    String? thumbnailPath,
    String? watermarkedPath,
    int? size,
    int? width,
    int? height,
    int? uploadedBy,
    String? caption,
    List<String>? tags,
    List<int>? likes,
    int? views,
    DateTime? uploadedAt,
    String? uploaderName,
    int? likesCount,
    bool? isLiked,
  }) {
    return Photo(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      filename: filename ?? this.filename,
      originalName: originalName ?? this.originalName,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      watermarkedPath: watermarkedPath ?? this.watermarkedPath,
      size: size ?? this.size,
      width: width ?? this.width,
      height: height ?? this.height,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploaderName: uploaderName ?? this.uploaderName,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  // Helper methods
  String get imageUrl {
    if (path.startsWith('http')) {
      return path;
    }
    return 'http://localhost:3000/uploads/$path';
  }

  String get thumbnailUrl {
    if (thumbnailPath != null) {
      if (thumbnailPath!.startsWith('http')) {
        return thumbnailPath!;
      }
      return 'http://localhost:3000/uploads/$thumbnailPath';
    }
    return imageUrl; // Fallback to main image
  }

  String get watermarkedUrl {
    if (watermarkedPath != null) {
      if (watermarkedPath!.startsWith('http')) {
        return watermarkedPath!;
      }
      return 'http://localhost:3000/uploads/$watermarkedPath';
    }
    return imageUrl; // Fallback to main image
  }

  int get actualLikesCount {
    return likesCount ?? (likes?.length ?? 0);
  }

  bool get isLikedByUser {
    return isLiked ?? false;
  }

  String get fullImageUrl => 'http://localhost:3000$path';
}

@JsonSerializable()
class UploadPhotoRequest {
  final List<String> captions;
  final List<String>? tags;

  UploadPhotoRequest({
    required this.captions,
    this.tags,
  });

  factory UploadPhotoRequest.fromJson(Map<String, dynamic> json) => _$UploadPhotoRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UploadPhotoRequestToJson(this);
}

@JsonSerializable()
class PhotoUploadResponse {
  final bool success;
  final String message;
  final List<Photo>? photos;

  PhotoUploadResponse({
    required this.success,
    required this.message,
    this.photos,
  });

  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json) => _$PhotoUploadResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoUploadResponseToJson(this);
}

@JsonSerializable()
class PhotoLikeRequest {
  @JsonKey(name: 'photo_id')
  final int photoId;

  PhotoLikeRequest({
    required this.photoId,
  });

  factory PhotoLikeRequest.fromJson(Map<String, dynamic> json) => _$PhotoLikeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoLikeRequestToJson(this);
}