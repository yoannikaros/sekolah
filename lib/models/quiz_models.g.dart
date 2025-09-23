// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassCode _$ClassCodeFromJson(Map<String, dynamic> json) => ClassCode(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  teacherId: json['teacherId'] as String,
  schoolId: json['schoolId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$ClassCodeToJson(ClassCode instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'teacherId': instance.teacherId,
  'schoolId': instance.schoolId,
  'createdAt': instance.createdAt.toIso8601String(),
  'isActive': instance.isActive,
};

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
  id: json['id'] as String,
  question: json['question'] as String,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctAnswerIndex: (json['correctAnswerIndex'] as num).toInt(),
  type: $enumDecode(_$QuestionTypeEnumMap, json['type']),
  imageUrl: json['imageUrl'] as String?,
  explanation: json['explanation'] as String?,
  points: (json['points'] as num?)?.toInt() ?? 10,
  category: $enumDecode(_$QuestionCategoryEnumMap, json['category']),
  subjectId: json['subjectId'] as String?,
);

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
  'id': instance.id,
  'question': instance.question,
  'options': instance.options,
  'correctAnswerIndex': instance.correctAnswerIndex,
  'type': _$QuestionTypeEnumMap[instance.type]!,
  'imageUrl': instance.imageUrl,
  'explanation': instance.explanation,
  'points': instance.points,
  'category': _$QuestionCategoryEnumMap[instance.category]!,
  'subjectId': instance.subjectId,
};

const _$QuestionTypeEnumMap = {
  QuestionType.multipleChoice: 'multipleChoice',
  QuestionType.trueFalse: 'trueFalse',
  QuestionType.fillInTheBlank: 'fillInTheBlank',
  QuestionType.matching: 'matching',
};

const _$QuestionCategoryEnumMap = {
  QuestionCategory.reading: 'reading',
  QuestionCategory.writing: 'writing',
  QuestionCategory.math: 'math',
  QuestionCategory.science: 'science',
};

Quiz _$QuizFromJson(Map<String, dynamic> json) => Quiz(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  questionIds:
      (json['questionIds'] as List<dynamic>).map((e) => e as String).toList(),
  category: $enumDecode(_$QuestionCategoryEnumMap, json['category']),
  totalPoints: (json['totalPoints'] as num).toInt(),
  timeLimit: (json['timeLimit'] as num?)?.toInt() ?? 30,
  classCodeId: json['classCodeId'] as String,
  subjectId: json['subjectId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$QuizToJson(Quiz instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'questionIds': instance.questionIds,
  'category': _$QuestionCategoryEnumMap[instance.category]!,
  'totalPoints': instance.totalPoints,
  'timeLimit': instance.timeLimit,
  'classCodeId': instance.classCodeId,
  'subjectId': instance.subjectId,
  'createdAt': instance.createdAt.toIso8601String(),
  'isActive': instance.isActive,
};

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
  id: json['id'] as String,
  userId: json['userId'] as String,
  classCodeId: json['classCodeId'] as String,
  quizResults:
      (json['quizResults'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, QuizResult.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
  earnedBadges:
      (json['earnedBadges'] as List<dynamic>?)
          ?.map((e) => Badge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
  streak: (json['streak'] as num?)?.toInt() ?? 0,
  lastActivity: DateTime.parse(json['lastActivity'] as String),
  categoryProgress:
      (json['categoryProgress'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          $enumDecode(_$QuestionCategoryEnumMap, k),
          CategoryProgress.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const {},
);

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'classCodeId': instance.classCodeId,
      'quizResults': instance.quizResults,
      'earnedBadges': instance.earnedBadges,
      'totalPoints': instance.totalPoints,
      'streak': instance.streak,
      'lastActivity': instance.lastActivity.toIso8601String(),
      'categoryProgress': instance.categoryProgress.map(
        (k, e) => MapEntry(_$QuestionCategoryEnumMap[k]!, e),
      ),
    };

QuizResult _$QuizResultFromJson(Map<String, dynamic> json) => QuizResult(
  quizId: json['quizId'] as String,
  score: (json['score'] as num).toInt(),
  totalQuestions: (json['totalQuestions'] as num).toInt(),
  correctAnswers: (json['correctAnswers'] as num).toInt(),
  timeSpent: (json['timeSpent'] as num).toInt(),
  completedAt: DateTime.parse(json['completedAt'] as String),
  answers:
      (json['answers'] as List<dynamic>)
          .map((e) => UserAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$QuizResultToJson(QuizResult instance) =>
    <String, dynamic>{
      'quizId': instance.quizId,
      'score': instance.score,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'timeSpent': instance.timeSpent,
      'completedAt': instance.completedAt.toIso8601String(),
      'answers': instance.answers,
    };

UserAnswer _$UserAnswerFromJson(Map<String, dynamic> json) => UserAnswer(
  questionId: json['questionId'] as String,
  selectedAnswerIndex: (json['selectedAnswerIndex'] as num).toInt(),
  isCorrect: json['isCorrect'] as bool,
  timeSpent: (json['timeSpent'] as num).toInt(),
);

Map<String, dynamic> _$UserAnswerToJson(UserAnswer instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'selectedAnswerIndex': instance.selectedAnswerIndex,
      'isCorrect': instance.isCorrect,
      'timeSpent': instance.timeSpent,
    };

Badge _$BadgeFromJson(Map<String, dynamic> json) => Badge(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  iconUrl: json['iconUrl'] as String,
  type: $enumDecode(_$BadgeTypeEnumMap, json['type']),
  earnedAt: DateTime.parse(json['earnedAt'] as String),
  criteria: json['criteria'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$BadgeToJson(Badge instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'iconUrl': instance.iconUrl,
  'type': _$BadgeTypeEnumMap[instance.type]!,
  'earnedAt': instance.earnedAt.toIso8601String(),
  'criteria': instance.criteria,
};

const _$BadgeTypeEnumMap = {
  BadgeType.streak: 'streak',
  BadgeType.category: 'category',
  BadgeType.achievement: 'achievement',
  BadgeType.milestone: 'milestone',
};

CategoryProgress _$CategoryProgressFromJson(Map<String, dynamic> json) =>
    CategoryProgress(
      category: $enumDecode(_$QuestionCategoryEnumMap, json['category']),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$CategoryProgressToJson(CategoryProgress instance) =>
    <String, dynamic>{
      'category': _$QuestionCategoryEnumMap[instance.category]!,
      'totalQuestions': instance.totalQuestions,
      'correctAnswers': instance.correctAnswers,
      'totalPoints': instance.totalPoints,
      'accuracy': instance.accuracy,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
