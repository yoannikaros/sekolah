import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';

part 'chapter_models.g.dart';

// Enum untuk jenis soal
enum QuestionType {
  @JsonValue('multiple_choice')
  multipleChoice,
  @JsonValue('essay')
  essay,
}

// Model untuk Bab (Chapter)
@JsonSerializable()
class Chapter {
  final String id;
  final String title; // Judul Bab (contoh: Bab 1 – Aljabar Dasar)
  final String? description; // Deskripsi Bab (opsional)
  final String subjectName; // Mata Pelajaran
  final String classCode; // Kode Kelas
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int? sortOrder;

  Chapter({
    required this.id,
    required this.title,
    this.description,
    required this.subjectName,
    required this.classCode,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.sortOrder,
  });

  Chapter copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectName,
    String? classCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? sortOrder,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectName: subjectName ?? this.subjectName,
      classCode: classCode ?? this.classCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    try {
      return _$ChapterFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Chapter from JSON: $e');
        print('JSON data: $json');
      }
      return Chapter(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Unknown Chapter',
        description: json['description'] as String?,
        subjectName: json['subjectName'] as String? ?? '',
        classCode: json['classCode'] as String? ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
        sortOrder: json['sortOrder'] as int?,
      );
    }
  }

  Map<String, dynamic> toJson() => _$ChapterToJson(this);
}

// Model untuk Kuis (Quiz)
@JsonSerializable()
class Quiz {
  final String id;
  final String chapterId; // Relasi ke Bab
  final String title; // Judul Kuis
  final DateTime createdDate; // Tanggal Dibuat
  final DateTime startDateTime; // Tanggal dan Jam Mulai
  final DateTime endDateTime; // Tanggal dan Jam Selesai
  final bool isActive;
  final int? totalQuestions;
  final int? totalPoints;

  Quiz({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.createdDate,
    required this.startDateTime,
    required this.endDateTime,
    this.isActive = true,
    this.totalQuestions,
    this.totalPoints,
  });

  Quiz copyWith({
    String? id,
    String? chapterId,
    String? title,
    DateTime? createdDate,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? isActive,
    int? totalQuestions,
    int? totalPoints,
  }) {
    return Quiz(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      createdDate: createdDate ?? this.createdDate,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      isActive: isActive ?? this.isActive,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    try {
      return _$QuizFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Quiz from JSON: $e');
        print('JSON data: $json');
      }
      return Quiz(
        id: json['id'] as String? ?? '',
        chapterId: json['chapterId'] as String? ?? '',
        title: json['title'] as String? ?? 'Unknown Quiz',
        createdDate: DateTime.now(),
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now().add(const Duration(hours: 1)),
        isActive: json['isActive'] as bool? ?? true,
        totalQuestions: json['totalQuestions'] as int?,
        totalPoints: json['totalPoints'] as int?,
      );
    }
  }

  Map<String, dynamic> toJson() => _$QuizToJson(this);
}

// Model untuk Opsi Pilihan Ganda
@JsonSerializable()
class MultipleChoiceOption {
  final String id;
  final String optionText;
  final String optionLabel; // A, B, C, D
  final bool isCorrect;

  MultipleChoiceOption({
    required this.id,
    required this.optionText,
    required this.optionLabel,
    required this.isCorrect,
  });

  MultipleChoiceOption copyWith({
    String? id,
    String? optionText,
    String? optionLabel,
    bool? isCorrect,
  }) {
    return MultipleChoiceOption(
      id: id ?? this.id,
      optionText: optionText ?? this.optionText,
      optionLabel: optionLabel ?? this.optionLabel,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  factory MultipleChoiceOption.fromJson(Map<String, dynamic> json) {
    try {
      return _$MultipleChoiceOptionFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing MultipleChoiceOption from JSON: $e');
        print('JSON data: $json');
      }
      return MultipleChoiceOption(
        id: json['id'] as String? ?? '',
        optionText: json['optionText'] as String? ?? '',
        optionLabel: json['optionLabel'] as String? ?? 'A',
        isCorrect: json['isCorrect'] as bool? ?? false,
      );
    }
  }

  Map<String, dynamic> toJson() => _$MultipleChoiceOptionToJson(this);
}

// Model untuk Soal (Question)
@JsonSerializable()
class Question {
  final String id;
  final String quizId; // Relasi ke Kuis
  final String questionText; // Pertanyaan
  final QuestionType questionType; // Jenis Soal: Pilihan Ganda / Essay
  final List<MultipleChoiceOption>? multipleChoiceOptions; // Untuk pilihan ganda
  final String? essayKeyAnswer; // Jawaban kunci untuk essay (opsional)
  final int points; // Poin / Skor
  final int? orderNumber; // Urutan soal
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Question({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    this.multipleChoiceOptions,
    this.essayKeyAnswer,
    required this.points,
    this.orderNumber,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  Question copyWith({
    String? id,
    String? quizId,
    String? questionText,
    QuestionType? questionType,
    List<MultipleChoiceOption>? multipleChoiceOptions,
    String? essayKeyAnswer,
    int? points,
    int? orderNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Question(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      multipleChoiceOptions: multipleChoiceOptions ?? this.multipleChoiceOptions,
      essayKeyAnswer: essayKeyAnswer ?? this.essayKeyAnswer,
      points: points ?? this.points,
      orderNumber: orderNumber ?? this.orderNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    try {
      return _$QuestionFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Question from JSON: $e');
        print('JSON data: $json');
      }
      return Question(
        id: json['id'] as String? ?? '',
        quizId: json['quizId'] as String? ?? '',
        questionText: json['questionText'] as String? ?? '',
        questionType: QuestionType.multipleChoice,
        points: json['points'] as int? ?? 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
      );
    }
  }

  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}

// Model untuk Response/Summary
@JsonSerializable()
class ChapterSummary {
  final Chapter chapter;
  final int totalQuizzes;
  final int totalQuestions;
  final int totalPoints;

  ChapterSummary({
    required this.chapter,
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.totalPoints,
  });

  factory ChapterSummary.fromJson(Map<String, dynamic> json) =>
      _$ChapterSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterSummaryToJson(this);
}

@JsonSerializable()
class QuizSummary {
  final Quiz quiz;
  final Chapter chapter;
  final int totalQuestions;
  final int totalPoints;

  QuizSummary({
    required this.quiz,
    required this.chapter,
    required this.totalQuestions,
    required this.totalPoints,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) =>
      _$QuizSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$QuizSummaryToJson(this);
}