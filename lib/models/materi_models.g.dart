// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'materi_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Materi _$MateriFromJson(Map<String, dynamic> json) => Materi(
  id: json['id'] as String,
  judul: json['judul'] as String,
  teacherId: json['teacherId'] as String,
  subjectId: json['subjectId'] as String,
  schoolId: json['schoolId'] as String,
  classCodeIds:
      (json['classCodeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  description: json['description'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
  isActive: json['isActive'] as bool? ?? true,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  thumbnailUrl: json['thumbnailUrl'] as String?,
  imageUrl: json['imageUrl'] as String?,
  attachments:
      (json['attachments'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$MateriToJson(Materi instance) => <String, dynamic>{
  'id': instance.id,
  'judul': instance.judul,
  'teacherId': instance.teacherId,
  'subjectId': instance.subjectId,
  'schoolId': instance.schoolId,
  'classCodeIds': instance.classCodeIds,
  'description': instance.description,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
  'isActive': instance.isActive,
  'sortOrder': instance.sortOrder,
  'thumbnailUrl': instance.thumbnailUrl,
  'imageUrl': instance.imageUrl,
  'attachments': instance.attachments,
};

DetailMateri _$DetailMateriFromJson(Map<String, dynamic> json) => DetailMateri(
  id: json['id'] as String,
  materiId: json['materiId'] as String,
  schoolId: json['schoolId'] as String,
  classCodeId: json['classCodeId'] as String,
  judul: json['judul'] as String,
  paragrafMateri: json['paragrafMateri'] as String,
  embedYoutube: json['embedYoutube'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
  isActive: json['isActive'] as bool? ?? true,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
  attachments:
      (json['attachments'] as List<dynamic>?)?.map((e) => e as String).toList(),
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$DetailMateriToJson(DetailMateri instance) =>
    <String, dynamic>{
      'id': instance.id,
      'materiId': instance.materiId,
      'schoolId': instance.schoolId,
      'classCodeId': instance.classCodeId,
      'judul': instance.judul,
      'paragrafMateri': instance.paragrafMateri,
      'embedYoutube': instance.embedYoutube,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
      'isActive': instance.isActive,
      'sortOrder': instance.sortOrder,
      'attachments': instance.attachments,
      'imageUrl': instance.imageUrl,
    };

MateriWithDetails _$MateriWithDetailsFromJson(Map<String, dynamic> json) =>
    MateriWithDetails(
      materi: Materi.fromJson(json['materi'] as Map<String, dynamic>),
      teacherName: json['teacherName'] as String,
      subjectName: json['subjectName'] as String,
      classCodeNames:
          (json['classCodeNames'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      details:
          (json['details'] as List<dynamic>)
              .map((e) => DetailMateri.fromJson(e as Map<String, dynamic>))
              .toList(),
    );

Map<String, dynamic> _$MateriWithDetailsToJson(MateriWithDetails instance) =>
    <String, dynamic>{
      'materi': instance.materi,
      'teacherName': instance.teacherName,
      'subjectName': instance.subjectName,
      'classCodeNames': instance.classCodeNames,
      'details': instance.details,
    };
