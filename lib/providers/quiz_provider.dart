import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/quiz.dart';
import '../services/quiz_service.dart';
import '../services/api_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuizService _quizService = QuizService();

  // State variables
  List<Quiz> _quizzes = [];
  Quiz? _currentQuiz;
  List<QuizQuestion> _currentQuestions = [];
  QuizAttempt? _currentAttempt;
  QuizResult? _lastResult;
  List<QuizAttempt> _userAttempts = [];
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingQuizzes = false;
  bool _isLoadingQuizDetails = false;
  bool _isSubmittingAnswer = false;
  bool _isCompletingQuiz = false;
  
  // Error states
  String? _error;
  String? _quizError;
  
  // Quiz taking state
  int _currentQuestionIndex = 0;
  Map<int, String> _userAnswers = {};
  Timer? _quizTimer;
  int _timeRemaining = 0; // in seconds
  bool _isQuizActive = false;
  
  // Filters
  String? _selectedCategory;
  String? _selectedDifficulty;
  int? _selectedClassId;

  // Getters
  List<Quiz> get quizzes => _quizzes;
  Quiz? get currentQuiz => _currentQuiz;
  List<QuizQuestion> get currentQuestions => _currentQuestions;
  QuizAttempt? get currentAttempt => _currentAttempt;
  QuizResult? get lastResult => _lastResult;
  List<QuizAttempt> get userAttempts => _userAttempts;
  
  bool get isLoading => _isLoading;
  bool get isLoadingQuizzes => _isLoadingQuizzes;
  bool get isLoadingQuizDetails => _isLoadingQuizDetails;
  bool get isSubmittingAnswer => _isSubmittingAnswer;
  bool get isCompletingQuiz => _isCompletingQuiz;
  
  String? get error => _error;
  String? get quizError => _quizError;
  
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, String> get userAnswers => _userAnswers;
  int get timeRemaining => _timeRemaining;
  bool get isQuizActive => _isQuizActive;
  
  String? get selectedCategory => _selectedCategory;
  String? get selectedDifficulty => _selectedDifficulty;
  int? get selectedClassId => _selectedClassId;

  // Get current question
  QuizQuestion? get currentQuestion {
    if (_currentQuestions.isEmpty || _currentQuestionIndex >= _currentQuestions.length) {
      return null;
    }
    return _currentQuestions[_currentQuestionIndex];
  }

  // Get quiz progress
  double get quizProgress {
    if (_currentQuestions.isEmpty) return 0.0;
    return (_currentQuestionIndex + 1) / _currentQuestions.length;
  }

  // Get answered questions count
  int get answeredQuestionsCount => _userAnswers.length;

  // Check if current question is answered
  bool get isCurrentQuestionAnswered {
    final question = currentQuestion;
    if (question == null) return false;
    return _userAnswers.containsKey(question.id);
  }

  // Clear error
  void clearError() {
    _error = null;
    _quizError = null;
    notifyListeners();
  }

  // Set filters
  void setFilters({
    String? category,
    String? difficulty,
    int? classId,
  }) {
    _selectedCategory = category;
    _selectedDifficulty = difficulty;
    _selectedClassId = classId;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedDifficulty = null;
    _selectedClassId = null;
    notifyListeners();
  }

  // Load quizzes with optional filters
  Future<void> loadQuizzes({
    String? category,
    String? difficulty,
    int? classId,
    bool refresh = false,
  }) async {
    if (_isLoadingQuizzes && !refresh) return;

    _isLoadingQuizzes = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _quizService.getQuizzes(
        category: category ?? _selectedCategory,
        difficulty: difficulty ?? _selectedDifficulty,
        classId: classId ?? _selectedClassId,
      );

      if (response.success && response.data != null) {
        _quizzes = response.data!;
      } else {
        _error = response.message ?? 'Failed to load quizzes';
      }
    } catch (e) {
      _error = 'Error loading quizzes: $e';
    } finally {
      _isLoadingQuizzes = false;
      notifyListeners();
    }
  }

  // Load quiz details
  Future<void> loadQuizDetails(int quizId) async {
    _isLoadingQuizDetails = true;
    _quizError = null;
    notifyListeners();

    try {
      final response = await _quizService.getQuizDetails(quizId);

      if (response.success && response.data != null) {
        _currentQuiz = response.data!.quiz;
        _currentQuestions = response.data!.questions;
      } else {
        _quizError = response.message ?? 'Failed to load quiz details';
      }
    } catch (e) {
      _quizError = 'Error loading quiz details: $e';
    } finally {
      _isLoadingQuizDetails = false;
      notifyListeners();
    }
  }

  // Start quiz attempt
  Future<bool> startQuizAttempt(int quizId) async {
    _isLoading = true;
    _quizError = null;
    notifyListeners();

    try {
      final response = await _quizService.startQuizAttempt(quizId);

      if (response.success && response.data != null) {
        _currentAttempt = QuizAttempt(
          id: response.data!.attemptId,
          quizId: quizId,
          studentId: 0, // Will be set by backend
          totalScore: 0,
          maxScore: response.data!.questions.fold(0, (sum, q) => sum + q.points),
          percentage: 0.0,
          timeSpent: 0,
          createdAt: DateTime.now(),
        );
        
        _currentQuiz = response.data!.quiz;
        _currentQuestions = response.data!.questions;
        _currentQuestionIndex = 0;
        _userAnswers.clear();
        _isQuizActive = true;
        
        // Start timer if quiz has time limit
        if (_currentQuiz!.timeLimit > 0) {
          _timeRemaining = _currentQuiz!.timeLimit * 60; // Convert to seconds
          _startTimer();
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _quizError = response.message ?? 'Failed to start quiz';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _quizError = 'Error starting quiz: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Start quiz timer
  void _startTimer() {
    _quizTimer?.cancel();
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        _autoCompleteQuiz();
      }
    });
  }

  // Auto complete quiz when time runs out
  Future<void> _autoCompleteQuiz() async {
    if (_currentAttempt != null) {
      await completeQuiz();
    }
  }

  // Submit answer for current question
  Future<bool> submitAnswer(String answer) async {
    final question = currentQuestion;
    final attempt = _currentAttempt;
    
    if (question == null || attempt == null || !_isQuizActive) {
      return false;
    }

    _isSubmittingAnswer = true;
    notifyListeners();

    try {
      final response = await _quizService.submitAnswer(
        quizId: _currentQuiz!.id,
        attemptId: attempt.id,
        questionId: question.id,
        answer: answer,
      );

      if (response.success) {
        _userAnswers[question.id] = answer;
        _isSubmittingAnswer = false;
        notifyListeners();
        return true;
      } else {
        _quizError = response.message ?? 'Failed to submit answer';
        _isSubmittingAnswer = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _quizError = 'Error submitting answer: $e';
      _isSubmittingAnswer = false;
      notifyListeners();
      return false;
    }
  }

  // Go to next question
  void nextQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  // Go to previous question
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  // Go to specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < _currentQuestions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  // Complete quiz and get results
  Future<bool> completeQuiz() async {
    final attempt = _currentAttempt;
    if (attempt == null) return false;

    _isCompletingQuiz = true;
    _isQuizActive = false;
    _quizTimer?.cancel();
    notifyListeners();

    try {
      final response = await _quizService.completeQuiz(
        quizId: _currentQuiz!.id,
        attemptId: attempt.id,
      );

      if (response.success && response.data != null) {
        _lastResult = response.data!;
        _isCompletingQuiz = false;
        notifyListeners();
        return true;
      } else {
        _quizError = response.message ?? 'Failed to complete quiz';
        _isCompletingQuiz = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _quizError = 'Error completing quiz: $e';
      _isCompletingQuiz = false;
      notifyListeners();
      return false;
    }
  }

  // Reset quiz state
  void resetQuizState() {
    _currentQuiz = null;
    _currentQuestions.clear();
    _currentAttempt = null;
    _lastResult = null;
    _currentQuestionIndex = 0;
    _userAnswers.clear();
    _quizTimer?.cancel();
    _timeRemaining = 0;
    _isQuizActive = false;
    _quizError = null;
    notifyListeners();
  }

  // Load user quiz attempts
  Future<void> loadUserAttempts({int? studentId, int? quizId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _quizService.getQuizAttempts(
        studentId: studentId,
        quizId: quizId,
      );

      if (response.success && response.data != null) {
        _userAttempts = response.data!;
      } else {
        _error = response.message ?? 'Failed to load quiz attempts';
      }
    } catch (e) {
      _error = 'Error loading quiz attempts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new quiz (for teachers/admins)
  Future<bool> createQuiz({
    required String title,
    String? description,
    required String category,
    required String difficulty,
    int? timeLimit,
    required int classId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _quizService.createQuiz(
        title: title,
        description: description,
        category: category,
        difficulty: difficulty,
        timeLimit: timeLimit,
        classId: classId,
      );

      if (response.success && response.data != null) {
        _quizzes.insert(0, response.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to create quiz';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error creating quiz: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update quiz (for teachers/admins)
  Future<bool> updateQuiz({
    required int quizId,
    required String title,
    String? description,
    required String category,
    required String difficulty,
    int? timeLimit,
    required int classId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _quizService.updateQuiz(
        quizId: quizId,
        title: title,
        description: description,
        category: category,
        difficulty: difficulty,
        timeLimit: timeLimit,
        classId: classId,
      );

      if (response.success && response.data != null) {
        final index = _quizzes.indexWhere((quiz) => quiz.id == quizId);
        if (index != -1) {
          _quizzes[index] = response.data!;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to update quiz';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating quiz: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete quiz (for teachers/admins)
  Future<bool> deleteQuiz(int quizId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _quizService.deleteQuiz(quizId);

      if (response.success) {
        _quizzes.removeWhere((quiz) => quiz.id == quizId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Failed to delete quiz';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error deleting quiz: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _quizTimer?.cancel();
    super.dispose();
  }
}