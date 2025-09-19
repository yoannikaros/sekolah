// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Album _$AlbumFromJson(Map<String, dynamic> json) => Album(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  coverPhoto: json['cover_photo'] as String?,
  classId: (json['class_id'] as num?)?.toInt(),
  createdBy: (json['created_by'] as num).toInt(),
  isPublic: json['is_public'] as bool,
  allowDownload: json['allow_download'] as bool,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  photoCount: (json['photo_count'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  creator:
      json['creator'] == null
          ? null
          : User.fromJson(json['creator'] as Map<String, dynamic>),
  photos:
      (json['photos'] as List<dynamic>?)
          ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$AlbumToJson(Album instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'cover_photo': instance.coverPhoto,
  'class_id': instance.classId,
  'created_by': instance.createdBy,
  'is_public': instance.isPublic,
  'allow_download': instance.allowDownload,
  'tags': instance.tags,
  'photo_count': instance.photoCount,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'creator': instance.creator,
  'photos': instance.photos,
};

CreateAlbumRequest _$CreateAlbumRequestFromJson(Map<String, dynamic> json) =>
    CreateAlbumRequest(
      title: json['title'] as String,
      description: json['description'] as String?,
      classId: (json['class_id'] as num?)?.toInt(),
      isPublic: json['is_public'] as bool,
      allowDownload: json['allow_download'] as bool,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$CreateAlbumRequestToJson(CreateAlbumRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'class_id': instance.classId,
      'is_public': instance.isPublic,
      'allow_download': instance.allowDownload,
      'tags': instance.tags,
    };

UpdateAlbumRequest _$UpdateAlbumRequestFromJson(Map<String, dynamic> json) =>
    UpdateAlbumRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      classId: (json['class_id'] as num?)?.toInt(),
      isPublic: json['is_public'] as bool?,
      allowDownload: json['allow_download'] as bool?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$UpdateAlbumRequestToJson(UpdateAlbumRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'class_id': instance.classId,
      'is_public': instance.isPublic,
      'allow_download': instance.allowDownload,
      'tags': instance.tags,
    };
