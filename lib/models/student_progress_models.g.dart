// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_progress_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentLearningProgress _$StudentLearningProgressFromJson(
  Map<String, dynamic> json,
) => StudentLearningProgress(
  studentId: json['studentId'] as String,
  classCodeId: json['classCodeId'] as String,
  schoolId: json['schoolId'] as String,
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
  overallAccuracy: (json['overallAccuracy'] as num?)?.toDouble() ?? 0.0,
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
  totalActiveDays: (json['totalActiveDays'] as num?)?.toInt() ?? 0,
  totalQuizzesCompleted: (json['totalQuizzesCompleted'] as num?)?.toInt() ?? 0,
  totalQuizQuestions: (json['totalQuizQuestions'] as num?)?.toInt() ?? 0,
  totalCorrectAnswers: (json['totalCorrectAnswers'] as num?)?.toInt() ?? 0,
  averageQuizScore: (json['averageQuizScore'] as num?)?.toDouble() ?? 0.0,
  totalTasksAssigned: (json['totalTasksAssigned'] as num?)?.toInt() ?? 0,
  totalTasksCompleted: (json['totalTasksCompleted'] as num?)?.toInt() ?? 0,
  totalTasksOnTime: (json['totalTasksOnTime'] as num?)?.toInt() ?? 0,
  taskCompletionRate: (json['taskCompletionRate'] as num?)?.toDouble() ?? 0.0,
  subjectProgress:
      (json['subjectProgress'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, SubjectProgress.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
  weeklyActivity:
      (json['weeklyActivity'] as List<dynamic>?)
          ?.map((e) => DailyActivity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  earnedBadges:
      (json['earnedBadges'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  achievements:
      (json['achievements'] as List<dynamic>?)
          ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalLearningTimeMinutes:
      (json['totalLearningTimeMinutes'] as num?)?.toInt() ?? 0,
  averageDailyLearningTime:
      (json['averageDailyLearningTime'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$StudentLearningProgressToJson(
  StudentLearningProgress instance,
) => <String, dynamic>{
  'studentId': instance.studentId,
  'classCodeId': instance.classCodeId,
  'schoolId': instance.schoolId,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
  'totalPoints': instance.totalPoints,
  'overallAccuracy': instance.overallAccuracy,
  'currentStreak': instance.currentStreak,
  'longestStreak': instance.longestStreak,
  'totalActiveDays': instance.totalActiveDays,
  'totalQuizzesCompleted': instance.totalQuizzesCompleted,
  'totalQuizQuestions': instance.totalQuizQuestions,
  'totalCorrectAnswers': instance.totalCorrectAnswers,
  'averageQuizScore': instance.averageQuizScore,
  'totalTasksAssigned': instance.totalTasksAssigned,
  'totalTasksCompleted': instance.totalTasksCompleted,
  'totalTasksOnTime': instance.totalTasksOnTime,
  'taskCompletionRate': instance.taskCompletionRate,
  'subjectProgress': instance.subjectProgress,
  'weeklyActivity': instance.weeklyActivity,
  'earnedBadges': instance.earnedBadges,
  'achievements': instance.achievements,
  'totalLearningTimeMinutes': instance.totalLearningTimeMinutes,
  'averageDailyLearningTime': instance.averageDailyLearningTime,
};

SubjectProgress _$SubjectProgressFromJson(Map<String, dynamic> json) =>
    SubjectProgress(
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      totalQuizzes: (json['totalQuizzes'] as num?)?.toInt() ?? 0,
      completedQuizzes: (json['completedQuizzes'] as num?)?.toInt() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      completedTopics:
          (json['completedTopics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      strugglingTopics:
          (json['strugglingTopics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubjectProgressToJson(SubjectProgress instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'subjectName': instance.subjectName,
      'totalQuizzes': instance.totalQuizzes,
      'completedQuizzes': instance.completedQuizzes,
      'averageScore': instance.averageScore,
      'totalTasks': instance.totalTasks,
      'completedTasks': instance.completedTasks,
      'totalPoints': instance.totalPoints,
      'accuracy': instance.accuracy,
      'lastActivity': instance.lastActivity.toIso8601String(),
      'completedTopics': instance.completedTopics,
      'strugglingTopics': instance.strugglingTopics,
    };

DailyActivity _$DailyActivityFromJson(Map<String, dynamic> json) =>
    DailyActivity(
      date: DateTime.parse(json['date'] as String),
      quizzesCompleted: (json['quizzesCompleted'] as num?)?.toInt() ?? 0,
      tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      learningTimeMinutes: (json['learningTimeMinutes'] as num?)?.toInt() ?? 0,
      subjectsStudied:
          (json['subjectsStudied'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DailyActivityToJson(DailyActivity instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'quizzesCompleted': instance.quizzesCompleted,
      'tasksCompleted': instance.tasksCompleted,
      'pointsEarned': instance.pointsEarned,
      'learningTimeMinutes': instance.learningTimeMinutes,
      'subjectsStudied': instance.subjectsStudied,
    };

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  iconUrl: json['iconUrl'] as String,
  type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
  earnedAt: DateTime.parse(json['earnedAt'] as String),
  pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'earnedAt': instance.earnedAt.toIso8601String(),
      'pointsAwarded': instance.pointsAwarded,
      'metadata': instance.metadata,
    };

const _$AchievementTypeEnumMap = {
  AchievementType.streak: 'streak',
  AchievementType.quiz: 'quiz',
  AchievementType.task: 'task',
  AchievementType.subject: 'subject',
  AchievementType.time: 'time',
  AchievementType.accuracy: 'accuracy',
  AchievementType.milestone: 'milestone',
};

WeeklyProgressSummary _$WeeklyProgressSummaryFromJson(
  Map<String, dynamic> json,
) => WeeklyProgressSummary(
  weekStart: DateTime.parse(json['weekStart'] as String),
  weekEnd: DateTime.parse(json['weekEnd'] as String),
  totalActiveDays: (json['totalActiveDays'] as num?)?.toInt() ?? 0,
  totalQuizzesCompleted: (json['totalQuizzesCompleted'] as num?)?.toInt() ?? 0,
  totalTasksCompleted: (json['totalTasksCompleted'] as num?)?.toInt() ?? 0,
  totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
  totalLearningTimeMinutes:
      (json['totalLearningTimeMinutes'] as num?)?.toInt() ?? 0,
  averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
  mostStudiedSubjects:
      (json['mostStudiedSubjects'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  dailyActivities:
      (json['dailyActivities'] as List<dynamic>?)
          ?.map((e) => DailyActivity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WeeklyProgressSummaryToJson(
  WeeklyProgressSummary instance,
) => <String, dynamic>{
  'weekStart': instance.weekStart.toIso8601String(),
  'weekEnd': instance.weekEnd.toIso8601String(),
  'totalActiveDays': instance.totalActiveDays,
  'totalQuizzesCompleted': instance.totalQuizzesCompleted,
  'totalTasksCompleted': instance.totalTasksCompleted,
  'totalPointsEarned': instance.totalPointsEarned,
  'totalLearningTimeMinutes': instance.totalLearningTimeMinutes,
  'averageAccuracy': instance.averageAccuracy,
  'mostStudiedSubjects': instance.mostStudiedSubjects,
  'dailyActivities': instance.dailyActivities,
};
