// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

School _$SchoolFromJson(Map<String, dynamic> json) => School(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  website: json['website'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  logoUrl: json['logoUrl'] as String?,
);

Map<String, dynamic> _$SchoolToJson(School instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'phone': instance.phone,
  'email': instance.email,
  'website': instance.website,
  'createdAt': instance.createdAt.toIso8601String(),
  'isActive': instance.isActive,
  'logoUrl': instance.logoUrl,
};

Subject _$SubjectFromJson(Map<String, dynamic> json) => Subject(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  code: json['code'] as String,
  schoolId: json['schoolId'] as String,
  classCodeIds:
      (json['classCodeIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  iconUrl: json['iconUrl'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$SubjectToJson(Subject instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'code': instance.code,
  'schoolId': instance.schoolId,
  'classCodeIds': instance.classCodeIds,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
  'iconUrl': instance.iconUrl,
  'sortOrder': instance.sortOrder,
};

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  studentId: json['studentId'] as String,
  classCodeId: json['classCodeId'] as String,
  schoolId: json['schoolId'] as String,
  enrolledAt: DateTime.parse(json['enrolledAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  profileImageUrl: json['profileImageUrl'] as String?,
);

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'studentId': instance.studentId,
  'classCodeId': instance.classCodeId,
  'schoolId': instance.schoolId,
  'enrolledAt': instance.enrolledAt.toIso8601String(),
  'isActive': instance.isActive,
  'profileImageUrl': instance.profileImageUrl,
};

AdminUser _$AdminUserFromJson(Map<String, dynamic> json) => AdminUser(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
  role: $enumDecode(_$AdminRoleEnumMap, json['role']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  lastLogin:
      json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
  managedClassCodes:
      (json['managedClassCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  schoolId: json['schoolId'] as String?,
);

Map<String, dynamic> _$AdminUserToJson(AdminUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'password': instance.password,
  'role': _$AdminRoleEnumMap[instance.role]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'isActive': instance.isActive,
  'lastLogin': instance.lastLogin?.toIso8601String(),
  'managedClassCodes': instance.managedClassCodes,
  'schoolId': instance.schoolId,
};

const _$AdminRoleEnumMap = {
  AdminRole.superAdmin: 'superAdmin',
  AdminRole.teacher: 'teacher',
  AdminRole.assistant: 'assistant',
};

QuestionBank _$QuestionBankFromJson(Map<String, dynamic> json) => QuestionBank(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  questionIds:
      (json['questionIds'] as List<dynamic>).map((e) => e as String).toList(),
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isPublic: json['isPublic'] as bool? ?? false,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$QuestionBankToJson(QuestionBank instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'questionIds': instance.questionIds,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isPublic': instance.isPublic,
      'tags': instance.tags,
    };

Teacher _$TeacherFromJson(Map<String, dynamic> json) => Teacher(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  schoolId: json['schoolId'] as String,
  phone: json['phone'] as String?,
  address: json['address'] as String?,
  subjectIds:
      (json['subjectIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  profileImageUrl: json['profileImageUrl'] as String?,
  employeeId: json['employeeId'] as String?,
  lastLogin:
      json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String),
);

Map<String, dynamic> _$TeacherToJson(Teacher instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'schoolId': instance.schoolId,
  'phone': instance.phone,
  'address': instance.address,
  'subjectIds': instance.subjectIds,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
  'profileImageUrl': instance.profileImageUrl,
  'employeeId': instance.employeeId,
  'lastLogin': instance.lastLogin?.toIso8601String(),
};

AdminQuiz _$AdminQuizFromJson(Map<String, dynamic> json) => AdminQuiz(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  subjectId: json['subjectId'] as String,
  classCodeId: json['classCodeId'] as String,
  chapterIds:
      (json['chapterIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  isPublished: json['isPublished'] as bool? ?? false,
  timeLimit: (json['timeLimit'] as num?)?.toInt(),
  publishedAt:
      json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
  dueDate:
      json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
);

Map<String, dynamic> _$AdminQuizToJson(AdminQuiz instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'subjectId': instance.subjectId,
  'classCodeId': instance.classCodeId,
  'chapterIds': instance.chapterIds,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isActive': instance.isActive,
  'isPublished': instance.isPublished,
  'timeLimit': instance.timeLimit,
  'publishedAt': instance.publishedAt?.toIso8601String(),
  'dueDate': instance.dueDate?.toIso8601String(),
};

QuizChapter _$QuizChapterFromJson(Map<String, dynamic> json) => QuizChapter(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  quizId: json['quizId'] as String,
  questionIds:
      (json['questionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  orderIndex: (json['orderIndex'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$QuizChapterToJson(QuizChapter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'quizId': instance.quizId,
      'questionIds': instance.questionIds,
      'orderIndex': instance.orderIndex,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
    };

AdminQuestion _$AdminQuestionFromJson(Map<String, dynamic> json) =>
    AdminQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      type: $enumDecode(_$AdminQuestionTypeEnumMap, json['type']),
      chapterId: json['chapterId'] as String,
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      correctAnswerIndex: (json['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswerText: json['correctAnswerText'] as String?,
      explanation: json['explanation'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 10,
      orderIndex: (json['orderIndex'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AdminQuestionToJson(AdminQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questionText': instance.questionText,
      'type': _$AdminQuestionTypeEnumMap[instance.type]!,
      'chapterId': instance.chapterId,
      'options': instance.options,
      'correctAnswerIndex': instance.correctAnswerIndex,
      'correctAnswerText': instance.correctAnswerText,
      'explanation': instance.explanation,
      'points': instance.points,
      'orderIndex': instance.orderIndex,
      'imageUrl': instance.imageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isActive': instance.isActive,
      'metadata': instance.metadata,
    };

const _$AdminQuestionTypeEnumMap = {
  AdminQuestionType.multipleChoice: 'multipleChoice',
  AdminQuestionType.essay: 'essay',
};

StudentQuizAttempt _$StudentQuizAttemptFromJson(Map<String, dynamic> json) =>
    StudentQuizAttempt(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      quizId: json['quizId'] as String,
      answers:
          (json['answers'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, StudentAnswer.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt:
          json['completedAt'] == null
              ? null
              : DateTime.parse(json['completedAt'] as String),
      totalScore: (json['totalScore'] as num?)?.toInt(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      timeSpent: (json['timeSpent'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$StudentQuizAttemptToJson(StudentQuizAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'quizId': instance.quizId,
      'answers': instance.answers,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'totalScore': instance.totalScore,
      'isCompleted': instance.isCompleted,
      'timeSpent': instance.timeSpent,
    };

StudentAnswer _$StudentAnswerFromJson(Map<String, dynamic> json) =>
    StudentAnswer(
      questionId: json['questionId'] as String,
      questionType: $enumDecode(
        _$AdminQuestionTypeEnumMap,
        json['questionType'],
      ),
      selectedOptionIndex: (json['selectedOptionIndex'] as num?)?.toInt(),
      essayAnswer: json['essayAnswer'] as String?,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
      score: (json['score'] as num?)?.toInt(),
      isCorrect: json['isCorrect'] as bool?,
    );

Map<String, dynamic> _$StudentAnswerToJson(StudentAnswer instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'questionType': _$AdminQuestionTypeEnumMap[instance.questionType]!,
      'selectedOptionIndex': instance.selectedOptionIndex,
      'essayAnswer': instance.essayAnswer,
      'answeredAt': instance.answeredAt.toIso8601String(),
      'score': instance.score,
      'isCorrect': instance.isCorrect,
    };
