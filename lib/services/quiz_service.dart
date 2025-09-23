import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/quiz_models.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Class Code operations
  Future<ClassCode?> validateClassCode(String code) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Searching for class code: $code');
      }
      final querySnapshot = await _firestore
          .collection('class_codes')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (kDebugMode) {
        print('DEBUG: Query result - Found ${querySnapshot.docs.length} documents');
      }
      
      if (querySnapshot.docs.isNotEmpty) {
        final docData = querySnapshot.docs.first.data();
        if (kDebugMode) {
          print('DEBUG: Document data: $docData');
        }
        
        // Add the document ID to the data
        final dataWithId = Map<String, dynamic>.from(docData);
        dataWithId['id'] = querySnapshot.docs.first.id;
        
        return ClassCode.fromJson(dataWithId);
      }
      
      // If not found with exact match, try case-insensitive search
      if (kDebugMode) {
        print('DEBUG: Trying case-insensitive search');
      }
      final allCodesSnapshot = await _firestore
          .collection('class_codes')
          .where('isActive', isEqualTo: true)
          .get();
      
      if (kDebugMode) {
        print('DEBUG: Found ${allCodesSnapshot.docs.length} active class codes');
      }
      
      for (final doc in allCodesSnapshot.docs) {
        final docData = doc.data();
        final docCode = docData['code']?.toString().toUpperCase();
        if (kDebugMode) {
          print('DEBUG: Checking code: $docCode against $code');
        }
        
        if (docCode == code.toUpperCase()) {
          final dataWithId = Map<String, dynamic>.from(docData);
          dataWithId['id'] = doc.id;
          return ClassCode.fromJson(dataWithId);
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error validating class code: $e');
      }
      return null;
    }
  }

  Future<List<ClassCode>> getClassCodes() async {
    try {
      final querySnapshot = await _firestore
          .collection('class_codes')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return ClassCode.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error getting class codes: $e');
      }
      return [];
    }
  }

  // Quiz operations
  Future<List<Quiz>> getQuizzesByClassCode(String classCodeId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Getting quizzes for class code ID: $classCodeId');
      }
      
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('classCodeId', isEqualTo: classCodeId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('DEBUG: Found ${querySnapshot.docs.length} quizzes');
      }

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Quiz.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error getting quizzes: $e');
      }
      return [];
    }
  }

  Future<Quiz?> getQuizById(String quizId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Getting quiz by ID: $quizId');
      }
      
      final doc = await _firestore.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        return Quiz.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error getting quiz: $e');
      }
      return null;
    }
  }

  Future<List<Quiz>> getQuizzesByCategory(String classCodeId, QuestionCategory category) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Getting quizzes by category: ${category.name} for class code: $classCodeId');
      }
      
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('classCodeId', isEqualTo: classCodeId)
          .where('category', isEqualTo: category.name)
          .where('isActive', isEqualTo: true)
          .get();

      if (kDebugMode) {
        print('DEBUG: Found ${querySnapshot.docs.length} quizzes for category ${category.name}');
      }

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Quiz.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error getting quizzes by category: $e');
      }
      return [];
    }
  }

  // Question operations
  Future<List<Question>> getQuestionsByIds(List<String> questionIds) async {
    try {
      if (questionIds.isEmpty) return [];

      if (kDebugMode) {
        print('DEBUG: Getting questions by IDs: $questionIds');
      }

      final querySnapshot = await _firestore
          .collection('questions')
          .where(FieldPath.documentId, whereIn: questionIds)
          .get();

      if (kDebugMode) {
        print('DEBUG: Found ${querySnapshot.docs.length} questions');
      }

      return querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Question.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error getting questions: $e');
      }
      return [];
    }
  }

  Future<Question?> getQuestionById(String questionId) async {
    try {
      if (kDebugMode) {
        print('DEBUG: Getting question by ID: $questionId');
      }
      
      final doc = await _firestore.collection('questions').doc(questionId).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        return Question.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error getting question: $e');
      }
      return null;
    }
  }

  // User Progress operations
  Future<UserProgress?> getUserProgress(String userId, String classCodeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .where('classCodeId', isEqualTo: classCodeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserProgress.fromJson(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      // Error getting user progress: $e
      return null;
    }
  }

  Future<bool> saveQuizResult(String userId, String classCodeId, QuizResult result) async {
    try {
      final progressDoc = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .where('classCodeId', isEqualTo: classCodeId)
          .limit(1)
          .get();

      if (progressDoc.docs.isNotEmpty) {
        // Update existing progress
        final docRef = progressDoc.docs.first.reference;
        final currentProgress = UserProgress.fromJson(progressDoc.docs.first.data());
        
        final updatedQuizResults = Map<String, QuizResult>.from(currentProgress.quizResults);
        updatedQuizResults[result.quizId] = result;

        final updatedProgress = UserProgress(
          id: currentProgress.id,
          userId: userId,
          classCodeId: classCodeId,
          quizResults: updatedQuizResults,
          earnedBadges: currentProgress.earnedBadges,
          totalPoints: currentProgress.totalPoints + result.score,
          streak: _calculateStreak(currentProgress, result),
          lastActivity: DateTime.now(),
          categoryProgress: _updateCategoryProgress(currentProgress.categoryProgress, result),
        );

        await docRef.update(updatedProgress.toJson());
      } else {
        // Create new progress
        final newProgress = UserProgress(
          id: _firestore.collection('user_progress').doc().id,
          userId: userId,
          classCodeId: classCodeId,
          quizResults: {result.quizId: result},
          totalPoints: result.score,
          streak: 1,
          lastActivity: DateTime.now(),
          categoryProgress: {},
        );

        await _firestore.collection('user_progress').add(newProgress.toJson());
      }
      return true;
    } catch (e) {
      // Error saving quiz result: $e
      return false;
    }
  }

  Future<List<Badge>> checkAndAwardBadges(String userId, String classCodeId) async {
    try {
      final progress = await getUserProgress(userId, classCodeId);
      if (progress == null) return [];

      final newBadges = <Badge>[];
      
      // Check for streak badges
      if (progress.streak >= 7 && !_hasBadge(progress.earnedBadges, 'streak_7')) {
        newBadges.add(Badge(
          id: 'streak_7',
          name: '7 Hari Berturut-turut',
          description: 'Menyelesaikan quiz selama 7 hari berturut-turut',
          iconUrl: 'assets/badges/streak_7.svg',
          type: BadgeType.streak,
          earnedAt: DateTime.now(),
        ));
      }

      // Check for category mastery badges
      for (final entry in progress.categoryProgress.entries) {
        if (entry.value.accuracy >= 0.8 && entry.value.totalQuestions >= 10) {
          final badgeId = 'master_${entry.key.name}';
          if (!_hasBadge(progress.earnedBadges, badgeId)) {
            newBadges.add(Badge(
              id: badgeId,
              name: 'Master ${_getCategoryName(entry.key)}',
              description: 'Mencapai akurasi 80% dalam kategori ${_getCategoryName(entry.key)}',
              iconUrl: 'assets/badges/$badgeId.svg',
              type: BadgeType.category,
              earnedAt: DateTime.now(),
            ));
          }
        }
      }

      // Save new badges
      if (newBadges.isNotEmpty) {
        final updatedBadges = [...progress.earnedBadges, ...newBadges];
        await _updateUserBadges(userId, classCodeId, updatedBadges);
      }

      return newBadges;
    } catch (e) {
      // Error checking badges: $e
      return [];
    }
  }

  // Helper methods
  int _calculateStreak(UserProgress currentProgress, QuizResult newResult) {
    final now = DateTime.now();
    final lastActivity = currentProgress.lastActivity;
    
    if (now.difference(lastActivity).inDays <= 1) {
      return currentProgress.streak + 1;
    } else {
      return 1;
    }
  }

  Map<QuestionCategory, CategoryProgress> _updateCategoryProgress(
    Map<QuestionCategory, CategoryProgress> currentProgress,
    QuizResult result,
  ) {
    // This would need quiz category information
    // For now, return the current progress
    return currentProgress;
  }

  bool _hasBadge(List<Badge> badges, String badgeId) {
    return badges.any((badge) => badge.id == badgeId);
  }

  String _getCategoryName(QuestionCategory category) {
    switch (category) {
      case QuestionCategory.reading:
        return 'Membaca';
      case QuestionCategory.writing:
        return 'Menulis';
      case QuestionCategory.math:
        return 'Matematika';
      case QuestionCategory.science:
        return 'Sains';
    }
  }

  Future<bool> _updateUserBadges(String userId, String classCodeId, List<Badge> badges) async {
    try {
      final progressDoc = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .where('classCodeId', isEqualTo: classCodeId)
          .limit(1)
          .get();

      if (progressDoc.docs.isNotEmpty) {
        await progressDoc.docs.first.reference.update({
          'earnedBadges': badges.map((badge) => badge.toJson()).toList(),
        });
      }
      return true;
    } catch (e) {
      // Error updating user badges: $e
      return false;
    }
  }
}