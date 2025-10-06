import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/student_progress_models.dart';
import '../models/task_models.dart';
import '../models/admin_models.dart';

// Simple QuerySnapshot implementation for fallback scenarios
class _SimpleQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;
  
  _SimpleQuerySnapshot(this._docs);
  
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;
  
  @override
  int get size => _docs.length;
  
  bool get isEmpty => _docs.isEmpty;
  
  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => [];
  
  @override
  SnapshotMetadata get metadata => _SimpleSnapshotMetadata();
}

// Simple SnapshotMetadata implementation
class _SimpleSnapshotMetadata implements SnapshotMetadata {
  @override
  bool get hasPendingWrites => false;
  
  @override
  bool get isFromCache => false;
}

class StudentProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive learning progress for a student
  Future<StudentLearningProgress?> getStudentProgress(String studentId) async {
    try {
      if (kDebugMode) {
        print('=== StudentProgressService: Getting progress for student $studentId ===');
      }

      // Get student basic info
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) {
        if (kDebugMode) {
          print('Student not found: $studentId');
        }
        return null;
      }

      final studentData = studentDoc.data()!;
      final classCodeId = studentData['classCodeId'] as String;
      final schoolId = studentData['schoolId'] as String;

      // Get quiz attempts
      final quizAttempts = await _getQuizAttempts(studentId);
      
      // Get task submissions
      final taskSubmissions = await _getTaskSubmissions(studentId);
      
      // Get assigned tasks
      final assignedTasks = await _getAssignedTasks(classCodeId);
      
      // Get subject progress
      final subjectProgress = await _calculateSubjectProgress(studentId, classCodeId);
      
      // Get weekly activity
      final weeklyActivity = await _calculateWeeklyActivity(studentId);
      
      // Get achievements and badges
      final achievements = await _getAchievements(studentId);
      final badges = await _getBadges(studentId);

      // Calculate overall statistics using helper method
      final quizStats = await _calculateQuizStats(quizAttempts);
      final totalQuizQuestions = quizStats['totalQuestions'] ?? 0;
      final totalCorrectAnswers = quizStats['correctAnswers'] ?? 0;
      final totalQuizPoints = quizAttempts.fold<int>(0, (total, attempt) => total + (attempt.totalScore?.toInt() ?? 0));
      
      final overallAccuracy = totalQuizQuestions > 0 ? (totalCorrectAnswers / totalQuizQuestions) * 100 : 0.0;
      final averageQuizScore = quizAttempts.isNotEmpty ? totalQuizPoints / quizAttempts.length : 0.0;
      
      final completedTasks = taskSubmissions.length;
      final onTimeTasks = taskSubmissions.where((s) => !s.isLate).length;
      final taskCompletionRate = assignedTasks.isNotEmpty ? (completedTasks / assignedTasks.length) * 100 : 0.0;

      // Calculate streaks
      final streaks = _calculateStreaks(weeklyActivity);
      
      // Calculate total learning time
      final totalLearningTime = weeklyActivity.fold<int>(0, (total, activity) => total + activity.learningTimeMinutes);
      final averageDailyTime = weeklyActivity.isNotEmpty ? totalLearningTime / weeklyActivity.length : 0.0;

      final progress = StudentLearningProgress(
        studentId: studentId,
        classCodeId: classCodeId,
        schoolId: schoolId,
        lastUpdated: DateTime.now(),
        totalPoints: totalQuizPoints,
        overallAccuracy: overallAccuracy,
        currentStreak: streaks['current'] ?? 0,
        longestStreak: streaks['longest'] ?? 0,
        totalActiveDays: weeklyActivity.where((a) => a.isActive).length,
        totalQuizzesCompleted: quizAttempts.length,
        totalQuizQuestions: totalQuizQuestions,
        totalCorrectAnswers: totalCorrectAnswers,
        averageQuizScore: averageQuizScore,
        totalTasksAssigned: assignedTasks.length,
        totalTasksCompleted: completedTasks,
        totalTasksOnTime: onTimeTasks,
        taskCompletionRate: taskCompletionRate,
        subjectProgress: subjectProgress,
        weeklyActivity: weeklyActivity,
        earnedBadges: badges,
        achievements: achievements,
        totalLearningTimeMinutes: totalLearningTime,
        averageDailyLearningTime: averageDailyTime,
      );

      if (kDebugMode) {
        print('Progress calculated successfully for student $studentId');
      }

      return progress;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting student progress: $e');
      }
      return null;
    }
  }

  /// Get quiz attempts for a student
  Future<List<StudentQuizAttempt>> _getQuizAttempts(String studentId) async {
    try {
      final query = await _firestore
          .collection('student_quiz_attempts')
          .where('studentId', isEqualTo: studentId)
          .where('isCompleted', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return StudentQuizAttempt.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting quiz attempts: $e');
      }
      return [];
    }
  }

  /// Get task submissions for a student
  Future<List<TaskSubmission>> _getTaskSubmissions(String studentId) async {
    try {
      final query = await _firestore
          .collection('task_submissions')
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .orderBy('submissionDate', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TaskSubmission.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting task submissions: $e');
      }
      // Return empty list instead of throwing error to prevent UI crashes
      return [];
    }
  }

  /// Get assigned tasks for a class
  Future<List<Task>> _getAssignedTasks(String classCodeId) async {
    try {
      // Get task classes for this class
      final taskClassesQuery = await _firestore
          .collection('task_classes')
          .where('classId', isEqualTo: classCodeId)
          .get();

      final taskIds = taskClassesQuery.docs.map((doc) => doc.data()['taskId'] as String).toList();

      if (taskIds.isEmpty) return [];

      final tasks = <Task>[];
      for (final taskId in taskIds) {
        final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
        if (taskDoc.exists) {
          final data = taskDoc.data()!;
          data['id'] = taskDoc.id;
          tasks.add(Task.fromJson(data));
        }
      }

      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting assigned tasks: $e');
      }
      return [];
    }
  }

  /// Calculate subject-wise progress
  Future<Map<String, SubjectProgress>> _calculateSubjectProgress(String studentId, String classCodeId) async {
    try {
      final subjectProgressMap = <String, SubjectProgress>{};

      // Get all subjects for the class
      final subjectsQuery = await _firestore.collection('subjects').get();
      
      for (final subjectDoc in subjectsQuery.docs) {
        final subjectData = subjectDoc.data();
        final subjectId = subjectDoc.id;
        final subjectName = subjectData['name'] as String;

        // Get quiz attempts for this subject
        final quizAttempts = await _getQuizAttemptsBySubject(studentId, subjectId);
        
        // Get task submissions for this subject
        final taskSubmissions = await _getTaskSubmissionsBySubject(studentId, subjectId);
        
        // Get assigned tasks for this subject
        final assignedTasks = await _getAssignedTasksBySubject(classCodeId, subjectId);

        if (quizAttempts.isNotEmpty || taskSubmissions.isNotEmpty || assignedTasks.isNotEmpty) {
          final totalQuizzes = await _getTotalQuizzesBySubject(subjectId, classCodeId);
          final averageScore = quizAttempts.isNotEmpty 
            ? quizAttempts.fold<double>(0, (total, attempt) => total + (attempt.totalScore ?? 0)) / quizAttempts.length
            : 0.0;
          
          // Calculate quiz statistics using helper method
          final quizStats = await _calculateQuizStats(quizAttempts);
          final totalQuestions = quizStats['totalQuestions'] ?? 0;
          final correctAnswers = quizStats['correctAnswers'] ?? 0;
          final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
          
          final totalPoints = quizAttempts.fold<int>(0, (total, attempt) => total + (attempt.totalScore?.toInt() ?? 0));
          
          final lastActivity = _getLastActivityDate(quizAttempts, taskSubmissions);

          subjectProgressMap[subjectId] = SubjectProgress(
            subjectId: subjectId,
            subjectName: subjectName,
            totalQuizzes: totalQuizzes,
            completedQuizzes: quizAttempts.length,
            averageScore: averageScore,
            totalTasks: assignedTasks.length,
            completedTasks: taskSubmissions.length,
            totalPoints: totalPoints,
            accuracy: accuracy,
            lastActivity: lastActivity,
          );
        }
      }

      return subjectProgressMap;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating subject progress: $e');
      }
      return {};
    }
  }

  /// Get quiz attempts by subject
  Future<List<StudentQuizAttempt>> _getQuizAttemptsBySubject(String studentId, String subjectId) async {
    try {
      // First get quizzes for this subject
      final quizzesQuery = await _firestore
          .collection('admin_quizzes')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      final quizIds = quizzesQuery.docs.map((doc) => doc.id).toList();
      if (quizIds.isEmpty) return [];

      final attempts = <StudentQuizAttempt>[];
      for (final quizId in quizIds) {
        final attemptQuery = await _firestore
            .collection('student_quiz_attempts')
            .where('studentId', isEqualTo: studentId)
            .where('quizId', isEqualTo: quizId)
            .where('isCompleted', isEqualTo: true)
            .get();

        for (final doc in attemptQuery.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          attempts.add(StudentQuizAttempt.fromJson(data));
        }
      }

      return attempts;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting quiz attempts by subject: $e');
      }
      return [];
    }
  }

  /// Get task submissions by subject
  Future<List<TaskSubmission>> _getTaskSubmissionsBySubject(String studentId, String subjectId) async {
    try {
      // First get tasks for this subject
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      final taskIds = tasksQuery.docs.map((doc) => doc.id).toList();
      if (taskIds.isEmpty) return [];

      final submissions = <TaskSubmission>[];
      for (final taskId in taskIds) {
        final submissionQuery = await _firestore
            .collection('task_submissions')
            .where('studentId', isEqualTo: studentId)
            .where('taskId', isEqualTo: taskId)
            .where('isActive', isEqualTo: true)
            .get();

        for (final doc in submissionQuery.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          submissions.add(TaskSubmission.fromJson(data));
        }
      }

      return submissions;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting task submissions by subject: $e');
      }
      return [];
    }
  }

  /// Get assigned tasks by subject
  Future<List<Task>> _getAssignedTasksBySubject(String classCodeId, String subjectId) async {
    try {
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('subjectId', isEqualTo: subjectId)
          .get();

      final tasks = <Task>[];
      for (final taskDoc in tasksQuery.docs) {
        // Check if task is assigned to this class
        final taskClassQuery = await _firestore
            .collection('task_classes')
            .where('taskId', isEqualTo: taskDoc.id)
            .where('classId', isEqualTo: classCodeId)
            .get();

        if (taskClassQuery.docs.isNotEmpty) {
          final data = taskDoc.data();
          data['id'] = taskDoc.id;
          tasks.add(Task.fromJson(data));
        }
      }

      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting assigned tasks by subject: $e');
      }
      return [];
    }
  }

  /// Get total quizzes by subject
  Future<int> _getTotalQuizzesBySubject(String subjectId, String classCodeId) async {
    try {
      final query = await _firestore
          .collection('admin_quizzes')
          .where('subjectId', isEqualTo: subjectId)
          .where('classCodeId', isEqualTo: classCodeId)
          .where('isPublished', isEqualTo: true)
          .get();

      return query.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting total quizzes by subject: $e');
      }
      return 0;
    }
  }

  /// Calculate weekly activity
  Future<List<DailyActivity>> _calculateWeeklyActivity(String studentId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final activities = <DailyActivity>[];

      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        // Get quiz attempts for this day
        final quizAttempts = await _firestore
            .collection('student_quiz_attempts')
            .where('studentId', isEqualTo: studentId)
            .where('completedAt', isGreaterThanOrEqualTo: startOfDay)
            .where('completedAt', isLessThan: endOfDay)
            .where('isCompleted', isEqualTo: true)
            .get();

        // Get task submissions for this day with improved error handling
        QuerySnapshot taskSubmissions;
        try {
          taskSubmissions = await _firestore
              .collection('task_submissions')
              .where('studentId', isEqualTo: studentId)
              .where('submissionDate', isGreaterThanOrEqualTo: startOfDay)
              .where('submissionDate', isLessThan: endOfDay)
              .get();
        } catch (indexError) {
          if (kDebugMode) {
            print('Index error for task submissions query, using fallback: $indexError');
          }
          // Fallback: get all submissions for student and filter in memory
          taskSubmissions = await _firestore
              .collection('task_submissions')
              .where('studentId', isEqualTo: studentId)
              .get();
          
          // Filter in memory for the specific date range
          final filteredDocs = taskSubmissions.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            DateTime? submissionDate;
            
            // Handle both Timestamp and String types for submissionDate
            final submissionDateField = data['submissionDate'];
            if (submissionDateField is Timestamp) {
              submissionDate = submissionDateField.toDate();
            } else if (submissionDateField is String) {
              try {
                submissionDate = DateTime.parse(submissionDateField);
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing submissionDate string: $e');
                }
                return false;
              }
            }
            
            return submissionDate != null && 
                   submissionDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   submissionDate.isBefore(endOfDay);
          }).toList();
          
          taskSubmissions = _createQuerySnapshotFromDocs(filteredDocs);
        }

        final pointsEarned = quizAttempts.docs.fold<int>(0, (total, doc) {
          final data = doc.data();
          return total + (data['totalScore'] as int? ?? 0);
        });

        final learningTime = quizAttempts.docs.fold<int>(0, (total, doc) {
          final data = doc.data();
          return total + (data['timeSpent'] as int? ?? 0);
        }) ~/ 60; // Convert to minutes

        final subjectsStudied = <String>{};
        for (final doc in quizAttempts.docs) {
          final quizId = doc.data()['quizId'] as String;
          final quizDoc = await _firestore.collection('admin_quizzes').doc(quizId).get();
          if (quizDoc.exists) {
            final subjectId = quizDoc.data()?['subjectId'] as String?;
            if (subjectId != null) {
              final subjectDoc = await _firestore.collection('subjects').doc(subjectId).get();
              if (subjectDoc.exists) {
                subjectsStudied.add(subjectDoc.data()?['name'] as String? ?? 'Unknown');
              }
            }
          }
        }

        activities.add(DailyActivity(
          date: startOfDay,
          quizzesCompleted: quizAttempts.docs.length,
          tasksCompleted: taskSubmissions.docs.length,
          pointsEarned: pointsEarned,
          learningTimeMinutes: learningTime,
          subjectsStudied: subjectsStudied.toList(),
        ));
      }

      return activities;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating weekly activity: $e');
      }
      // Return empty list instead of throwing error to prevent UI crashes
      return [];
    }
  }

  // Helper method to create QuerySnapshot from filtered docs
  QuerySnapshot<Map<String, dynamic>> _createQuerySnapshotFromDocs(List<QueryDocumentSnapshot> docs) {
    // Cast the docs to the correct type
    final typedDocs = docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>();
    return _SimpleQuerySnapshot(typedDocs);
  }

  /// Get achievements for a student
  Future<List<Achievement>> _getAchievements(String studentId) async {
    try {
      // This would typically come from a dedicated achievements collection
      // For now, we'll return an empty list as achievements system needs to be implemented
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting achievements: $e');
      }
      return [];
    }
  }

  /// Get badges for a student
  Future<List<String>> _getBadges(String studentId) async {
    try {
      // Get from leaderboard service or dedicated badges collection
      final studentStats = await _firestore
          .collection('student_statistics')
          .doc(studentId)
          .get();

      if (studentStats.exists) {
        final data = studentStats.data()!;
        final badges = data['badges'] as List<dynamic>? ?? [];
        return badges.map((badge) => badge['id'] as String).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting badges: $e');
      }
      return [];
    }
  }

  /// Calculate streaks
  Map<String, int> _calculateStreaks(List<DailyActivity> activities) {
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // Sort activities by date (most recent first)
    final sortedActivities = List<DailyActivity>.from(activities);
    sortedActivities.sort((a, b) => b.date.compareTo(a.date));

    // Calculate current streak (from most recent day backwards)
    for (int i = 0; i < sortedActivities.length; i++) {
      if (sortedActivities[i].isActive) {
        if (i == 0 || _isConsecutiveDay(sortedActivities[i].date, sortedActivities[i - 1].date)) {
          currentStreak++;
        } else {
          break;
        }
      } else if (i == 0) {
        break; // If today is not active, current streak is 0
      }
    }

    // Calculate longest streak
    for (final activity in sortedActivities.reversed) {
      if (activity.isActive) {
        tempStreak++;
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
      } else {
        tempStreak = 0;
      }
    }

    return {
      'current': currentStreak,
      'longest': longestStreak,
    };
  }

  /// Check if two dates are consecutive days
  bool _isConsecutiveDay(DateTime date1, DateTime date2) {
    final diff = date2.difference(date1).inDays;
    return diff == 1;
  }

  /// Get last activity date from quiz attempts and task submissions
  DateTime _getLastActivityDate(List<StudentQuizAttempt> quizAttempts, List<TaskSubmission> taskSubmissions) {
    DateTime lastActivity = DateTime.now().subtract(const Duration(days: 365)); // Default to a year ago

    if (quizAttempts.isNotEmpty) {
      final lastQuizActivity = quizAttempts.map((a) => a.completedAt).reduce((a, b) => a!.isAfter(b!) ? a : b);
      if (lastQuizActivity != null && lastQuizActivity.isAfter(lastActivity)) {
        lastActivity = lastQuizActivity;
      }
    }

    if (taskSubmissions.isNotEmpty) {
      final lastTaskActivity = taskSubmissions.map((s) => s.submissionDate).reduce((a, b) => a.isAfter(b) ? a : b);
      if (lastTaskActivity.isAfter(lastActivity)) {
        lastActivity = lastTaskActivity;
      }
    }

    return lastActivity;
  }

  /// Get weekly progress summary
  Future<WeeklyProgressSummary> getWeeklyProgressSummary(String studentId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final dailyActivities = await _calculateWeeklyActivity(studentId);
      
      final totalActiveDays = dailyActivities.where((a) => a.isActive).length;
      final totalQuizzesCompleted = dailyActivities.fold<int>(0, (total, a) => total + a.quizzesCompleted);
      final totalTasksCompleted = dailyActivities.fold<int>(0, (total, a) => total + a.tasksCompleted);
      final totalPointsEarned = dailyActivities.fold<int>(0, (total, a) => total + a.pointsEarned);
      final totalLearningTime = dailyActivities.fold<int>(0, (total, a) => total + a.learningTimeMinutes);

      // Get task submissions for this week (for future use)
      // final taskSubmissions = await _getTaskSubmissionsForWeek(studentId, weekStart, weekEnd);
      
      // Calculate average accuracy from quiz attempts this week
      final quizAttempts = await _getQuizAttemptsForWeek(studentId, weekStart, weekEnd);
      final quizStats = await _calculateQuizStats(quizAttempts);
      final totalQuestions = quizStats['totalQuestions'] ?? 0;
      final correctAnswers = quizStats['correctAnswers'] ?? 0;
      final averageAccuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

      // Get most studied subjects
      final allSubjects = dailyActivities.expand((a) => a.subjectsStudied).toList();
      final subjectCounts = <String, int>{};
      for (final subject in allSubjects) {
        subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
      }
      final mostStudiedSubjects = subjectCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

      return WeeklyProgressSummary(
        weekStart: weekStart,
        weekEnd: weekEnd,
        totalActiveDays: totalActiveDays,
        totalQuizzesCompleted: totalQuizzesCompleted,
        totalTasksCompleted: totalTasksCompleted,
        totalPointsEarned: totalPointsEarned,
        totalLearningTimeMinutes: totalLearningTime,
        averageAccuracy: averageAccuracy,
        mostStudiedSubjects: mostStudiedSubjects.take(3).map((e) => e.key).toList(),
        dailyActivities: dailyActivities,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting weekly progress summary: $e');
      }
      return WeeklyProgressSummary(
        weekStart: DateTime.now(),
        weekEnd: DateTime.now(),
        dailyActivities: [],
      );
    }
  }

  /// Get quiz attempts for a specific week
  Future<List<StudentQuizAttempt>> _getQuizAttemptsForWeek(String studentId, DateTime weekStart, DateTime weekEnd) async {
    try {
      final query = await _firestore
          .collection('student_quiz_attempts')
          .where('studentId', isEqualTo: studentId)
          .where('isCompleted', isEqualTo: true)
          .where('completedAt', isGreaterThanOrEqualTo: weekStart.toIso8601String())
          .where('completedAt', isLessThanOrEqualTo: weekEnd.toIso8601String())
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Parse dates safely
        if (data['startedAt'] is String) {
          data['startedAt'] = DateTime.parse(data['startedAt']);
        }
        if (data['completedAt'] is String) {
          data['completedAt'] = DateTime.parse(data['completedAt']);
        }
        
        return StudentQuizAttempt.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting quiz attempts for week: $e');
      }
      return [];
    }
  }

  /// Get task submissions for a specific week (currently unused but kept for future use)
  // ignore: unused_element
  Future<List<TaskSubmission>> _getTaskSubmissionsForWeek(String studentId, DateTime weekStart, DateTime weekEnd) async {
    try {
      final query = await _firestore
          .collection('task_submissions')
          .where('studentId', isEqualTo: studentId)
          .where('submittedAt', isGreaterThanOrEqualTo: weekStart.toIso8601String())
          .where('submittedAt', isLessThanOrEqualTo: weekEnd.toIso8601String())
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Parse dates safely
        if (data['submittedAt'] is String) {
          data['submittedAt'] = DateTime.parse(data['submittedAt']);
        }
        
        return TaskSubmission.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting task submissions for week: $e');
      }
      return [];
    }
  }

  /// Calculate total questions and correct answers from quiz attempts
  Future<Map<String, int>> _calculateQuizStats(List<StudentQuizAttempt> attempts) async {
    int totalQuestions = 0;
    int correctAnswers = 0;
    
    for (final attempt in attempts) {
      // Count questions from answers
      totalQuestions += attempt.answers.length;
      
      // Count correct answers
      for (final answer in attempt.answers.values) {
        if (answer.isCorrect == true) {
          correctAnswers++;
        }
      }
    }
    
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
    };
  }
}