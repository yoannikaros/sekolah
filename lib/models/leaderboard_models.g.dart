// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      classCodeId: json['classCodeId'] as String,
      classCodeName: json['classCodeName'] as String,
      totalScore: (json['totalScore'] as num).toInt(),
      totalQuizzes: (json['totalQuizzes'] as num).toInt(),
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      accuracy: (json['accuracy'] as num).toDouble(),
      streak: (json['streak'] as num).toInt(),
      earnedBadgeIds:
          (json['earnedBadgeIds'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      rank: (json['rank'] as num).toInt(),
      profileImageUrl: json['profileImageUrl'] as String?,
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'classCodeId': instance.classCodeId,
      'classCodeName': instance.classCodeName,
      'totalScore': instance.totalScore,
      'totalQuizzes': instance.totalQuizzes,
      'correctAnswers': instance.correctAnswers,
      'totalQuestions': instance.totalQuestions,
      'accuracy': instance.accuracy,
      'streak': instance.streak,
      'earnedBadgeIds': instance.earnedBadgeIds,
      'lastActivity': instance.lastActivity.toIso8601String(),
      'rank': instance.rank,
      'profileImageUrl': instance.profileImageUrl,
    };

GameBadge _$GameBadgeFromJson(Map<String, dynamic> json) => GameBadge(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  iconName: json['iconName'] as String,
  color: json['color'] as String,
  category: $enumDecode(_$BadgeCategoryEnumMap, json['category']),
  rarity: $enumDecode(_$BadgeRarityEnumMap, json['rarity']),
  criteria: json['criteria'] as Map<String, dynamic>,
  points: (json['points'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$GameBadgeToJson(GameBadge instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'iconName': instance.iconName,
  'color': instance.color,
  'category': _$BadgeCategoryEnumMap[instance.category]!,
  'rarity': _$BadgeRarityEnumMap[instance.rarity]!,
  'criteria': instance.criteria,
  'points': instance.points,
  'createdAt': instance.createdAt.toIso8601String(),
  'isActive': instance.isActive,
};

const _$BadgeCategoryEnumMap = {
  BadgeCategory.achievement: 'achievement',
  BadgeCategory.streak: 'streak',
  BadgeCategory.accuracy: 'accuracy',
  BadgeCategory.participation: 'participation',
  BadgeCategory.milestone: 'milestone',
  BadgeCategory.special: 'special',
};

const _$BadgeRarityEnumMap = {
  BadgeRarity.common: 'common',
  BadgeRarity.uncommon: 'uncommon',
  BadgeRarity.rare: 'rare',
  BadgeRarity.epic: 'epic',
  BadgeRarity.legendary: 'legendary',
};

StudentBadge _$StudentBadgeFromJson(Map<String, dynamic> json) => StudentBadge(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  badgeId: json['badgeId'] as String,
  badge: GameBadge.fromJson(json['badge'] as Map<String, dynamic>),
  earnedAt: DateTime.parse(json['earnedAt'] as String),
  earnedCriteria: json['earnedCriteria'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$StudentBadgeToJson(StudentBadge instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'badgeId': instance.badgeId,
      'badge': instance.badge,
      'earnedAt': instance.earnedAt.toIso8601String(),
      'earnedCriteria': instance.earnedCriteria,
    };

ClassLeaderboard _$ClassLeaderboardFromJson(Map<String, dynamic> json) =>
    ClassLeaderboard(
      classCodeId: json['classCodeId'] as String,
      classCodeName: json['classCodeName'] as String,
      entries:
          (json['entries'] as List<dynamic>)
              .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      totalStudents: (json['totalStudents'] as num).toInt(),
      averageScore: (json['averageScore'] as num).toDouble(),
      totalQuizzes: (json['totalQuizzes'] as num).toInt(),
    );

Map<String, dynamic> _$ClassLeaderboardToJson(ClassLeaderboard instance) =>
    <String, dynamic>{
      'classCodeId': instance.classCodeId,
      'classCodeName': instance.classCodeName,
      'entries': instance.entries,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'totalStudents': instance.totalStudents,
      'averageScore': instance.averageScore,
      'totalQuizzes': instance.totalQuizzes,
    };

StudentStatistics _$StudentStatisticsFromJson(Map<String, dynamic> json) =>
    StudentStatistics(
      studentId: json['studentId'] as String,
      classCodeId: json['classCodeId'] as String,
      totalScore: (json['totalScore'] as num).toInt(),
      totalQuizzes: (json['totalQuizzes'] as num).toInt(),
      correctAnswers: (json['correctAnswers'] as num).toInt(),
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      accuracy: (json['accuracy'] as num).toDouble(),
      currentStreak: (json['currentStreak'] as num).toInt(),
      longestStreak: (json['longestStreak'] as num).toInt(),
      badges:
          (json['badges'] as List<dynamic>)
              .map((e) => StudentBadge.fromJson(e as Map<String, dynamic>))
              .toList(),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      subjectScores: Map<String, int>.from(json['subjectScores'] as Map),
      rank: (json['rank'] as num).toInt(),
      totalStudentsInClass: (json['totalStudentsInClass'] as num).toInt(),
    );

Map<String, dynamic> _$StudentStatisticsToJson(StudentStatistics instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'classCodeId': instance.classCodeId,
      'totalScore': instance.totalScore,
      'totalQuizzes': instance.totalQuizzes,
      'correctAnswers': instance.correctAnswers,
      'totalQuestions': instance.totalQuestions,
      'accuracy': instance.accuracy,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'badges': instance.badges,
      'lastActivity': instance.lastActivity.toIso8601String(),
      'subjectScores': instance.subjectScores,
      'rank': instance.rank,
      'totalStudentsInClass': instance.totalStudentsInClass,
    };
