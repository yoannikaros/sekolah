import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_models.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get leaderboard for a specific class
  Future<ClassLeaderboard?> getClassLeaderboard(String classCodeId) async {
    try {
      // Get class info
      final classDoc = await _firestore.collection('class_codes').doc(classCodeId).get();
      
      if (!classDoc.exists) return null;
      
      final className = classDoc.data()?['name'] as String? ?? 'Unknown Class';
      
      // Get students in the class
      final studentsQuery = await _firestore
          .collection('students')
          .where('classCodeId', isEqualTo: classCodeId)
          .where('isActive', isEqualTo: true)
          .get();
      
      final List<LeaderboardEntry> entries = [];
      
      for (var studentDoc in studentsQuery.docs) {
        final studentData = studentDoc.data();
        final studentId = studentDoc.id;
        final studentName = studentData['name'] as String? ?? 'Unknown';
        final profileImageUrl = studentData['profileImageUrl'] as String?;
        
        // Get quiz attempts for this student
        final attemptsQuery = await _firestore
            .collection('student_quiz_attempts')
            .where('studentId', isEqualTo: studentId)
            .where('isCompleted', isEqualTo: true)
            .get();
        
        int totalScore = 0;
        int totalQuizzes = attemptsQuery.docs.length;
        int correctAnswers = 0;
        int totalQuestions = 0;
        DateTime? lastActivity;
        
        for (var attemptDoc in attemptsQuery.docs) {
          final attemptData = attemptDoc.data();
          totalScore += (attemptData['totalScore'] as int?) ?? 0;
          
          // Parse answers to count correct ones
          final answers = attemptData['answers'] as Map<String, dynamic>? ?? {};
          for (var answer in answers.values) {
            if (answer is Map<String, dynamic>) {
              totalQuestions++;
              if (answer['isCorrect'] == true) {
                correctAnswers++;
              }
            }
          }
          
          // Track last activity
          final completedAt = attemptData['completedAt'];
          if (completedAt is String) {
            final activityDate = DateTime.parse(completedAt);
            if (lastActivity == null || activityDate.isAfter(lastActivity)) {
              lastActivity = activityDate;
            }
          }
        }
        
        final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
        
        // Get student badges
        final badgesQuery = await _firestore
            .collection('student_badges')
            .where('studentId', isEqualTo: studentId)
            .get();
        
        final earnedBadgeIds = badgesQuery.docs.map((doc) => doc.data()['badgeId'] as String).toList();
        
        entries.add(LeaderboardEntry(
          studentId: studentId,
          studentName: studentName,
          classCodeId: classCodeId,
          classCodeName: className,
          totalScore: totalScore,
          totalQuizzes: totalQuizzes,
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
          accuracy: accuracy,
          streak: 0, // TODO: Calculate streak
          earnedBadgeIds: earnedBadgeIds,
          lastActivity: lastActivity ?? DateTime.now(),
          rank: 0, // Will be set after sorting
          profileImageUrl: profileImageUrl,
        ));
      }
      
      // Sort by total score and assign ranks
      entries.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      for (int i = 0; i < entries.length; i++) {
        entries[i] = LeaderboardEntry(
          studentId: entries[i].studentId,
          studentName: entries[i].studentName,
          classCodeId: entries[i].classCodeId,
          classCodeName: entries[i].classCodeName,
          totalScore: entries[i].totalScore,
          totalQuizzes: entries[i].totalQuizzes,
          correctAnswers: entries[i].correctAnswers,
          totalQuestions: entries[i].totalQuestions,
          accuracy: entries[i].accuracy,
          streak: entries[i].streak,
          earnedBadgeIds: entries[i].earnedBadgeIds,
          lastActivity: entries[i].lastActivity,
          rank: i + 1,
          profileImageUrl: entries[i].profileImageUrl,
        );
      }
      
      return ClassLeaderboard(
        classCodeId: classCodeId,
        classCodeName: className,
        entries: entries,
        totalStudents: entries.length,
        lastUpdated: DateTime.now(),
        averageScore: entries.isNotEmpty 
            ? entries.map((e) => e.totalScore).reduce((a, b) => a + b) / entries.length 
            : 0.0,
        totalQuizzes: entries.isNotEmpty 
            ? entries.map((e) => e.totalQuizzes).reduce((a, b) => a > b ? a : b) 
            : 0,
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('Error getting class leaderboard: $e');
      }
      return null;
    }
  }

  // Get available badges
  Future<List<GameBadge>> getAvailableBadges() async {
    try {
      final querySnapshot = await _firestore
          .collection('game_badges')
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .orderBy('rarity')
          .get();
      
      final badges = <GameBadge>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse enum values
          data['category'] = BadgeCategory.values.firstWhere(
            (e) => e.toString().split('.').last == data['category'],
            orElse: () => BadgeCategory.achievement,
          );
          data['rarity'] = BadgeRarity.values.firstWhere(
            (e) => e.toString().split('.').last == data['rarity'],
            orElse: () => BadgeRarity.common,
          );
          
          // Parse dates
          if (data['createdAt'] is String) {
            data['createdAt'] = DateTime.parse(data['createdAt']);
          }
          
          final badge = GameBadge.fromJson(data);
          badges.add(badge);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing badge document ${doc.id}: $e');
          }
        }
      }
      
      return badges;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available badges: $e');
      }
      return [];
    }
  }

  // Get student badges
  Future<List<StudentBadge>> getStudentBadges(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('student_badges')
          .where('studentId', isEqualTo: studentId)
          .orderBy('earnedAt', descending: true)
          .get();
      
      final studentBadges = <StudentBadge>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse dates
          if (data['earnedAt'] is String) {
            data['earnedAt'] = DateTime.parse(data['earnedAt']);
          }
          
          // Get badge details
          final badgeDoc = await _firestore
              .collection('game_badges')
              .doc(data['badgeId'])
              .get();
          
          if (badgeDoc.exists) {
            final badgeData = badgeDoc.data()!;
            badgeData['id'] = badgeDoc.id;
            
            // Parse enum values for badge
            badgeData['category'] = BadgeCategory.values.firstWhere(
              (e) => e.toString().split('.').last == badgeData['category'],
              orElse: () => BadgeCategory.achievement,
            );
            badgeData['rarity'] = BadgeRarity.values.firstWhere(
              (e) => e.toString().split('.').last == badgeData['rarity'],
              orElse: () => BadgeRarity.common,
            );
            
            // Parse dates for badge
            if (badgeData['createdAt'] is String) {
              badgeData['createdAt'] = DateTime.parse(badgeData['createdAt']);
            }
            
            final badge = GameBadge.fromJson(badgeData);
            
            final studentBadge = StudentBadge(
              id: data['id'] as String,
              studentId: data['studentId'] as String,
              badgeId: data['badgeId'] as String,
              earnedAt: data['earnedAt'] as DateTime,
              badge: badge,
              earnedCriteria: data['earnedCriteria'] != null
                  ? Map<String, dynamic>.from(data['earnedCriteria'] as Map)
                  : null,
            );
            
            studentBadges.add(studentBadge);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing student badge document ${doc.id}: $e');
          }
        }
      }
      
      return studentBadges;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting student badges: $e');
      }
      return [];
    }
  }

  // Get student statistics
  Future<StudentStatistics?> getStudentStatistics(String studentId) async {
    try {
      // Get student basic info
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      
      if (!studentDoc.exists) return null;
      
      final studentData = studentDoc.data()!;
      final classCodeId = studentData['classCodeId'] as String;
      
      // Get quiz attempts for this student
      final attemptsQuery = await _firestore
          .collection('student_quiz_attempts')
          .where('studentId', isEqualTo: studentId)
          .where('isCompleted', isEqualTo: true)
          .get();
      
      int totalScore = 0;
      int totalQuizzes = attemptsQuery.docs.length;
      int correctAnswers = 0;
      int totalQuestions = 0;
      DateTime? lastActivity;
      
      for (var attemptDoc in attemptsQuery.docs) {
        final attemptData = attemptDoc.data();
        totalScore += (attemptData['totalScore'] as int?) ?? 0;
        
        // Parse answers to count correct ones
        final answers = attemptData['answers'] as Map<String, dynamic>? ?? {};
        for (var answer in answers.values) {
          if (answer is Map<String, dynamic>) {
            totalQuestions++;
            if (answer['isCorrect'] == true) {
              correctAnswers++;
            }
          }
        }
        
        // Track last activity
        final completedAt = attemptData['completedAt'];
        if (completedAt is String) {
          final activityDate = DateTime.parse(completedAt);
          if (lastActivity == null || activityDate.isAfter(lastActivity)) {
            lastActivity = activityDate;
          }
        }
      }
      
      final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
      
      // Get student badges
      final badges = await getStudentBadges(studentId);
      
      // Calculate rank in class
      final classLeaderboard = await getClassLeaderboard(classCodeId);
      int rank = 1;
      if (classLeaderboard != null) {
        final entry = classLeaderboard.entries.firstWhere(
          (e) => e.studentId == studentId,
          orElse: () => classLeaderboard.entries.first,
        );
        rank = entry.rank;
      }
      
      return StudentStatistics(
        studentId: studentId,
        classCodeId: classCodeId,
        totalScore: totalScore,
        totalQuizzes: totalQuizzes,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        accuracy: accuracy,
        currentStreak: 0, // TODO: Calculate streak
        longestStreak: 0, // TODO: Calculate longest streak
        badges: badges,
        rank: rank,
        lastActivity: lastActivity ?? DateTime.now(),
        subjectScores: {}, // TODO: Implement subject scores
        totalStudentsInClass: classLeaderboard?.totalStudents ?? 1,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting student statistics: $e');
      }
      return null;
    }
  }

  // Save quiz result to Firebase
  Future<bool> saveQuizResult({
    required String studentId,
    required String quizId,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required DateTime completionTime,
    required List<dynamic> answers, // UserAnswer list
  }) async {
    try {
      // Convert UserAnswer objects to Map for Firebase
      final answersMap = <String, Map<String, dynamic>>{};
      for (int i = 0; i < answers.length; i++) {
        final answer = answers[i];
        if (answer is Map<String, dynamic>) {
          answersMap['question_$i'] = answer;
        } else {
          // If it's a UserAnswer object, convert to map
          answersMap['question_$i'] = {
            'questionId': answer.questionId ?? '',
            'selectedAnswerIndex': answer.selectedAnswerIndex ?? -1,
            'isCorrect': answer.isCorrect ?? false,
            'timeSpent': answer.timeSpent ?? 0,
          };
        }
      }

      // Save to student_quiz_attempts collection
      final attemptData = {
        'studentId': studentId,
        'quizId': quizId,
        'totalScore': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'completedAt': completionTime.toIso8601String(),
        'answers': answersMap,
        'isCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('student_quiz_attempts').add(attemptData);
      
      if (kDebugMode) {
        print('Quiz result saved successfully for student: $studentId, quiz: $quizId');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving quiz result: $e');
      }
      return false;
    }
  }

  // Initialize default badges
  Future<void> initializeDefaultBadges() async {
    try {
      // Check if badges already exist
      final existingBadges = await _firestore.collection('game_badges').limit(1).get();
      if (existingBadges.docs.isNotEmpty) {
        if (kDebugMode) {
          print('Badges already initialized');
        }
        return;
      }
      
      final defaultBadges = [
        {
          'name': 'Pemula',
          'description': 'Menyelesaikan quiz pertama',
          'iconName': 'star',
          'color': '#4CAF50',
          'category': 'milestone',
          'rarity': 'common',
          'criteria': {'quizzes_completed': 1},
          'points': 10,
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
        {
          'name': 'Sempurna',
          'description': 'Mendapat skor 100% dalam quiz',
          'iconName': 'emoji_events',
          'color': '#FFD700',
          'category': 'achievement',
          'rarity': 'rare',
          'criteria': {'perfect_scores': 1},
          'points': 50,
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
        {
          'name': 'Konsisten',
          'description': 'Mengerjakan quiz 7 hari berturut-turut',
          'iconName': 'local_fire_department',
          'color': '#FF5722',
          'category': 'streak',
          'rarity': 'uncommon',
          'criteria': {'streak_days': 7},
          'points': 30,
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
        {
          'name': 'Akurat',
          'description': 'Mempertahankan akurasi 90% dalam 10 quiz',
          'iconName': 'gps_fixed',
          'color': '#2196F3',
          'category': 'accuracy',
          'rarity': 'epic',
          'criteria': {'accuracy': 90, 'min_quizzes': 10},
          'points': 75,
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      ];
      
      for (final badge in defaultBadges) {
        await _firestore.collection('game_badges').add(badge);
      }
      
      if (kDebugMode) {
        print('Default badges initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing default badges: $e');
      }
    }
  }
}