import 'package:json_annotation/json_annotation.dart';

part 'leaderboard_models.g.dart';

// Model untuk Leaderboard Entry
@JsonSerializable()
class LeaderboardEntry {
  final String studentId;
  final String studentName;
  final String classCodeId;
  final String classCodeName;
  final int totalScore;
  final int totalQuizzes;
  final int correctAnswers;
  final int totalQuestions;
  final double accuracy;
  final int streak;
  final List<String> earnedBadgeIds;
  final DateTime lastActivity;
  final int rank;
  final String? profileImageUrl;

  LeaderboardEntry({
    required this.studentId,
    required this.studentName,
    required this.classCodeId,
    required this.classCodeName,
    required this.totalScore,
    required this.totalQuizzes,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.accuracy,
    required this.streak,
    required this.earnedBadgeIds,
    required this.lastActivity,
    required this.rank,
    this.profileImageUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => 
      _$LeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);
}

// Model untuk Badge yang lebih lengkap
@JsonSerializable()
class GameBadge {
  final String id;
  final String name;
  final String description;
  final String iconName; // Nama icon dari material icons
  final String color; // Hex color code
  final BadgeCategory category;
  final BadgeRarity rarity;
  final Map<String, dynamic> criteria; // Kriteria untuk mendapatkan badge
  final int points; // Poin yang didapat saat meraih badge
  final DateTime createdAt;
  final bool isActive;

  GameBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.color,
    required this.category,
    required this.rarity,
    required this.criteria,
    required this.points,
    required this.createdAt,
    this.isActive = true,
  });

  factory GameBadge.fromJson(Map<String, dynamic> json) => 
      _$GameBadgeFromJson(json);
  Map<String, dynamic> toJson() => _$GameBadgeToJson(this);
}

// Model untuk Student Badge (badge yang dimiliki siswa)
@JsonSerializable()
class StudentBadge {
  final String id;
  final String studentId;
  final String badgeId;
  final GameBadge badge;
  final DateTime earnedAt;
  final Map<String, dynamic>? earnedCriteria; // Kriteria saat meraih badge

  StudentBadge({
    required this.id,
    required this.studentId,
    required this.badgeId,
    required this.badge,
    required this.earnedAt,
    this.earnedCriteria,
  });

  factory StudentBadge.fromJson(Map<String, dynamic> json) => 
      _$StudentBadgeFromJson(json);
  Map<String, dynamic> toJson() => _$StudentBadgeToJson(this);
}

// Model untuk Class Leaderboard
@JsonSerializable()
class ClassLeaderboard {
  final String classCodeId;
  final String classCodeName;
  final List<LeaderboardEntry> entries;
  final DateTime lastUpdated;
  final int totalStudents;
  final double averageScore;
  final int totalQuizzes;

  ClassLeaderboard({
    required this.classCodeId,
    required this.classCodeName,
    required this.entries,
    required this.lastUpdated,
    required this.totalStudents,
    required this.averageScore,
    required this.totalQuizzes,
  });

  factory ClassLeaderboard.fromJson(Map<String, dynamic> json) => 
      _$ClassLeaderboardFromJson(json);
  Map<String, dynamic> toJson() => _$ClassLeaderboardToJson(this);
}

// Enums
enum BadgeCategory {
  @JsonValue('achievement')
  achievement,
  @JsonValue('streak')
  streak,
  @JsonValue('accuracy')
  accuracy,
  @JsonValue('participation')
  participation,
  @JsonValue('milestone')
  milestone,
  @JsonValue('special')
  special,
}

enum BadgeRarity {
  @JsonValue('common')
  common,
  @JsonValue('uncommon')
  uncommon,
  @JsonValue('rare')
  rare,
  @JsonValue('epic')
  epic,
  @JsonValue('legendary')
  legendary,
}

// Model untuk Student Statistics
@JsonSerializable()
class StudentStatistics {
  final String studentId;
  final String classCodeId;
  final int totalScore;
  final int totalQuizzes;
  final int correctAnswers;
  final int totalQuestions;
  final double accuracy;
  final int currentStreak;
  final int longestStreak;
  final List<StudentBadge> badges;
  final DateTime lastActivity;
  final Map<String, int> subjectScores; // Score per mata pelajaran
  final int rank;
  final int totalStudentsInClass;

  StudentStatistics({
    required this.studentId,
    required this.classCodeId,
    required this.totalScore,
    required this.totalQuizzes,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.accuracy,
    required this.currentStreak,
    required this.longestStreak,
    required this.badges,
    required this.lastActivity,
    required this.subjectScores,
    required this.rank,
    required this.totalStudentsInClass,
  });

  factory StudentStatistics.fromJson(Map<String, dynamic> json) => 
      _$StudentStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$StudentStatisticsToJson(this);
}