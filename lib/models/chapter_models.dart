import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // Ensure ID is always present from Firebase document ID
      final id = json['id'] as String? ?? '';
      if (id.isEmpty) {
        if (kDebugMode) {
          print('WARNING: Chapter ID is missing from JSON data!');
          print('JSON data: $json');
        }
        throw Exception('Chapter ID is required but missing from JSON data');
      }
      
      // Create a copy of json with guaranteed ID
      final jsonWithId = Map<String, dynamic>.from(json);
      jsonWithId['id'] = id;
      
      return _$ChapterFromJson(jsonWithId);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Chapter from JSON: $e');
        print('JSON data: $json');
      }
      
      // Fallback parsing with better ID handling
      final id = json['id'] as String? ?? '';
      if (id.isEmpty) {
        if (kDebugMode) {
          print('CRITICAL: Chapter ID is empty in fallback parsing!');
        }
        throw Exception('Chapter ID cannot be empty');
      }
      
      // Parse dates safely
      DateTime createdAt = DateTime.now();
      DateTime updatedAt = DateTime.now();
      
      try {
        if (json['createdAt'] != null) {
          if (json['createdAt'] is String) {
            createdAt = DateTime.parse(json['createdAt']);
          } else if (json['createdAt'] is Timestamp) {
            createdAt = (json['createdAt'] as Timestamp).toDate();
          }
        }
        
        if (json['updatedAt'] != null) {
          if (json['updatedAt'] is String) {
            updatedAt = DateTime.parse(json['updatedAt']);
          } else if (json['updatedAt'] is Timestamp) {
            updatedAt = (json['updatedAt'] as Timestamp).toDate();
          }
        }
      } catch (dateError) {
        if (kDebugMode) {
          print('Error parsing dates, using current time: $dateError');
        }
      }
      
      return Chapter(
        id: id,
        title: json['title'] as String? ?? 'Unknown Chapter',
        description: json['description'] as String?,
        subjectName: json['subjectName'] as String? ?? '',
        classCode: json['classCode'] as String? ?? '',
        createdAt: createdAt,
        updatedAt: updatedAt,
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
      // Fallback parsing with better ID and chapterId handling
      final id = json['id'] as String? ?? '';
      final chapterId = json['chapterId'] as String? ?? '';
      
      if (kDebugMode) {
        if (id.isEmpty) print('WARNING: Quiz ID is empty in JSON data!');
        if (chapterId.isEmpty) print('WARNING: Quiz chapterId is empty in JSON data!');
      }
      
      return Quiz(
        id: id,
        chapterId: chapterId,
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
      
      // Parse multipleChoiceOptions manually if available
      List<MultipleChoiceOption>? multipleChoiceOptions;
      if (json['multipleChoiceOptions'] != null) {
        try {
          final optionsData = json['multipleChoiceOptions'];
          if (kDebugMode) {
            print('Manual parsing multipleChoiceOptions: $optionsData');
            print('Type: ${optionsData.runtimeType}');
          }
          
          if (optionsData is List) {
            multipleChoiceOptions = optionsData
                .map((e) {
                  if (kDebugMode) {
                    print('Processing option: $e (type: ${e.runtimeType})');
                  }
                  
                  if (e is Map<String, dynamic>) {
                    return MultipleChoiceOption.fromJson(e);
                  } else if (e is Map) {
                    // Convert Map to Map<String, dynamic>
                    final convertedMap = <String, dynamic>{};
                    e.forEach((key, value) {
                      convertedMap[key.toString()] = value;
                    });
                    return MultipleChoiceOption.fromJson(convertedMap);
                  } else {
                    throw Exception('Invalid option format: $e');
                  }
                })
                .toList();
                
            if (kDebugMode) {
              print('Successfully parsed ${multipleChoiceOptions.length} options');
              for (int i = 0; i < multipleChoiceOptions.length; i++) {
                final option = multipleChoiceOptions[i];
                print('Option $i: ${option.optionLabel} = "${option.optionText}" (correct: ${option.isCorrect})');
              }
            }
          }
        } catch (optionError) {
          if (kDebugMode) {
            print('Error parsing multipleChoiceOptions: $optionError');
            print('Stack trace: ${StackTrace.current}');
          }
          multipleChoiceOptions = null;
        }
      }
      
      // Parse questionType manually
      QuestionType questionType = QuestionType.multipleChoice;
      if (json['questionType'] != null) {
        try {
          final typeString = json['questionType'] as String;
          questionType = QuestionType.values.firstWhere(
            (e) => e.name == typeString,
            orElse: () => QuestionType.multipleChoice,
          );
        } catch (typeError) {
          if (kDebugMode) {
            print('Error parsing questionType: $typeError');
          }
        }
      }
      
      final question = Question(
        id: json['id'] as String? ?? '',
        quizId: json['quizId'] as String? ?? '',
        questionText: json['questionText'] as String? ?? '',
        questionType: questionType,
        multipleChoiceOptions: multipleChoiceOptions,
        essayKeyAnswer: json['essayKeyAnswer'] as String?,
        points: json['points'] as int? ?? 1,
        orderNumber: json['orderNumber'] as int?,
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
      );
      
      if (kDebugMode) {
        print('Manual parsing result - multipleChoiceOptions: ${question.multipleChoiceOptions}');
        if (question.multipleChoiceOptions != null) {
          print('Manual parsing - options count: ${question.multipleChoiceOptions!.length}');
        }
      }
      
      return question;
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

// Model untuk jawaban user
@JsonSerializable()
class UserAnswer {
  final String questionId;
  final int selectedAnswerIndex;
  final bool isCorrect;
  final int timeSpent; // in seconds

  UserAnswer({
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.isCorrect,
    required this.timeSpent,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) => _$UserAnswerFromJson(json);
  Map<String, dynamic> toJson() => _$UserAnswerToJson(this);
}

// Model untuk hasil quiz
@JsonSerializable()
class QuizResult {
  final String quizId;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent; // in seconds
  final DateTime completedAt;
  final List<UserAnswer> answers;

  QuizResult({
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.completedAt,
    required this.answers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => _$QuizResultFromJson(json);
  Map<String, dynamic> toJson() => _$QuizResultToJson(this);
}