// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Photo _$PhotoFromJson(Map<String, dynamic> json) => Photo(
  id: (json['id'] as num).toInt(),
  albumId: (json['album_id'] as num).toInt(),
  filename: json['filename'] as String,
  originalName: json['original_name'] as String,
  path: json['path'] as String,
  thumbnailPath: json['thumbnail_path'] as String?,
  watermarkedPath: json['watermarked_path'] as String?,
  size: (json['size'] as num).toInt(),
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  uploadedBy: (json['uploaded_by'] as num).toInt(),
  caption: json['caption'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  likes:
      (json['likes'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
  views: (json['views'] as num).toInt(),
  uploadedAt: DateTime.parse(json['uploaded_at'] as String),
  uploaderName: json['uploader_name'] as String?,
  likesCount: (json['likes_count'] as num?)?.toInt(),
  isLiked: json['is_liked'] as bool?,
);

Map<String, dynamic> _$PhotoToJson(Photo instance) => <String, dynamic>{
  'id': instance.id,
  'album_id': instance.albumId,
  'filename': instance.filename,
  'original_name': instance.originalName,
  'path': instance.path,
  'thumbnail_path': instance.thumbnailPath,
  'watermarked_path': instance.watermarkedPath,
  'size': instance.size,
  'width': instance.width,
  'height': instance.height,
  'uploaded_by': instance.uploadedBy,
  'caption': instance.caption,
  'tags': instance.tags,
  'likes': instance.likes,
  'views': instance.views,
  'uploaded_at': instance.uploadedAt.toIso8601String(),
  'uploader_name': instance.uploaderName,
  'likes_count': instance.likesCount,
  'is_liked': instance.isLiked,
};

UploadPhotoRequest _$UploadPhotoRequestFromJson(Map<String, dynamic> json) =>
    UploadPhotoRequest(
      captions:
          (json['captions'] as List<dynamic>).map((e) => e as String).toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$UploadPhotoRequestToJson(UploadPhotoRequest instance) =>
    <String, dynamic>{'captions': instance.captions, 'tags': instance.tags};

PhotoUploadResponse _$PhotoUploadResponseFromJson(Map<String, dynamic> json) =>
    PhotoUploadResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$PhotoUploadResponseToJson(
  PhotoUploadResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'photos': instance.photos,
};

PhotoLikeRequest _$PhotoLikeRequestFromJson(Map<String, dynamic> json) =>
    PhotoLikeRequest(photoId: (json['photo_id'] as num).toInt());

Map<String, dynamic> _$PhotoLikeRequestToJson(PhotoLikeRequest instance) =>
    <String, dynamic>{'photo_id': instance.photoId};
