// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryPhoto _$GalleryPhotoFromJson(Map<String, dynamic> json) => GalleryPhoto(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  originalImageUrl: json['originalImageUrl'] as String,
  watermarkedImageUrl: json['watermarkedImageUrl'] as String,
  thumbnailUrl: json['thumbnailUrl'] as String,
  schoolId: json['schoolId'] as String,
  classCode: json['classCode'] as String,
  albumId: json['albumId'] as String,
  uploadedBy: json['uploadedBy'] as String,
  uploaderName: json['uploaderName'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  metadata: json['metadata'] as Map<String, dynamic>?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$GalleryPhotoToJson(GalleryPhoto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'originalImageUrl': instance.originalImageUrl,
      'watermarkedImageUrl': instance.watermarkedImageUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'schoolId': instance.schoolId,
      'classCode': instance.classCode,
      'albumId': instance.albumId,
      'uploadedBy': instance.uploadedBy,
      'uploaderName': instance.uploaderName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'metadata': instance.metadata,
      'tags': instance.tags,
    };

GalleryAlbum _$GalleryAlbumFromJson(Map<String, dynamic> json) => GalleryAlbum(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  schoolId: json['schoolId'] as String,
  classCode: json['classCode'] as String,
  coverImageUrl: json['coverImageUrl'] as String,
  createdBy: json['createdBy'] as String,
  creatorName: json['creatorName'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$GalleryAlbumToJson(GalleryAlbum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'schoolId': instance.schoolId,
      'classCode': instance.classCode,
      'coverImageUrl': instance.coverImageUrl,
      'createdBy': instance.createdBy,
      'creatorName': instance.creatorName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
      'photoCount': instance.photoCount,
      'tags': instance.tags,
    };

GalleryUploadRequest _$GalleryUploadRequestFromJson(
  Map<String, dynamic> json,
) => GalleryUploadRequest(
  title: json['title'] as String,
  description: json['description'] as String,
  albumId: json['albumId'] as String,
  classCode: json['classCode'] as String,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$GalleryUploadRequestToJson(
  GalleryUploadRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'albumId': instance.albumId,
  'classCode': instance.classCode,
  'tags': instance.tags,
};

GalleryAlbumRequest _$GalleryAlbumRequestFromJson(Map<String, dynamic> json) =>
    GalleryAlbumRequest(
      name: json['name'] as String,
      description: json['description'] as String,
      classCode: json['classCode'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );

Map<String, dynamic> _$GalleryAlbumRequestToJson(
  GalleryAlbumRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'classCode': instance.classCode,
  'tags': instance.tags,
};
