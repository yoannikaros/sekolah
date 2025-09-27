import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'task_models.g.dart';

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
class Task {
  final String id; // ID Tugas (unik)
  final String teacherId; // Terhubung ke Guru (siapa yang membuat)
  final String subjectId; // Terhubung ke Mata Pelajaran (tugas mapel apa)
  final String title; // Judul Tugas (misalnya: BAB 1, BAB 2)
  final String description; // Deskripsi Tugas
  @DateTimeConverter()
  final DateTime createdAt; // Tanggal Dibuat (otomatis saat dibuat)
  @DateTimeConverter()
  final DateTime openDate; // Tanggal Dibuka (kapan mulai bisa dikerjakan)
  @DateTimeConverter()
  final DateTime dueDate; // Tanggal Selesai (deadline)
  final String taskLink; // Link Soal (misalnya Google Docs atau PDF)
  final bool isActive;
  @NullableDateTimeConverter()
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.openDate,
    required this.dueDate,
    required this.taskLink,
    this.isActive = true,
    this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? teacherId,
    String? subjectId,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? openDate,
    DateTime? dueDate,
    String? taskLink,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      openDate: openDate ?? this.openDate,
      dueDate: dueDate ?? this.dueDate,
      taskLink: taskLink ?? this.taskLink,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      return _$TaskFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Task from JSON: $e');
        print('JSON data: $json');
      }
      // Return a default task object if parsing fails
      return Task(
        id: json['id'] as String? ?? '',
        teacherId: json['teacherId'] as String? ?? '',
        subjectId: json['subjectId'] as String? ?? '',
        title: json['title'] as String? ?? 'Unknown Task',
        description: json['description'] as String? ?? '',
        createdAt: DateTime.now(),
        openDate: DateTime.now(),
        dueDate: DateTime.now().add(Duration(days: 7)),
        taskLink: json['taskLink'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );
    }
  }

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  // Helper methods
  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(openDate) && now.isBefore(dueDate);
  }

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate);
  }

  bool get isUpcoming {
    return DateTime.now().isBefore(openDate);
  }
}

@JsonSerializable()
class TaskClass {
  final String id; // ID Tugas-Kelas (unik)
  final String taskId; // ID Tugas (tugas mana)
  final String classId; // ID Kelas (kelas mana)
  @DateTimeConverter()
  final DateTime createdAt;
  final bool isActive;

  TaskClass({
    required this.id,
    required this.taskId,
    required this.classId,
    required this.createdAt,
    this.isActive = true,
  });

  TaskClass copyWith({
    String? id,
    String? taskId,
    String? classId,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return TaskClass(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      classId: classId ?? this.classId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory TaskClass.fromJson(Map<String, dynamic> json) {
    try {
      return _$TaskClassFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing TaskClass from JSON: $e');
        print('JSON data: $json');
      }
      // Return a default task class object if parsing fails
      return TaskClass(
        id: json['id'] as String? ?? '',
        taskId: json['taskId'] as String? ?? '',
        classId: json['classId'] as String? ?? '',
        createdAt: DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
      );
    }
  }

  Map<String, dynamic> toJson() => _$TaskClassToJson(this);
}

@JsonSerializable()
class TaskSubmission {
  final String id; // ID Pengumpulan (unik)
  final String taskId; // Terhubung ke Tugas (tugas mana yang dikumpulkan)
  final String studentId; // Terhubung ke Siswa (siswa mana yang mengumpulkan)
  final String submissionLink; // Link Pengumpulan (misalnya link Google Drive, GitHub, dsb)
  @DateTimeConverter()
  final DateTime submissionDate; // Tanggal Pengumpulan (otomatis saat siswa mengumpulkan)
  final String? notes; // Catatan tambahan dari siswa
  final bool isLate; // Apakah terlambat mengumpulkan
  @NullableDateTimeConverter()
  final DateTime? gradedAt; // Tanggal dinilai
  final double? score; // Nilai yang diberikan
  final String? feedback; // Feedback dari guru
  final bool isActive;

  TaskSubmission({
    required this.id,
    required this.taskId,
    required this.studentId,
    required this.submissionLink,
    required this.submissionDate,
    this.notes,
    this.isLate = false,
    this.gradedAt,
    this.score,
    this.feedback,
    this.isActive = true,
  });

  TaskSubmission copyWith({
    String? id,
    String? taskId,
    String? studentId,
    String? submissionLink,
    DateTime? submissionDate,
    String? notes,
    bool? isLate,
    DateTime? gradedAt,
    double? score,
    String? feedback,
    bool? isActive,
  }) {
    return TaskSubmission(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      studentId: studentId ?? this.studentId,
      submissionLink: submissionLink ?? this.submissionLink,
      submissionDate: submissionDate ?? this.submissionDate,
      notes: notes ?? this.notes,
      isLate: isLate ?? this.isLate,
      gradedAt: gradedAt ?? this.gradedAt,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      isActive: isActive ?? this.isActive,
    );
  }

  factory TaskSubmission.fromJson(Map<String, dynamic> json) {
    try {
      return _$TaskSubmissionFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing TaskSubmission from JSON: $e');
        print('JSON data: $json');
      }
      // Return a default task submission object if parsing fails
      return TaskSubmission(
        id: json['id'] as String? ?? '',
        taskId: json['taskId'] as String? ?? '',
        studentId: json['studentId'] as String? ?? '',
        submissionLink: json['submissionLink'] as String? ?? '',
        submissionDate: DateTime.now(),
        isLate: json['isLate'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
      );
    }
  }

  Map<String, dynamic> toJson() => _$TaskSubmissionToJson(this);

  // Helper methods
  bool get isGraded => score != null;
  
  String get statusText {
    if (isGraded) return 'Sudah Dinilai';
    if (isLate) return 'Terlambat';
    return 'Dikumpulkan';
  }
}

// Model untuk menampilkan data tugas dengan informasi lengkap
@JsonSerializable()
class TaskWithDetails {
  final Task task;
  final String teacherName;
  final String subjectName;
  final List<String> classNames;
  final int submissionCount;
  final int totalStudents;

  TaskWithDetails({
    required this.task,
    required this.teacherName,
    required this.subjectName,
    required this.classNames,
    required this.submissionCount,
    required this.totalStudents,
  });

  factory TaskWithDetails.fromJson(Map<String, dynamic> json) =>
      _$TaskWithDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$TaskWithDetailsToJson(this);

  double get submissionPercentage {
    if (totalStudents == 0) return 0.0;
    return (submissionCount / totalStudents) * 100;
  }
}