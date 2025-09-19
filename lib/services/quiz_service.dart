import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz.dart';
import 'api_service.dart';

class QuizService {
  static const String baseUrl = 'http://localhost:3000/api';
  final ApiService _apiService = ApiService();

  // Get headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get all quizzes with optional filters
  Future<ApiResponse<List<Quiz>>> getQuizzes({
    String? category,
    String? difficulty,
    int? classId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (classId != null) queryParams['class_id'] = classId.toString();

      final uri = Uri.parse('$baseUrl/quizzes').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final quizzes = (data['quizzes'] as List)
            .map((quiz) => Quiz.fromJson(quiz as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<Quiz>>(
          success: true,
          message: 'Quizzes retrieved successfully',
          data: quizzes,
        );
      } else {
        return ApiResponse<List<Quiz>>(
          success: false,
          message: data['error'] as String? ?? 'Failed to get quizzes',
        );
      }
    } catch (e) {
      return ApiResponse<List<Quiz>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Create new quiz
  Future<ApiResponse<Quiz>> createQuiz({
    required String title,
    String? description,
    required String category,
    required String difficulty,
    int? timeLimit,
    required int classId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'difficulty': difficulty,
          'time_limit': timeLimit,
          'class_id': classId,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Quiz>(
          success: true,
          message: data['message'] as String? ?? 'Quiz created successfully',
          data: Quiz.fromJson(data['quiz'] as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<Quiz>(
          success: false,
          message: data['error'] as String? ?? 'Failed to create quiz',
        );
      }
    } catch (e) {
      return ApiResponse<Quiz>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get quiz details with questions
  Future<ApiResponse<QuizWithQuestions>> getQuizDetails(int quizId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quizzes/$quizId'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final quiz = Quiz.fromJson(data['quiz'] as Map<String, dynamic>);
        final questions = (data['questions'] as List)
            .map((question) => QuizQuestion.fromJson(question as Map<String, dynamic>))
            .toList();

        return ApiResponse<QuizWithQuestions>(
          success: true,
          message: 'Quiz details retrieved successfully',
          data: QuizWithQuestions(quiz: quiz, questions: questions),
        );
      } else {
        return ApiResponse<QuizWithQuestions>(
          success: false,
          message: data['error'] as String? ?? 'Failed to get quiz details',
        );
      }
    } catch (e) {
      return ApiResponse<QuizWithQuestions>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Start quiz attempt
  Future<ApiResponse<QuizAttemptStart>> startQuizAttempt(int quizId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/$quizId/start'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final attemptId = data['attempt_id'] as int;
        final quiz = Quiz.fromJson(data['quiz'] as Map<String, dynamic>);
        final questions = (data['quiz']['questions'] as List)
            .map((question) => QuizQuestion.fromJson(question as Map<String, dynamic>))
            .toList();

        return ApiResponse<QuizAttemptStart>(
          success: true,
          message: 'Quiz attempt started successfully',
          data: QuizAttemptStart(
            attemptId: attemptId,
            quiz: quiz,
            questions: questions,
          ),
        );
      } else {
        return ApiResponse<QuizAttemptStart>(
          success: false,
          message: data['error'] as String? ?? 'Failed to start quiz attempt',
        );
      }
    } catch (e) {
      return ApiResponse<QuizAttemptStart>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Submit answer for a question
  Future<ApiResponse<void>> submitAnswer({
    required int quizId,
    required int attemptId,
    required int questionId,
    required String answer,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/$quizId/answer'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'attempt_id': attemptId,
          'question_id': questionId,
          'answer': answer,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: data['message'] as String? ?? 'Answer submitted successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: data['error'] as String? ?? 'Failed to submit answer',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Complete quiz and get results
  Future<ApiResponse<QuizResult>> completeQuiz({
    required int quizId,
    required int attemptId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/$quizId/complete'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'attempt_id': attemptId,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final result = QuizResult.fromJson(data['result'] as Map<String, dynamic>);
        
        return ApiResponse<QuizResult>(
          success: true,
          message: 'Quiz completed successfully',
          data: result,
        );
      } else {
        return ApiResponse<QuizResult>(
          success: false,
          message: data['error'] as String? ?? 'Failed to complete quiz',
        );
      }
    } catch (e) {
      return ApiResponse<QuizResult>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Update quiz
  Future<ApiResponse<Quiz>> updateQuiz({
    required int quizId,
    required String title,
    String? description,
    required String category,
    required String difficulty,
    int? timeLimit,
    required int classId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/quizzes/$quizId'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'difficulty': difficulty,
          'time_limit': timeLimit,
          'class_id': classId,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse<Quiz>(
          success: true,
          message: data['message'] as String? ?? 'Quiz updated successfully',
          data: Quiz.fromJson(data['quiz'] as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<Quiz>(
          success: false,
          message: data['error'] as String? ?? 'Failed to update quiz',
        );
      }
    } catch (e) {
      return ApiResponse<Quiz>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Delete quiz
  Future<ApiResponse<void>> deleteQuiz(int quizId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/quizzes/$quizId'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: data['message'] as String? ?? 'Quiz deleted successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: data['error'] as String? ?? 'Failed to delete quiz',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Add question to quiz
  Future<ApiResponse<QuizQuestion>> addQuestion({
    required int quizId,
    required String question,
    required String type,
    List<String>? options,
    required String correctAnswer,
    int points = 1,
    String? explanation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/quizzes/$quizId/questions'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'question': question,
          'type': type,
          'options': options,
          'correct_answer': correctAnswer,
          'points': points,
          'explanation': explanation,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<QuizQuestion>(
          success: true,
          message: data['message'] as String? ?? 'Question added successfully',
          data: QuizQuestion.fromJson(data['question'] as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<QuizQuestion>(
          success: false,
          message: data['error'] as String? ?? 'Failed to add question',
        );
      }
    } catch (e) {
      return ApiResponse<QuizQuestion>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get quiz attempts for a student
  Future<ApiResponse<List<QuizAttempt>>> getQuizAttempts({
    int? studentId,
    int? quizId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (studentId != null) queryParams['student_id'] = studentId.toString();
      if (quizId != null) queryParams['quiz_id'] = quizId.toString();

      final uri = Uri.parse('$baseUrl/quiz-attempts').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final attempts = (data['attempts'] as List)
            .map((attempt) => QuizAttempt.fromJson(attempt as Map<String, dynamic>))
            .toList();

        return ApiResponse<List<QuizAttempt>>(
          success: true,
          message: 'Quiz attempts retrieved successfully',
          data: attempts,
        );
      } else {
        return ApiResponse<List<QuizAttempt>>(
          success: false,
          message: data['error'] as String? ?? 'Failed to get quiz attempts',
        );
      }
    } catch (e) {
      return ApiResponse<List<QuizAttempt>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}

// Helper classes for complex responses
class QuizWithQuestions {
  final Quiz quiz;
  final List<QuizQuestion> questions;

  QuizWithQuestions({
    required this.quiz,
    required this.questions,
  });
}

class QuizAttemptStart {
  final int attemptId;
  final Quiz quiz;
  final List<QuizQuestion> questions;

  QuizAttemptStart({
    required this.attemptId,
    required this.quiz,
    required this.questions,
  });
}