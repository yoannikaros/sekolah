import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chapter_models.dart';

class ChapterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== CHAPTER CRUD OPERATIONS ====================

  /// Create a new chapter
  Future<String?> createChapter(Chapter chapter) async {
    try {
      final chapterData = {
        'title': chapter.title,
        'description': chapter.description,
        'subjectName': chapter.subjectName,
        'classCode': chapter.classCode,
        'createdAt': chapter.createdAt.toIso8601String(),
        'updatedAt': chapter.updatedAt.toIso8601String(),
        'isActive': chapter.isActive,
        'sortOrder': chapter.sortOrder,
      };
      
      final docRef = await _firestore.collection('chapters').add(chapterData);
      if (kDebugMode) {
        print('Chapter created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating chapter: $e');
      }
      return null;
    }
  }

  /// Update an existing chapter
  Future<bool> updateChapter(String id, Chapter chapter) async {
    try {
      final chapterData = {
        'title': chapter.title,
        'description': chapter.description,
        'subjectName': chapter.subjectName,
        'classCode': chapter.classCode,
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': chapter.isActive,
        'sortOrder': chapter.sortOrder,
      };
      
      await _firestore.collection('chapters').doc(id).update(chapterData);
      if (kDebugMode) {
        print('Chapter updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating chapter: $e');
      }
      return false;
    }
  }

  /// Delete a chapter (soft delete)
  Future<bool> deleteChapter(String id) async {
    try {
      await _firestore.collection('chapters').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Chapter deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting chapter: $e');
      }
      return false;
    }
  }

  /// Get all active chapters
  Future<List<Chapter>> getAllChapters() async {
    try {
      if (kDebugMode) {
        print('ChapterService: Starting to fetch chapters from Firestore...');
      }
      
      // First, try to get all chapters without ordering constraints
      final querySnapshot = await _firestore
          .collection('chapters')
          .where('isActive', isEqualTo: true)
          .get();

      if (kDebugMode) {
        print('ChapterService: Found ${querySnapshot.docs.length} chapters in Firestore');
      }

      final chapters = <Chapter>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          // Ensure document ID is properly set
          data['id'] = doc.id;
          
          if (kDebugMode) {
            print('ChapterService: Processing chapter ${doc.id}');
            print('ChapterService: Raw data: $data');
            print('ChapterService: Document ID set to: ${data['id']}');
          }
          
          // Validate that document ID is not empty
          if (doc.id.isEmpty) {
            if (kDebugMode) {
              print('ChapterService: ERROR - Document ID is empty! Skipping chapter.');
            }
            continue;
          }
          
          final chapter = Chapter.fromJson(data);
          
          // Double-check that the chapter ID is properly set
          if (chapter.id.isEmpty) {
            if (kDebugMode) {
              print('ChapterService: WARNING - Chapter ID is empty after parsing! Document ID: ${doc.id}');
            }
            continue; // Skip this chapter if ID is empty
          }
          
          chapters.add(chapter);
          
          if (kDebugMode) {
            print('ChapterService: Successfully parsed chapter: ${chapter.title} with ID: ${chapter.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('ChapterService: Error parsing chapter ${doc.id}: $e');
            print('ChapterService: Chapter data: ${doc.data()}');
          }
          // Continue processing other chapters even if one fails
          continue;
        }
      }

      // Sort chapters manually
      chapters.sort((a, b) {
        // First sort by sortOrder if available
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        }
        // Then by createdAt (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });

      if (kDebugMode) {
        print('ChapterService: Successfully parsed ${chapters.length} chapters');
        for (final chapter in chapters) {
          print('  - ${chapter.title} (${chapter.subjectName} - ${chapter.classCode})');
        }
      }

      return chapters;
    } catch (e) {
      if (kDebugMode) {
        print('ChapterService: Error getting chapters: $e');
        print('ChapterService: Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  /// Get chapter by ID
  Future<Chapter?> getChapterById(String id) async {
    try {
      final doc = await _firestore.collection('chapters').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Chapter.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chapter by ID: $e');
      }
      return null;
    }
  }

  /// Get chapters by subject and class
  Future<List<Chapter>> getChaptersBySubjectAndClass(String subjectName, String classCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('chapters')
          .where('isActive', isEqualTo: true)
          .where('subjectName', isEqualTo: subjectName)
          .where('classCode', isEqualTo: classCode)
          .orderBy('sortOrder')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Chapter.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chapters by subject and class: $e');
      }
      return [];
    }
  }

  // ==================== QUIZ CRUD OPERATIONS ====================

  /// Create a new quiz
  Future<String?> createQuiz(Quiz quiz) async {
    try {
      final quizData = {
        'chapterId': quiz.chapterId,
        'title': quiz.title,
        'createdDate': quiz.createdDate.toIso8601String(),
        'startDateTime': quiz.startDateTime.toIso8601String(),
        'endDateTime': quiz.endDateTime.toIso8601String(),
        'isActive': quiz.isActive,
        'totalQuestions': quiz.totalQuestions ?? 0,
        'totalPoints': quiz.totalPoints ?? 0,
      };
      
      final docRef = await _firestore.collection('quizzes').add(quizData);
      if (kDebugMode) {
        print('Quiz created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating quiz: $e');
      }
      return null;
    }
  }

  /// Update an existing quiz
  Future<bool> updateQuiz(String id, Quiz quiz) async {
    try {
      final quizData = {
        'chapterId': quiz.chapterId,
        'title': quiz.title,
        'createdDate': quiz.createdDate.toIso8601String(),
        'startDateTime': quiz.startDateTime.toIso8601String(),
        'endDateTime': quiz.endDateTime.toIso8601String(),
        'isActive': quiz.isActive,
        'totalQuestions': quiz.totalQuestions ?? 0,
        'totalPoints': quiz.totalPoints ?? 0,
      };
      
      await _firestore.collection('quizzes').doc(id).update(quizData);
      if (kDebugMode) {
        print('Quiz updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating quiz: $e');
      }
      return false;
    }
  }

  /// Delete a quiz (soft delete)
  Future<bool> deleteQuiz(String id) async {
    try {
      await _firestore.collection('quizzes').doc(id).update({
        'isActive': false,
      });
      if (kDebugMode) {
        print('Quiz deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting quiz: $e');
      }
      return false;
    }
  }

  /// Get quizzes by chapter ID
  Future<List<Quiz>> getQuizzesByChapterId(String chapterId) async {
    try {
      if (kDebugMode) {
        print('ChapterService: Starting to fetch quizzes for chapter $chapterId...');
      }
      
      // First, try to get all quizzes without ordering constraints
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('isActive', isEqualTo: true)
          .where('chapterId', isEqualTo: chapterId)
          .get();

      if (kDebugMode) {
        print('ChapterService: Found ${querySnapshot.docs.length} quizzes in Firestore for chapter $chapterId');
      }

      final quizzes = <Quiz>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          // Ensure document ID is properly set
          data['id'] = doc.id;
          
          if (kDebugMode) {
            print('ChapterService: Processing quiz ${doc.id}');
            print('ChapterService: Raw quiz data: $data');
            print('ChapterService: Document ID set to: ${data['id']}');
            print('ChapterService: ChapterId in data: ${data['chapterId']}');
          }
          
          final quiz = Quiz.fromJson(data);
          
          // Double-check that the quiz has proper IDs
          if (quiz.id.isEmpty) {
            if (kDebugMode) {
              print('ChapterService: WARNING - Quiz ID is empty after parsing! Document ID: ${doc.id}');
            }
            continue; // Skip this quiz if ID is empty
          }
          
          if (quiz.chapterId.isEmpty) {
            if (kDebugMode) {
              print('ChapterService: WARNING - Quiz chapterId is empty! Quiz ID: ${quiz.id}');
            }
            continue; // Skip this quiz if chapterId is empty
          }
          
          quizzes.add(quiz);
          
          if (kDebugMode) {
            print('ChapterService: Successfully parsed quiz: ${quiz.title} with ID: ${quiz.id} and chapterId: ${quiz.chapterId}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('ChapterService: Error parsing quiz ${doc.id}: $e');
            print('ChapterService: Quiz data: ${doc.data()}');
          }
        }
      }

      // Sort quizzes manually by createdDate (newest first)
      quizzes.sort((a, b) => b.createdDate.compareTo(a.createdDate));

      if (kDebugMode) {
        print('ChapterService: Successfully parsed ${quizzes.length} quizzes for chapter $chapterId');
        for (final quiz in quizzes) {
          print('  - ${quiz.title} (${quiz.startDateTime} - ${quiz.endDateTime})');
        }
      }

      return quizzes;
    } catch (e) {
      if (kDebugMode) {
        print('ChapterService: Error getting quizzes by chapter ID: $e');
        print('ChapterService: Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  /// Get quiz by ID
  Future<Quiz?> getQuizById(String id) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Quiz.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting quiz by ID: $e');
      }
      return null;
    }
  }

  // ==================== QUESTION CRUD OPERATIONS ====================

  /// Create a new question
  Future<String?> createQuestion(Question question) async {
    try {
      final questionData = {
        'quizId': question.quizId,
        'questionText': question.questionText,
        'questionType': question.questionType.name,
        'multipleChoiceOptions': question.multipleChoiceOptions?.map((option) => option.toJson()).toList(),
        'essayKeyAnswer': question.essayKeyAnswer,
        'points': question.points,
        'orderNumber': question.orderNumber,
        'createdAt': question.createdAt.toIso8601String(),
        'updatedAt': question.updatedAt.toIso8601String(),
        'isActive': question.isActive,
      };
      
      final docRef = await _firestore.collection('questions').add(questionData);
      
      // Update quiz total questions and points
      await _updateQuizTotals(question.quizId);
      
      if (kDebugMode) {
        print('Question created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating question: $e');
      }
      return null;
    }
  }

  /// Update an existing question
  Future<bool> updateQuestion(String id, Question question) async {
    try {
      final questionData = {
        'quizId': question.quizId,
        'questionText': question.questionText,
        'questionType': question.questionType.name,
        'multipleChoiceOptions': question.multipleChoiceOptions?.map((option) => option.toJson()).toList(),
        'essayKeyAnswer': question.essayKeyAnswer,
        'points': question.points,
        'orderNumber': question.orderNumber,
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': question.isActive,
      };
      
      await _firestore.collection('questions').doc(id).update(questionData);
      
      // Update quiz total questions and points
      await _updateQuizTotals(question.quizId);
      
      if (kDebugMode) {
        print('Question updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating question: $e');
      }
      return false;
    }
  }

  /// Delete a question (soft delete)
  Future<bool> deleteQuestion(String id) async {
    try {
      // Get question first to get quizId for updating totals
      final questionDoc = await _firestore.collection('questions').doc(id).get();
      if (!questionDoc.exists) return false;
      
      final quizId = questionDoc.data()!['quizId'] as String;
      
      await _firestore.collection('questions').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Update quiz total questions and points
      await _updateQuizTotals(quizId);
      
      if (kDebugMode) {
        print('Question deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting question: $e');
      }
      return false;
    }
  }

  /// Get questions by quiz ID
  Future<List<Question>> getQuestionsByQuizId(String quizId) async {
    try {
      if (kDebugMode) {
        print('ChapterService: Starting to fetch questions for quiz $quizId...');
      }
      
      // First, try to get all questions without ordering constraints
      final querySnapshot = await _firestore
          .collection('questions')
          .where('isActive', isEqualTo: true)
          .where('quizId', isEqualTo: quizId)
          .get();

      if (kDebugMode) {
        print('ChapterService: Found ${querySnapshot.docs.length} questions in Firestore for quiz $quizId');
      }

      final questions = <Question>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          if (kDebugMode) {
            print('ChapterService: Processing question ${doc.id}');
            print('ChapterService: Raw question data: $data');
            print('ChapterService: multipleChoiceOptions field: ${data['multipleChoiceOptions']}');
            print('ChapterService: multipleChoiceOptions type: ${data['multipleChoiceOptions'].runtimeType}');
            if (data['multipleChoiceOptions'] != null) {
              print('ChapterService: multipleChoiceOptions length: ${(data['multipleChoiceOptions'] as List).length}');
              for (int i = 0; i < (data['multipleChoiceOptions'] as List).length; i++) {
                final option = (data['multipleChoiceOptions'] as List)[i];
                print('ChapterService: Option $i: $option');
              }
            }
          }
          
          final question = Question.fromJson(data);
          
          if (kDebugMode) {
            print('ChapterService: Parsed question multipleChoiceOptions: ${question.multipleChoiceOptions}');
            if (question.multipleChoiceOptions != null) {
              print('ChapterService: Parsed options count: ${question.multipleChoiceOptions!.length}');
              for (int i = 0; i < question.multipleChoiceOptions!.length; i++) {
                final option = question.multipleChoiceOptions![i];
                print('ChapterService: Parsed option $i: id=${option.id}, label=${option.optionLabel}, text="${option.optionText}", isCorrect=${option.isCorrect}');
              }
            }
          }
          
          questions.add(question);
          
          if (kDebugMode) {
            print('ChapterService: Successfully parsed question: ${question.questionText.substring(0, question.questionText.length > 50 ? 50 : question.questionText.length)}...');
          }
        } catch (e) {
          if (kDebugMode) {
            print('ChapterService: Error parsing question ${doc.id}: $e');
            print('ChapterService: Question data: ${doc.data()}');
          }
        }
      }

      // Sort questions manually by orderNumber, then by createdAt
      questions.sort((a, b) {
        final orderComparison = (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0);
        if (orderComparison != 0) return orderComparison;
        return a.createdAt.compareTo(b.createdAt);
      });

      if (kDebugMode) {
        print('ChapterService: Successfully parsed ${questions.length} questions for quiz $quizId');
        for (final question in questions) {
          print('  - Order ${question.orderNumber}: ${question.questionText.substring(0, question.questionText.length > 30 ? 30 : question.questionText.length)}...');
        }
      }

      return questions;
    } catch (e) {
      if (kDebugMode) {
        print('ChapterService: Error getting questions by quiz ID: $e');
        print('ChapterService: Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  /// Get question by ID
  Future<Question?> getQuestionById(String id) async {
    try {
      final doc = await _firestore.collection('questions').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Question.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting question by ID: $e');
      }
      return null;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Update quiz totals (total questions and points)
  Future<void> _updateQuizTotals(String quizId) async {
    try {
      final questions = await getQuestionsByQuizId(quizId);
      final totalQuestions = questions.length;
      final totalPoints = questions.fold<int>(0, (total, question) => total + question.points);
      
      await _firestore.collection('quizzes').doc(quizId).update({
        'totalQuestions': totalQuestions,
        'totalPoints': totalPoints,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating quiz totals: $e');
      }
    }
  }

  // ==================== SUMMARY METHODS ====================

  /// Get chapter summary with totals
  Future<ChapterSummary> getChapterSummary(String chapterId) async {
    try {
      final chapterDoc = await _firestore.collection('chapters').doc(chapterId).get();
      if (!chapterDoc.exists) {
        throw Exception('Chapter not found');
      }

      final chapter = Chapter.fromJson(chapterDoc.data()!);
      
      final quizzesSnapshot = await _firestore
          .collection('quizzes')
          .where('chapterId', isEqualTo: chapterId)
          .get();

      final totalQuizzes = quizzesSnapshot.docs.length;
      final totalQuestions = quizzesSnapshot.docs.fold<int>(0, (total, doc) {
        final quiz = Quiz.fromJson(doc.data());
        return total + (quiz.totalQuestions ?? 0);
      });
      final totalPoints = quizzesSnapshot.docs.fold<int>(0, (total, doc) {
        final quiz = Quiz.fromJson(doc.data());
        return total + (quiz.totalPoints ?? 0);
      });

      return ChapterSummary(
        chapter: chapter,
        totalQuizzes: totalQuizzes,
        totalQuestions: totalQuestions,
        totalPoints: totalPoints,
      );
    } catch (e) {
      throw Exception('Failed to get chapter summary: $e');
    }
  }

  /// Get quiz summary with chapter info
  Future<QuizSummary> getQuizSummary(String quizId) async {
    try {
      final quizDoc = await _firestore.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) {
        throw Exception('Quiz not found');
      }

      final quiz = Quiz.fromJson(quizDoc.data()!);
      
      // Get chapter info
      final chapterDoc = await _firestore.collection('chapters').doc(quiz.chapterId).get();
      if (!chapterDoc.exists) {
        throw Exception('Chapter not found');
      }
      final chapter = Chapter.fromJson(chapterDoc.data()!);
      
      final questionsSnapshot = await _firestore
          .collection('questions')
          .where('quizId', isEqualTo: quizId)
          .get();

      final totalQuestions = questionsSnapshot.docs.length;
      final totalPoints = questionsSnapshot.docs.fold<int>(0, (total, doc) {
        final question = Question.fromJson(doc.data());
        return total + question.points;
      });

      return QuizSummary(
        quiz: quiz,
        chapter: chapter,
        totalQuestions: totalQuestions,
        totalPoints: totalPoints,
      );
    } catch (e) {
      throw Exception('Failed to get quiz summary: $e');
    }
  }

  /// Get all chapter summaries
  Future<List<ChapterSummary>> getAllChapterSummaries() async {
    try {
      final chapters = await getAllChapters();
      final summaries = <ChapterSummary>[];

      for (final chapter in chapters) {
        final summary = await getChapterSummary(chapter.id);
        summaries.add(summary);
      }

      return summaries;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all chapter summaries: $e');
      }
      return [];
    }
  }
}