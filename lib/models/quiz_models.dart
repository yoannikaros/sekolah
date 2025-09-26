import 'package:json_annotation/json_annotation.dart';

part 'quiz_models.g.dart';

@JsonSerializable()
class ClassCode {
  final String id;
  final String code;
  final String name;
  final String description;
  final String teacherId;
  final String? schoolId; // Link class to school - nullable to handle missing schoolId
  final DateTime createdAt;
  final bool isActive;

  ClassCode({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.teacherId,
    this.schoolId, // Make schoolId optional
    required this.createdAt,
    this.isActive = true,
  });

  factory ClassCode.fromJson(Map<String, dynamic> json) => _$ClassCodeFromJson(json);
  Map<String, dynamic> toJson() => _$ClassCodeToJson(this);
}

@JsonSerializable()
class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final QuestionType type;
  final String? imageUrl;
  final String? explanation;
  final int points;
  final QuestionCategory category;
  final String? subjectId; // Link question to subject for better organization

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.type,
    this.imageUrl,
    this.explanation,
    this.points = 10,
    required this.category,
    this.subjectId,
  });

  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}

@JsonSerializable()
class Quiz {
  final String id;
  final String title;
  final String description;
  final List<String> questionIds;
  final QuestionCategory category;
  final int totalPoints;
  final int timeLimit; // in minutes
  final String classCodeId;
  final String subjectId; // Link quiz to subject
  final DateTime createdAt;
  final bool isActive;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questionIds,
    required this.category,
    required this.totalPoints,
    this.timeLimit = 30,
    required this.classCodeId,
    required this.subjectId,
    required this.createdAt,
    this.isActive = true,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) => _$QuizFromJson(json);
  Map<String, dynamic> toJson() => _$QuizToJson(this);
}

@JsonSerializable()
class UserProgress {
  final String id;
  final String userId;
  final String classCodeId;
  final Map<String, QuizResult> quizResults;
  final List<Badge> earnedBadges;
  final int totalPoints;
  final int streak;
  final DateTime lastActivity;
  final Map<QuestionCategory, CategoryProgress> categoryProgress;

  UserProgress({
    required this.id,
    required this.userId,
    required this.classCodeId,
    this.quizResults = const {},
    this.earnedBadges = const [],
    this.totalPoints = 0,
    this.streak = 0,
    required this.lastActivity,
    this.categoryProgress = const {},
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) => _$UserProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserProgressToJson(this);
}

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

@JsonSerializable()
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeType type;
  final DateTime earnedAt;
  final Map<String, dynamic>? criteria;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.earnedAt,
    this.criteria,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
  Map<String, dynamic> toJson() => _$BadgeToJson(this);
}

@JsonSerializable()
class CategoryProgress {
  final QuestionCategory category;
  final int totalQuestions;
  final int correctAnswers;
  final int totalPoints;
  final double accuracy;
  final DateTime lastUpdated;

  CategoryProgress({
    required this.category,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.totalPoints = 0,
    this.accuracy = 0.0,
    required this.lastUpdated,
  });

  factory CategoryProgress.fromJson(Map<String, dynamic> json) => _$CategoryProgressFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryProgressToJson(this);
}

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillInTheBlank,
  matching,
}

enum QuestionCategory {
  reading,
  writing,
  math,
  science,
}

enum BadgeType {
  streak,
  category,
  achievement,
  milestone,
}