// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  subjectName: json['subjectName'] as String,
  classCode: json['classCode'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'subjectName': instance.subjectName,
  'classCode': instance.classCode,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
  'sortOrder': instance.sortOrder,
};

Quiz _$QuizFromJson(Map<String, dynamic> json) => Quiz(
  id: json['id'] as String,
  chapterId: json['chapterId'] as String,
  title: json['title'] as String,
  createdDate: DateTime.parse(json['createdDate'] as String),
  startDateTime: DateTime.parse(json['startDateTime'] as String),
  endDateTime: DateTime.parse(json['endDateTime'] as String),
  isActive: json['isActive'] as bool? ?? true,
  totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
  totalPoints: (json['totalPoints'] as num?)?.toInt(),
);

Map<String, dynamic> _$QuizToJson(Quiz instance) => <String, dynamic>{
  'id': instance.id,
  'chapterId': instance.chapterId,
  'title': instance.title,
  'createdDate': instance.createdDate.toIso8601String(),
  'startDateTime': instance.startDateTime.toIso8601String(),
  'endDateTime': instance.endDateTime.toIso8601String(),
  'isActive': instance.isActive,
  'totalQuestions': instance.totalQuestions,
  'totalPoints': instance.totalPoints,
};

MultipleChoiceOption _$MultipleChoiceOptionFromJson(
  Map<String, dynamic> json,
) => MultipleChoiceOption(
  id: json['id'] as String,
  optionText: json['optionText'] as String,
  optionLabel: json['optionLabel'] as String,
  isCorrect: json['isCorrect'] as bool,
);

Map<String, dynamic> _$MultipleChoiceOptionToJson(
  MultipleChoiceOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'optionText': instance.optionText,
  'optionLabel': instance.optionLabel,
  'isCorrect': instance.isCorrect,
};

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
  id: json['id'] as String,
  quizId: json['quizId'] as String,
  questionText: json['questionText'] as String,
  questionType: $enumDecode(_$QuestionTypeEnumMap, json['questionType']),
  multipleChoiceOptions:
      (json['multipleChoiceOptions'] as List<dynamic>?)
          ?.map((e) => MultipleChoiceOption.fromJson(e as Map<String, dynamic>))
          .toList(),
  essayKeyAnswer: json['essayKeyAnswer'] as String?,
  points: (json['points'] as num).toInt(),
  orderNumber: (json['orderNumber'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
  'id': instance.id,
  'quizId': instance.quizId,
  'questionText': instance.questionText,
  'questionType': _$QuestionTypeEnumMap[instance.questionType]!,
  'multipleChoiceOptions': instance.multipleChoiceOptions,
  'essayKeyAnswer': instance.essayKeyAnswer,
  'points': instance.points,
  'orderNumber': instance.orderNumber,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
};

const _$QuestionTypeEnumMap = {
  QuestionType.multipleChoice: 'multiple_choice',
  QuestionType.essay: 'essay',
};

ChapterSummary _$ChapterSummaryFromJson(Map<String, dynamic> json) =>
    ChapterSummary(
      chapter: Chapter.fromJson(json['chapter'] as Map<String, dynamic>),
      totalQuizzes: (json['totalQuizzes'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toInt(),
    );

Map<String, dynamic> _$ChapterSummaryToJson(ChapterSummary instance) =>
    <String, dynamic>{
      'chapter': instance.chapter,
      'totalQuizzes': instance.totalQuizzes,
      'totalQuestions': instance.totalQuestions,
      'totalPoints': instance.totalPoints,
    };

QuizSummary _$QuizSummaryFromJson(Map<String, dynamic> json) => QuizSummary(
  quiz: Quiz.fromJson(json['quiz'] as Map<String, dynamic>),
  chapter: Chapter.fromJson(json['chapter'] as Map<String, dynamic>),
  totalQuestions: (json['totalQuestions'] as num).toInt(),
  totalPoints: (json['totalPoints'] as num).toInt(),
);

Map<String, dynamic> _$QuizSummaryToJson(QuizSummary instance) =>
    <String, dynamic>{
      'quiz': instance.quiz,
      'chapter': instance.chapter,
      'totalQuestions': instance.totalQuestions,
      'totalPoints': instance.totalPoints,
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
