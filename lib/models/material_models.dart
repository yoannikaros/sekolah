import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part 'material_models.g.dart';

@JsonSerializable()
class Material {
  final String id;
  final String subjectId; // Relasi ke mata pelajaran
  final String classCodeId; // Relasi ke kode kelas
  final String teacherId; // Relasi ke guru
  final String title; // Judul materi
  final String content; // Isi materi (paragraf)
  final String? youtubeEmbedUrl; // Embed YouTube (opsional)
  final List<MaterialComment> comments; // Komentar dari guru atau murid
  final String createdBy; // ID admin/guru yang membuat
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isPublished; // Apakah materi sudah dipublish untuk siswa
  final DateTime? publishedAt;
  final int? sortOrder; // Urutan materi
  final List<String> tags; // Tag untuk kategorisasi
  final String? thumbnailUrl; // Thumbnail untuk materi

  Material({
    required this.id,
    required this.subjectId,
    required this.classCodeId,
    required this.teacherId,
    required this.title,
    required this.content,
    this.youtubeEmbedUrl,
    this.comments = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isPublished = false,
    this.publishedAt,
    this.sortOrder,
    this.tags = const [],
    this.thumbnailUrl,
  });

  Material copyWith({
    String? id,
    String? subjectId,
    String? classCodeId,
    String? teacherId,
    String? title,
    String? content,
    String? youtubeEmbedUrl,
    List<MaterialComment>? comments,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPublished,
    DateTime? publishedAt,
    int? sortOrder,
    List<String>? tags,
    String? thumbnailUrl,
  }) {
    return Material(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      classCodeId: classCodeId ?? this.classCodeId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      content: content ?? this.content,
      youtubeEmbedUrl: youtubeEmbedUrl ?? this.youtubeEmbedUrl,
      comments: comments ?? this.comments,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  factory Material.fromJson(Map<String, dynamic> json) {
    try {
      return _$MaterialFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Material from JSON with generated method: $e');
        print('JSON data: $json');
        print('Attempting manual parsing...');
      }
      
      // Manual parsing as fallback
      try {
        return Material(
          id: json['id'] as String? ?? '',
          subjectId: json['subjectId'] as String? ?? '',
          classCodeId: json['classCodeId'] as String? ?? '',
          teacherId: json['teacherId'] as String? ?? '',
          title: json['title'] as String? ?? 'Untitled Material',
          content: json['content'] as String? ?? '',
          youtubeEmbedUrl: json['youtubeEmbedUrl'] as String?,
          comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => MaterialComment.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
          createdBy: json['createdBy'] as String? ?? '',
          createdAt: json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
          updatedAt: json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
          isActive: json['isActive'] as bool? ?? true,
          isPublished: json['isPublished'] as bool? ?? false,
          publishedAt: json['publishedAt'] != null 
              ? DateTime.parse(json['publishedAt'] as String)
              : null,
          sortOrder: json['sortOrder'] as int?,
          tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
          thumbnailUrl: json['thumbnailUrl'] as String?,
        );
      } catch (e2) {
        if (kDebugMode) {
          print('Manual parsing also failed: $e2');
        }
        // Return minimal valid material object
        return Material(
          id: json['id'] as String? ?? '',
          subjectId: json['subjectId'] as String? ?? '',
          classCodeId: json['classCodeId'] as String? ?? '',
          teacherId: json['teacherId'] as String? ?? '',
          title: json['title'] as String? ?? 'Untitled Material',
          content: json['content'] as String? ?? '',
          createdBy: json['createdBy'] as String? ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );
      }
    }
  }

  Map<String, dynamic> toJson() => _$MaterialToJson(this);
}

@JsonSerializable()
class MaterialComment {
  final String id;
  final String materialId; // ID materi yang dikomentari
  final String authorId; // ID pengguna yang berkomentar (guru atau murid)
  final String authorName; // Nama pengguna yang berkomentar
  final String authorType; // 'teacher' atau 'student'
  final String comment; // Isi komentar
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? parentCommentId; // Untuk reply komentar
  final List<String> attachmentUrls; // URL attachment jika ada

  MaterialComment({
    required this.id,
    required this.materialId,
    required this.authorId,
    required this.authorName,
    required this.authorType,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.parentCommentId,
    this.attachmentUrls = const [],
  });

  MaterialComment copyWith({
    String? id,
    String? materialId,
    String? authorId,
    String? authorName,
    String? authorType,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? parentCommentId,
    List<String>? attachmentUrls,
  }) {
    return MaterialComment(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorType: authorType ?? this.authorType,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }

  factory MaterialComment.fromJson(Map<String, dynamic> json) {
    try {
      return _$MaterialCommentFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing MaterialComment from JSON: $e');
      }
      // Manual parsing as fallback
      return MaterialComment(
        id: json['id'] as String? ?? '',
        materialId: json['materialId'] as String? ?? '',
        authorId: json['authorId'] as String? ?? '',
        authorName: json['authorName'] as String? ?? 'Unknown User',
        authorType: json['authorType'] as String? ?? 'student',
        comment: json['comment'] as String? ?? '',
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
        parentCommentId: json['parentCommentId'] as String?,
        attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    }
  }

  Map<String, dynamic> toJson() => _$MaterialCommentToJson(this);
}

// Enum untuk tipe author komentar
enum MaterialCommentAuthorType {
  teacher,
  student,
  admin,
}

// Model untuk filter materi
@JsonSerializable()
class MaterialFilter {
  final String? subjectId;
  final String? classCodeId;
  final String? teacherId;
  final bool? isPublished;
  final bool? isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? tags;
  final String? searchQuery;

  MaterialFilter({
    this.subjectId,
    this.classCodeId,
    this.teacherId,
    this.isPublished,
    this.isActive,
    this.startDate,
    this.endDate,
    this.tags,
    this.searchQuery,
  });

  MaterialFilter copyWith({
    String? subjectId,
    String? classCodeId,
    String? teacherId,
    bool? isPublished,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    String? searchQuery,
  }) {
    return MaterialFilter(
      subjectId: subjectId ?? this.subjectId,
      classCodeId: classCodeId ?? this.classCodeId,
      teacherId: teacherId ?? this.teacherId,
      isPublished: isPublished ?? this.isPublished,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  factory MaterialFilter.fromJson(Map<String, dynamic> json) =>
      _$MaterialFilterFromJson(json);

  Map<String, dynamic> toJson() => _$MaterialFilterToJson(this);
}