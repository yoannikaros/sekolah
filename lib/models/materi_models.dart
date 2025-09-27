import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'materi_models.g.dart';

// Custom converter for DateTime that handles both String and Timestamp
class DateTimeConverter implements JsonConverter<DateTime, dynamic> {
  const DateTimeConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('Cannot convert null to DateTime');
    }
    if (json is String) {
      return DateTime.parse(json);
    } else if (json is Timestamp) {
      return json.toDate();
    } else if (json is DateTime) {
      return json;
    } else {
      throw ArgumentError('Cannot convert $json to DateTime');
    }
  }

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

// Custom converter for nullable DateTime that handles both String and Timestamp
class NullableDateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) {
      return null;
    }
    if (json is String) {
      return DateTime.parse(json);
    } else if (json is Timestamp) {
      return json.toDate();
    } else if (json is DateTime) {
      return json;
    } else {
      throw ArgumentError('Cannot convert $json to DateTime');
    }
  }

  @override
  dynamic toJson(DateTime? object) => object?.toIso8601String();
}

@JsonSerializable()
class Materi {
  final String id;
  final String judul; // BAB 1, BAB 2, etc.
  final String teacherId; // Relasi dengan guru
  final String subjectId; // Relasi mata pelajaran
  final String schoolId; // Relasi dengan sekolah
  final List<String> classCodeIds; // Relasi kode kelas (multiple)
  final String? description; // Deskripsi materi (opsional)
  @DateTimeConverter()
  final DateTime createdAt;
  @DateTimeConverter()
  final DateTime updatedAt;
  final bool isActive;
  final int? sortOrder; // Urutan materi
  final String? thumbnailUrl; // Gambar thumbnail (opsional)
  final String? imageUrl; // Gambar pendukung (opsional)
  final List<String>? attachments; // File attachment (opsional)

  Materi({
    required this.id,
    required this.judul,
    required this.teacherId,
    required this.subjectId,
    required this.schoolId,
    this.classCodeIds = const [],
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.sortOrder,
    this.thumbnailUrl,
    this.imageUrl,
    this.attachments,
  });

  Materi copyWith({
    String? id,
    String? judul,
    String? teacherId,
    String? subjectId,
    String? schoolId,
    List<String>? classCodeIds,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? sortOrder,
    String? thumbnailUrl,
    String? imageUrl,
    List<String>? attachments,
  }) {
    return Materi(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      schoolId: schoolId ?? this.schoolId,
      classCodeIds: classCodeIds ?? this.classCodeIds,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      attachments: attachments ?? this.attachments,
    );
  }

  factory Materi.fromJson(Map<String, dynamic> json) {
    try {
      return _$MateriFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Materi from JSON: $e');
        print('JSON data: $json');
      }
      // Return a default materi object if parsing fails
      return Materi(
        id: json['id'] as String? ?? '',
        judul: json['judul'] as String? ?? 'Unknown Materi',
        teacherId: json['teacherId'] as String? ?? '',
        subjectId: json['subjectId'] as String? ?? '',
        schoolId: json['schoolId'] as String? ?? '',
        classCodeIds: (json['classCodeIds'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    }
  }

  Map<String, dynamic> toJson() => _$MateriToJson(this);
}

@JsonSerializable()
class DetailMateri {
  final String id;
  final String materiId; // ID materi parent
  final String schoolId; // Relasi dengan sekolah
  final String classCodeId; // Relasi dengan kode kelas spesifik
  final String judul; // Judul detail materi
  final String paragrafMateri; // Konten paragraf materi
  final String? embedYoutube; // URL embed YouTube (opsional)
  @DateTimeConverter()
  final DateTime createdAt;
  @DateTimeConverter()
  final DateTime updatedAt;
  final bool isActive;
  final int? sortOrder; // Urutan dalam materi
  final List<String>? attachments; // File attachment (opsional)
  final String? imageUrl; // Gambar pendukung (opsional)

  DetailMateri({
    required this.id,
    required this.materiId,
    required this.schoolId,
    required this.classCodeId,
    required this.judul,
    required this.paragrafMateri,
    this.embedYoutube,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.sortOrder,
    this.attachments,
    this.imageUrl,
  });

  DetailMateri copyWith({
    String? id,
    String? materiId,
    String? schoolId,
    String? classCodeId,
    String? judul,
    String? paragrafMateri,
    String? embedYoutube,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? sortOrder,
    List<String>? attachments,
    String? imageUrl,
  }) {
    return DetailMateri(
      id: id ?? this.id,
      materiId: materiId ?? this.materiId,
      schoolId: schoolId ?? this.schoolId,
      classCodeId: classCodeId ?? this.classCodeId,
      judul: judul ?? this.judul,
      paragrafMateri: paragrafMateri ?? this.paragrafMateri,
      embedYoutube: embedYoutube ?? this.embedYoutube,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      attachments: attachments ?? this.attachments,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory DetailMateri.fromJson(Map<String, dynamic> json) {
    try {
      return _$DetailMateriFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing DetailMateri from JSON: $e');
        print('JSON data: $json');
      }
      // Return a default detail materi object if parsing fails
      return DetailMateri(
        id: json['id'] as String? ?? '',
        materiId: json['materiId'] as String? ?? '',
        schoolId: json['schoolId'] as String? ?? '',
        classCodeId: json['classCodeId'] as String? ?? '',
        judul: json['judul'] as String? ?? 'Unknown Detail',
        paragrafMateri: json['paragrafMateri'] as String? ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    }
  }

  Map<String, dynamic> toJson() => _$DetailMateriToJson(this);
}

// Model untuk menampilkan materi dengan informasi relasi
@JsonSerializable()
class MateriWithDetails {
  final Materi materi;
  final String teacherName;
  final String subjectName;
  final List<String> classCodeNames;
  final List<DetailMateri> details;

  MateriWithDetails({
    required this.materi,
    required this.teacherName,
    required this.subjectName,
    required this.classCodeNames,
    required this.details,
  });

  factory MateriWithDetails.fromJson(Map<String, dynamic> json) => 
      _$MateriWithDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$MateriWithDetailsToJson(this);
}