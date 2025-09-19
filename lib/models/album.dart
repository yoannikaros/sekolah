import 'package:json_annotation/json_annotation.dart';
import 'photo.dart';
import 'user.dart';

part 'album.g.dart';

@JsonSerializable()
class Album {
  final int id;
  final String title;
  final String? description;
  @JsonKey(name: 'cover_photo')
  final String? coverPhoto;
  @JsonKey(name: 'class_id')
  final int? classId;
  @JsonKey(name: 'created_by')
  final int createdBy;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'allow_download')
  final bool allowDownload;
  final List<String>? tags;
  @JsonKey(name: 'photo_count')
  final int photoCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  final User? creator;
  final List<Photo>? photos;

  Album({
    required this.id,
    required this.title,
    this.description,
    this.coverPhoto,
    this.classId,
    required this.createdBy,
    required this.isPublic,
    required this.allowDownload,
    required this.tags,
    required this.photoCount,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
    this.photos,
  });

  // Helper getter to check if current user can edit this album
  bool get canEdit {
    // This is a simplified implementation - in a real app you'd check
    // if the current user is the creator or has appropriate permissions
    return true; // For now, allow all users to edit
  }

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumToJson(this);

  Album copyWith({
    int? id,
    String? title,
    String? description,
    String? coverPhoto,
    int? classId,
    int? createdBy,
    bool? isPublic,
    bool? allowDownload,
    List<String>? tags,
    int? photoCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? creator,
    List<Photo>? photos,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      classId: classId ?? this.classId,
      createdBy: createdBy ?? this.createdBy,
      isPublic: isPublic ?? this.isPublic,
      allowDownload: allowDownload ?? this.allowDownload,
      tags: tags ?? this.tags,
      photoCount: photoCount ?? this.photoCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creator: creator ?? this.creator,
      photos: photos ?? this.photos,
    );
  }
}

@JsonSerializable()
class CreateAlbumRequest {
  final String title;
  final String? description;
  @JsonKey(name: 'class_id')
  final int? classId;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'allow_download')
  final bool allowDownload;
  final List<String> tags;

  CreateAlbumRequest({
    required this.title,
    this.description,
    this.classId,
    required this.isPublic,
    required this.allowDownload,
    required this.tags,
  });

  factory CreateAlbumRequest.fromJson(Map<String, dynamic> json) => _$CreateAlbumRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAlbumRequestToJson(this);
}

@JsonSerializable()
class UpdateAlbumRequest {
  final String? title;
  final String? description;
  @JsonKey(name: 'class_id')
  final int? classId;
  @JsonKey(name: 'is_public')
  final bool? isPublic;
  @JsonKey(name: 'allow_download')
  final bool? allowDownload;
  final List<String>? tags;

  UpdateAlbumRequest({
    this.title,
    this.description,
    this.classId,
    this.isPublic,
    this.allowDownload,
    this.tags,
  });

  factory UpdateAlbumRequest.fromJson(Map<String, dynamic> json) => _$UpdateAlbumRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateAlbumRequestToJson(this);
}