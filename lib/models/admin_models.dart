import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part 'admin_models.g.dart';

@JsonSerializable()
class School {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final DateTime createdAt;
  final bool isActive;
  final String? logoUrl;

  School({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.website,
    required this.createdAt,
    this.isActive = true,
    this.logoUrl,
  });

  School copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    DateTime? createdAt,
    bool? isActive,
    String? logoUrl,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  factory School.fromJson(Map<String, dynamic> json) {
    try {
      // Use the generated method as fallback for better compatibility
      return _$SchoolFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing School from JSON: $e');
        print('JSON data: $json');
      }
      // Return a default school object if parsing fails
      return School(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown School',
        address: json['address'] as String? ?? '',
        createdAt: DateTime.now(),
        isActive: true,
      );
    }
  }

  Map<String, dynamic> toJson() => _$SchoolToJson(this);
}

@JsonSerializable()
class Subject {
  final String id;
  final String name;
  final String description;
  final String code; // e.g., "MTK", "IPA", "IPS"
  final String schoolId; // Link to school
  final List<String> classCodeIds; // Multiple class codes for this subject
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? iconUrl;
  final int? sortOrder;

  Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
    required this.schoolId,
    this.classCodeIds = const [], // Default to empty list
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.iconUrl,
    this.sortOrder,
  });

  Subject copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    String? schoolId,
    List<String>? classCodeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? iconUrl,
    int? sortOrder,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      schoolId: schoolId ?? this.schoolId,
      classCodeIds: classCodeIds ?? this.classCodeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      iconUrl: iconUrl ?? this.iconUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    try {
      // Use the generated method as fallback for better compatibility
      return _$SubjectFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Subject from JSON: $e');
        print('JSON data: $json');
      }
      // Return a default subject object if parsing fails
      return Subject(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown Subject',
        description: json['description'] as String? ?? '',
        code: json['code'] as String? ?? 'UNK',
        schoolId: json['schoolId'] as String? ?? '',
        classCodeIds: (json['classCodeIds'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    }
  }
  Map<String, dynamic> toJson() => _$SubjectToJson(this);
}

@JsonSerializable()
class Student {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String classCodeId;
  final String schoolId;
  final DateTime enrolledAt;
  final bool isActive;
  final String? profileImageUrl;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.classCodeId,
    required this.schoolId,
    required this.enrolledAt,
    this.isActive = true,
    this.profileImageUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);
  Map<String, dynamic> toJson() => _$StudentToJson(this);
}

@JsonSerializable()
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final AdminRole role;
  final DateTime createdAt;
  final bool isActive;
  final DateTime? lastLogin;
  final List<String> managedClassCodes;
  final String? schoolId; // Link admin to specific school

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.lastLogin,
    this.managedClassCodes = const [],
    this.schoolId,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => _$AdminUserFromJson(json);
  Map<String, dynamic> toJson() => _$AdminUserToJson(this);
}

@JsonSerializable()
class QuestionBank {
  final String id;
  final String title;
  final String description;
  final List<String> questionIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final List<String> tags;

  QuestionBank({
    required this.id,
    required this.title,
    required this.description,
    required this.questionIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.tags = const [],
  });

  factory QuestionBank.fromJson(Map<String, dynamic> json) => _$QuestionBankFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionBankToJson(this);
}

@JsonSerializable()
class Teacher {
  final String id;
  final String name;
  final String email;
  final String schoolId; // Kode sekolah yang otomatis diassign
  final String? phone;
  final String? address;
  final List<String> subjectIds; // Mata pelajaran yang diajar
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? profileImageUrl;
  final String? employeeId; // NIP atau ID karyawan
  final DateTime? lastLogin;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.schoolId,
    this.phone,
    this.address,
    this.subjectIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.profileImageUrl,
    this.employeeId,
    this.lastLogin,
  });

  Teacher copyWith({
    String? id,
    String? name,
    String? email,
    String? schoolId,
    String? phone,
    String? address,
    List<String>? subjectIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profileImageUrl,
    String? employeeId,
    DateTime? lastLogin,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      schoolId: schoolId ?? this.schoolId,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      subjectIds: subjectIds ?? this.subjectIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      employeeId: employeeId ?? this.employeeId,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    try {
      return _$TeacherFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Teacher from JSON with generated method: $e');
        print('JSON data: $json');
        print('Attempting manual parsing...');
      }
      
      // Manual parsing as fallback
      try {
        return Teacher(
          id: json['id'] as String? ?? '',
          name: json['name'] as String? ?? 'Unknown Teacher',
          email: json['email'] as String? ?? '',
          schoolId: json['schoolId'] as String? ?? '',
          phone: json['phone'] as String?,
          address: json['address'] as String?,
          subjectIds: (json['subjectIds'] as List<dynamic>?)?.cast<String>() ?? [],
          createdAt: json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
          updatedAt: json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
          isActive: json['isActive'] as bool? ?? true,
          profileImageUrl: json['profileImageUrl'] as String?,
          employeeId: json['employeeId'] as String?,
          lastLogin: json['lastLogin'] != null 
              ? DateTime.parse(json['lastLogin'] as String)
              : null,
        );
      } catch (e2) {
        if (kDebugMode) {
          print('Manual parsing also failed: $e2');
        }
        // Return minimal valid teacher object
        return Teacher(
          id: json['id'] as String? ?? '',
          name: json['name'] as String? ?? 'Unknown Teacher',
          email: json['email'] as String? ?? '',
          schoolId: json['schoolId'] as String? ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );
      }
    }
  }

  Map<String, dynamic> toJson() => _$TeacherToJson(this);
}

enum AdminRole {
  superAdmin,
  teacher,
  assistant,
}

// New models for hierarchical quiz management
@JsonSerializable()
class AdminQuiz {
  final String id;
  final String title;
  final String description;
  final String subjectId; // Relasi ke mata pelajaran
  final String classCodeId; // Relasi ke class code
  final List<String> chapterIds; // List ID bab-bab dalam quiz ini
  final String createdBy; // Admin/teacher yang membuat
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isPublished; // Apakah quiz sudah dipublish untuk siswa
  final int? timeLimit; // Batas waktu dalam menit (optional)
  final DateTime? publishedAt;
  final DateTime? dueDate; // Tanggal deadline (optional)

  AdminQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.classCodeId,
    this.chapterIds = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isPublished = false,
    this.timeLimit,
    this.publishedAt,
    this.dueDate,
  });

  AdminQuiz copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    String? classCodeId,
    List<String>? chapterIds,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isPublished,
    int? timeLimit,
    DateTime? publishedAt,
    DateTime? dueDate,
  }) {
    return AdminQuiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      classCodeId: classCodeId ?? this.classCodeId,
      chapterIds: chapterIds ?? this.chapterIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      timeLimit: timeLimit ?? this.timeLimit,
      publishedAt: publishedAt ?? this.publishedAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  factory AdminQuiz.fromJson(Map<String, dynamic> json) => _$AdminQuizFromJson(json);
  Map<String, dynamic> toJson() => _$AdminQuizToJson(this);
}

@JsonSerializable()
class QuizChapter {
  final String id;
  final String title;
  final String description;
  final String quizId; // Parent quiz ID
  final List<String> questionIds; // List ID soal-soal dalam bab ini
  final int orderIndex; // Urutan bab dalam quiz
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  QuizChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.quizId,
    this.questionIds = const [],
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  QuizChapter copyWith({
    String? id,
    String? title,
    String? description,
    String? quizId,
    List<String>? questionIds,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return QuizChapter(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      quizId: quizId ?? this.quizId,
      questionIds: questionIds ?? this.questionIds,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory QuizChapter.fromJson(Map<String, dynamic> json) => _$QuizChapterFromJson(json);
  Map<String, dynamic> toJson() => _$QuizChapterToJson(this);
}

@JsonSerializable()
class AdminQuestion {
  final String id;
  final String questionText;
  final AdminQuestionType type; // Multiple choice atau essay
  final String chapterId; // Parent chapter ID
  final List<String> options; // Untuk multiple choice (kosong jika essay)
  final int? correctAnswerIndex; // Index jawaban benar untuk multiple choice
  final String? correctAnswerText; // Jawaban benar untuk essay (optional)
  final String? explanation; // Penjelasan jawaban
  final int points; // Poin untuk soal ini
  final int orderIndex; // Urutan soal dalam bab
  final String? imageUrl; // Gambar soal (optional)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata; // Data tambahan (difficulty level, tags, etc.)

  AdminQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.chapterId,
    this.options = const [],
    this.correctAnswerIndex,
    this.correctAnswerText,
    this.explanation,
    this.points = 10,
    required this.orderIndex,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.metadata,
  });

  AdminQuestion copyWith({
    String? id,
    String? questionText,
    AdminQuestionType? type,
    String? chapterId,
    List<String>? options,
    int? correctAnswerIndex,
    String? correctAnswerText,
    String? explanation,
    int? points,
    int? orderIndex,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return AdminQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      chapterId: chapterId ?? this.chapterId,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      correctAnswerText: correctAnswerText ?? this.correctAnswerText,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
      orderIndex: orderIndex ?? this.orderIndex,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  factory AdminQuestion.fromJson(Map<String, dynamic> json) => _$AdminQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$AdminQuestionToJson(this);
}

enum AdminQuestionType {
  multipleChoice, // ABC
  essay, // Essay
}

// Model untuk menyimpan jawaban siswa (untuk tracking dan grading)
@JsonSerializable()
class StudentQuizAttempt {
  final String id;
  final String studentId;
  final String quizId;
  final Map<String, StudentAnswer> answers; // questionId -> answer
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? totalScore;
  final bool isCompleted;
  final int timeSpent; // dalam detik

  StudentQuizAttempt({
    required this.id,
    required this.studentId,
    required this.quizId,
    this.answers = const {},
    required this.startedAt,
    this.completedAt,
    this.totalScore,
    this.isCompleted = false,
    this.timeSpent = 0,
  });

  factory StudentQuizAttempt.fromJson(Map<String, dynamic> json) => _$StudentQuizAttemptFromJson(json);
  Map<String, dynamic> toJson() => _$StudentQuizAttemptToJson(this);
}

@JsonSerializable()
class StudentAnswer {
  final String questionId;
  final AdminQuestionType questionType;
  final int? selectedOptionIndex; // Untuk multiple choice
  final String? essayAnswer; // Untuk essay
  final DateTime answeredAt;
  final int? score; // Skor yang diberikan (untuk essay, bisa di-grade manual)
  final bool? isCorrect; // Untuk multiple choice

  StudentAnswer({
    required this.questionId,
    required this.questionType,
    this.selectedOptionIndex,
    this.essayAnswer,
    required this.answeredAt,
    this.score,
    this.isCorrect,
  });

  factory StudentAnswer.fromJson(Map<String, dynamic> json) => _$StudentAnswerFromJson(json);
  Map<String, dynamic> toJson() => _$StudentAnswerToJson(this);
}

// Model untuk manajemen tugas admin
@JsonSerializable()
class AdminTask {
  final String id;
  final DateTime tanggalDibuat;
  final String kodeKelas;
  final String mataPelajaran;
  final String judul;
  final String deskripsi;
  final String? linkSoal;
  final DateTime tanggalDibuka;
  final DateTime tanggalBerakhir;
  final String? linkPdf;
  final List<TaskComment> komentar;
  final List<StudentSubmission> submissions; // Daftar pengumpulan siswa
  final String createdBy; // ID admin/guru yang membuat
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  AdminTask({
    required this.id,
    required this.tanggalDibuat,
    required this.kodeKelas,
    required this.mataPelajaran,
    required this.judul,
    required this.deskripsi,
    this.linkSoal,
    required this.tanggalDibuka,
    required this.tanggalBerakhir,
    this.linkPdf,
    this.komentar = const [],
    this.submissions = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  AdminTask copyWith({
    String? id,
    DateTime? tanggalDibuat,
    String? kodeKelas,
    String? mataPelajaran,
    String? judul,
    String? deskripsi,
    String? linkSoal,
    DateTime? tanggalDibuka,
    DateTime? tanggalBerakhir,
    String? linkPdf,
    List<TaskComment>? komentar,
    List<StudentSubmission>? submissions,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AdminTask(
      id: id ?? this.id,
      tanggalDibuat: tanggalDibuat ?? this.tanggalDibuat,
      kodeKelas: kodeKelas ?? this.kodeKelas,
      mataPelajaran: mataPelajaran ?? this.mataPelajaran,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      linkSoal: linkSoal ?? this.linkSoal,
      tanggalDibuka: tanggalDibuka ?? this.tanggalDibuka,
      tanggalBerakhir: tanggalBerakhir ?? this.tanggalBerakhir,
      linkPdf: linkPdf ?? this.linkPdf,
      komentar: komentar ?? this.komentar,
      submissions: submissions ?? this.submissions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AdminTask.fromJson(Map<String, dynamic> json) => _$AdminTaskFromJson(json);
  Map<String, dynamic> toJson() => _$AdminTaskToJson(this);
}

// Model untuk komentar tugas
@JsonSerializable()
class TaskComment {
  final String id;
  final String taskId;
  final String authorId;
  final String authorName;
  final String authorType; // 'guru' atau 'murid'
  final String comment;
  final DateTime createdAt;
  final bool isActive;

  TaskComment({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorName,
    required this.authorType,
    required this.comment,
    required this.createdAt,
    this.isActive = true,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) => _$TaskCommentFromJson(json);
  Map<String, dynamic> toJson() => _$TaskCommentToJson(this);
}

// Model untuk pengumpulan tugas siswa
@JsonSerializable()
class StudentSubmission {
  final String id;
  final String taskId;
  final String studentId;
  final String studentName;
  final String title; // Judul pengumpulan
  final String description; // Deskripsi pengumpulan
  final String link; // Link pengumpulan (Google Drive, dll)
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final int? score; // Nilai yang diberikan guru
  final String? feedback; // Feedback dari guru
  final bool isActive;

  StudentSubmission({
    required this.id,
    required this.taskId,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.description,
    required this.link,
    required this.submittedAt,
    this.gradedAt,
    this.score,
    this.feedback,
    this.isActive = true,
  });

  StudentSubmission copyWith({
    String? id,
    String? taskId,
    String? studentId,
    String? studentName,
    String? title,
    String? description,
    String? link,
    DateTime? submittedAt,
    DateTime? gradedAt,
    int? score,
    String? feedback,
    bool? isActive,
  }) {
    return StudentSubmission(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      title: title ?? this.title,
      description: description ?? this.description,
      link: link ?? this.link,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      isActive: isActive ?? this.isActive,
    );
  }

  factory StudentSubmission.fromJson(Map<String, dynamic> json) => _$StudentSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$StudentSubmissionToJson(this);
}