import 'package:json_annotation/json_annotation.dart';

part 'student_progress_models.g.dart';

@JsonSerializable()
class StudentLearningProgress {
  final String studentId;
  final String classCodeId;
  final String schoolId;
  final DateTime lastUpdated;
  
  // Overall statistics
  final int totalPoints;
  final double overallAccuracy;
  final int currentStreak;
  final int longestStreak;
  final int totalActiveDays;
  
  // Quiz progress
  final int totalQuizzesCompleted;
  final int totalQuizQuestions;
  final int totalCorrectAnswers;
  final double averageQuizScore;
  
  // Task progress
  final int totalTasksAssigned;
  final int totalTasksCompleted;
  final int totalTasksOnTime;
  final double taskCompletionRate;
  
  // Subject-wise progress
  final Map<String, SubjectProgress> subjectProgress;
  
  // Weekly activity
  final List<DailyActivity> weeklyActivity;
  
  // Achievements and badges
  final List<String> earnedBadges;
  final List<Achievement> achievements;
  
  // Learning time tracking
  final int totalLearningTimeMinutes;
  final double averageDailyLearningTime;

  StudentLearningProgress({
    required this.studentId,
    required this.classCodeId,
    required this.schoolId,
    required this.lastUpdated,
    this.totalPoints = 0,
    this.overallAccuracy = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalActiveDays = 0,
    this.totalQuizzesCompleted = 0,
    this.totalQuizQuestions = 0,
    this.totalCorrectAnswers = 0,
    this.averageQuizScore = 0.0,
    this.totalTasksAssigned = 0,
    this.totalTasksCompleted = 0,
    this.totalTasksOnTime = 0,
    this.taskCompletionRate = 0.0,
    this.subjectProgress = const {},
    this.weeklyActivity = const [],
    this.earnedBadges = const [],
    this.achievements = const [],
    this.totalLearningTimeMinutes = 0,
    this.averageDailyLearningTime = 0.0,
  });

  factory StudentLearningProgress.fromJson(Map<String, dynamic> json) =>
      _$StudentLearningProgressFromJson(json);

  Map<String, dynamic> toJson() => _$StudentLearningProgressToJson(this);
}

@JsonSerializable()
class SubjectProgress {
  final String subjectId;
  final String subjectName;
  final int totalQuizzes;
  final int completedQuizzes;
  final double averageScore;
  final int totalTasks;
  final int completedTasks;
  final int totalPoints;
  final double accuracy;
  final DateTime lastActivity;
  final List<String> completedTopics;
  final List<String> strugglingTopics;

  SubjectProgress({
    required this.subjectId,
    required this.subjectName,
    this.totalQuizzes = 0,
    this.completedQuizzes = 0,
    this.averageScore = 0.0,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.totalPoints = 0,
    this.accuracy = 0.0,
    required this.lastActivity,
    this.completedTopics = const [],
    this.strugglingTopics = const [],
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> json) =>
      _$SubjectProgressFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectProgressToJson(this);

  double get completionRate {
    if (totalQuizzes == 0 && totalTasks == 0) return 0.0;
    final totalActivities = totalQuizzes + totalTasks;
    final completedActivities = completedQuizzes + completedTasks;
    return (completedActivities / totalActivities) * 100;
  }
}

@JsonSerializable()
class DailyActivity {
  final DateTime date;
  final int quizzesCompleted;
  final int tasksCompleted;
  final int pointsEarned;
  final int learningTimeMinutes;
  final List<String> subjectsStudied;

  DailyActivity({
    required this.date,
    this.quizzesCompleted = 0,
    this.tasksCompleted = 0,
    this.pointsEarned = 0,
    this.learningTimeMinutes = 0,
    this.subjectsStudied = const [],
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) =>
      _$DailyActivityFromJson(json);

  Map<String, dynamic> toJson() => _$DailyActivityToJson(this);

  bool get isActive => quizzesCompleted > 0 || tasksCompleted > 0 || learningTimeMinutes > 0;
}

@JsonSerializable()
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final AchievementType type;
  final DateTime earnedAt;
  final int pointsAwarded;
  final Map<String, dynamic>? metadata;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.earnedAt,
    this.pointsAwarded = 0,
    this.metadata,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);

  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}

@JsonSerializable()
class WeeklyProgressSummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalActiveDays;
  final int totalQuizzesCompleted;
  final int totalTasksCompleted;
  final int totalPointsEarned;
  final int totalLearningTimeMinutes;
  final double averageAccuracy;
  final List<String> mostStudiedSubjects;
  final List<DailyActivity> dailyActivities;

  WeeklyProgressSummary({
    required this.weekStart,
    required this.weekEnd,
    this.totalActiveDays = 0,
    this.totalQuizzesCompleted = 0,
    this.totalTasksCompleted = 0,
    this.totalPointsEarned = 0,
    this.totalLearningTimeMinutes = 0,
    this.averageAccuracy = 0.0,
    this.mostStudiedSubjects = const [],
    this.dailyActivities = const [],
  });

  factory WeeklyProgressSummary.fromJson(Map<String, dynamic> json) =>
      _$WeeklyProgressSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyProgressSummaryToJson(this);
}

enum AchievementType {
  streak,
  quiz,
  task,
  subject,
  time,
  accuracy,
  milestone,
}

// Helper class for progress analytics
class ProgressAnalytics {
  static double calculateGrowthRate(List<DailyActivity> activities) {
    if (activities.length < 2) return 0.0;
    
    final recent = activities.take(3).fold(0, (sum, activity) => sum + activity.pointsEarned);
    final previous = activities.skip(3).take(3).fold(0, (sum, activity) => sum + activity.pointsEarned);
    
    if (previous == 0) return recent > 0 ? 100.0 : 0.0;
    return ((recent - previous) / previous) * 100;
  }
  
  static List<String> getStrengthSubjects(Map<String, SubjectProgress> subjectProgress) {
    final subjects = subjectProgress.values.toList();
    subjects.sort((a, b) => b.accuracy.compareTo(a.accuracy));
    return subjects.take(3).map((s) => s.subjectName).toList();
  }
  
  static List<String> getImprovementAreas(Map<String, SubjectProgress> subjectProgress) {
    final subjects = subjectProgress.values.toList();
    subjects.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return subjects.take(3).map((s) => s.subjectName).toList();
  }
}