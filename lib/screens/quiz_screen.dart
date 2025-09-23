import 'package:flutter/material.dart';
import 'package:sekangkatanapp/screens/quiz/quiz_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/quiz_service.dart';
import '../models/quiz_models.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String classCodeId;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.classCodeId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  final List<UserAnswer> _userAnswers = [];
  Timer? _timer;
  int _timeRemaining = 0;
  int _questionStartTime = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  
  late AnimationController _progressController;
  late AnimationController _questionController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadQuestions();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _quizService.getQuestionsByIds(widget.quiz.questionIds);
      setState(() {
        _questions = questions;
        _timeRemaining = widget.quiz.timeLimit * 60; // Convert to seconds
        _questionStartTime = DateTime.now().millisecondsSinceEpoch;
        _isLoading = false;
      });
      
      _startTimer();
      _questionController.forward();
      _updateProgress();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  void _updateProgress() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    _progressController.animateTo(progress);
  }

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswerIndex = index;
    });
  }

  Future<void> _nextQuestion() async {
    if (_selectedAnswerIndex == null) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final timeSpent = (DateTime.now().millisecondsSinceEpoch - _questionStartTime) ~/ 1000;
    
    final userAnswer = UserAnswer(
      questionId: currentQuestion.id,
      selectedAnswerIndex: _selectedAnswerIndex!,
      isCorrect: _selectedAnswerIndex == currentQuestion.correctAnswerIndex,
      timeSpent: timeSpent,
    );

    _userAnswers.add(userAnswer);

    if (_currentQuestionIndex < _questions.length - 1) {
      // Move to next question
      await _questionController.reverse();
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _questionStartTime = DateTime.now().millisecondsSinceEpoch;
      });
      _updateProgress();
      await _questionController.forward();
    } else {
      // Quiz completed
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'default_user';
      
      final correctAnswers = _userAnswers.where((answer) => answer.isCorrect).length;
      final totalTimeSpent = widget.quiz.timeLimit * 60 - _timeRemaining;
      final score = (correctAnswers / _questions.length * widget.quiz.totalPoints).round();

      final quizResult = QuizResult(
        quizId: widget.quiz.id,
        score: score,
        totalQuestions: _questions.length,
        correctAnswers: correctAnswers,
        timeSpent: totalTimeSpent,
        completedAt: DateTime.now(),
        answers: _userAnswers,
      );

      await _quizService.saveQuizResult(userId, widget.classCodeId, quizResult);
      final newBadges = await _quizService.checkAndAwardBadges(userId, widget.classCodeId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              result: quizResult,
              questions: _questions,
              newBadges: newBadges,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting quiz: $e')),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimeColor() {
    if (_timeRemaining > 300) return Colors.green; // > 5 minutes
    if (_timeRemaining > 60) return Colors.orange;  // > 1 minute
    return Colors.red; // < 1 minute
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.blue.shade50,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat soal...'),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Tidak ada soal tersedia'),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress and timer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Keluar Quiz'),
                              content: const Text('Apakah Anda yakin ingin keluar? Progress akan hilang.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Keluar'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.close),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getTimeColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: _getTimeColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(_timeRemaining),
                              style: TextStyle(
                                color: _getTimeColor(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${((_currentQuestionIndex + 1) / _questions.length * 100).round()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                            minHeight: 6,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Question content
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentQuestion.imageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  currentQuestion.imageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              currentQuestion.question,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Answer options
                      Expanded(
                        child: ListView.builder(
                          itemCount: currentQuestion.options.length,
                          itemBuilder: (context, index) {
                            final isSelected = _selectedAnswerIndex == index;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _selectAnswer(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue.shade600 : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected ? Colors.white : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected ? Colors.white : Colors.grey.shade400,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + index), // A, B, C, D
                                            style: TextStyle(
                                              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          currentQuestion.options[index],
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Next button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAnswerIndex != null && !_isSubmitting ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _currentQuestionIndex == _questions.length - 1 ? 'Selesai' : 'Lanjut',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _questionController.dispose();
    super.dispose();
  }
}