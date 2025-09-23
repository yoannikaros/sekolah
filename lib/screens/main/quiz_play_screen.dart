import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../../models/chapter_models.dart';
import '../../services/chapter_service.dart';
import '../../services/leaderboard_service.dart';
import 'quiz_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  final Quiz quiz;
  final Chapter chapter;

  const QuizPlayScreen({
    super.key,
    required this.quiz,
    required this.chapter,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with TickerProviderStateMixin {
  final ChapterService _chapterService = ChapterService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerSelected = false;
  bool _showCorrectAnswer = false;
  int _score = 0;
  int _correctAnswers = 0;
  final List<UserAnswer> _userAnswers = [];
  Timer? _timer;
  int _timeRemaining = 0;
  // int _questionStartTime = 0; // Unused field - commented out
  
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  late AnimationController _progressAnimationController;
  late AnimationController _questionAnimationController;
  late AnimationController _answerAnimationController;
  late AnimationController _celebrationController;
  
  late Animation<double> _progressAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late Animation<double> _questionFadeAnimation;
  late Animation<double> _answerScaleAnimation;

  // Mock questions for demonstration - REMOVED, now using Firebase data

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final questions = await _chapterService.getQuestionsByQuizId(widget.quiz.id);
      
      if (questions.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Tidak ada soal yang tersedia untuk quiz ini.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _questions = questions;
        _isLoading = false;
      });

      // Start timer and animations after questions are loaded
      _startTimer();
      // _questionStartTime = DateTime.now().millisecondsSinceEpoch; // Unused
      _questionAnimationController.forward();
      _updateProgressAnimation();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Gagal memuat soal: $e';
        _isLoading = false;
      });
    }
  }

  void _initAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _answerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _questionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionAnimationController,
      curve: Curves.easeIn,
    ));

    _answerScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _answerAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _startTimer() {
    if (_questions.isEmpty) return;
    
    _timeRemaining = 30; // 30 seconds per question
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _timer?.cancel();
        if (!_isAnswerSelected) {
          _selectAnswer(null); // Auto-submit with no answer
        }
      }
    });
  }

  void _updateProgressAnimation() {
    if (_questions.isEmpty) return;
    
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    _progressAnimationController.animateTo(progress);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnimationController.dispose();
    _questionAnimationController.dispose();
    _answerAnimationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.quiz.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6c5ce7)),
              ),
              SizedBox(height: 16),
              Text(
                'Memuat soal...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.quiz.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.alertCircle,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Terjadi Kesalahan',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6c5ce7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Coba Lagi',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.quiz.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.fileQuestion,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak Ada Soal',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quiz ini belum memiliki soal.',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildQuestionContent(),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final minutes = _timeRemaining ~/ 60;
    final seconds = _timeRemaining % 60;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: Color(0xFF1E293B),
                  ),
                  onPressed: () => _showExitDialog(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeRemaining < 60 
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Skor: $_score',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    final currentQuestion = _questions[_currentQuestionIndex];
    
    return FadeTransition(
      opacity: _questionFadeAnimation,
      child: SlideTransition(
        position: _questionSlideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  currentQuestion.questionText,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion.multipleChoiceOptions?.length ?? 0,
                  itemBuilder: (context, index) {
                    return _buildAnswerOption(currentQuestion, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOption(Question question, int index) {
    final isSelected = _selectedAnswerIndex == index;
    final option = question.multipleChoiceOptions![index];
    final isCorrect = option.isCorrect;
    final showResult = _showCorrectAnswer;
    
    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF1E293B);
    
    if (showResult) {
      if (isCorrect) {
        backgroundColor = const Color(0xFF10B981);
        borderColor = const Color(0xFF10B981);
        textColor = Colors.white;
      } else if (isSelected && !isCorrect) {
        backgroundColor = const Color(0xFFEF4444);
        borderColor = const Color(0xFFEF4444);
        textColor = Colors.white;
      }
    } else if (isSelected) {
      backgroundColor = const Color(0xFF4F46E5).withValues(alpha: 0.1);
      borderColor = const Color(0xFF4F46E5);
      textColor = const Color(0xFF4F46E5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ScaleTransition(
        scale: isSelected ? _answerScaleAnimation : 
               const AlwaysStoppedAnimation(1.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isAnswerSelected ? null : () => _selectAnswer(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: showResult && isCorrect
                          ? Colors.white.withValues(alpha: 0.2)
                          : showResult && isSelected && !isCorrect
                              ? Colors.white.withValues(alpha: 0.2)
                              : isSelected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: showResult && (isCorrect || (isSelected && !isCorrect))
                              ? Colors.white
                              : isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                        option.optionText,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                  ),
                  if (showResult && isCorrect)
                    const Icon(
                      LucideIcons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  else if (showResult && isSelected && !isCorrect)
                    const Icon(
                      LucideIcons.x,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    if (!_isAnswerSelected) {
      return const SizedBox(height: 100);
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    
    // Find the correct answer index from multiple choice options
    int correctAnswerIndex = -1;
    if (currentQuestion.multipleChoiceOptions != null) {
      for (int i = 0; i < currentQuestion.multipleChoiceOptions!.length; i++) {
        if (currentQuestion.multipleChoiceOptions![i].isCorrect) {
          correctAnswerIndex = i;
          break;
        }
      }
    }
    
    final isCorrect = _selectedAnswerIndex == correctAnswerIndex;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showCorrectAnswer) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? LucideIcons.check : LucideIcons.x,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? 'Benar!' : 'Salah!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentQuestion.essayKeyAnswer ?? 'Tidak ada penjelasan tersedia.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showCorrectAnswer ? _nextQuestion : _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _showCorrectAnswer 
                    ? (_currentQuestionIndex == _questions.length - 1 ? 'Selesai' : 'Lanjut')
                    : 'Periksa Jawaban',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(int? answerIndex) {
    if (_questions.isEmpty) return;
    if (_selectedAnswerIndex != null) return; // Already answered
    
    setState(() {
      _selectedAnswerIndex = answerIndex;
      _isAnswerSelected = true; // Set this flag when answer is selected
    });
    
    // Record the answer with proper UserAnswer structure
    final currentQuestion = _questions[_currentQuestionIndex];
    final timeSpent = (2 * 60) - _timeRemaining; // Time spent on this question
    
    final userAnswer = UserAnswer(
      questionId: currentQuestion.id,
      selectedAnswerIndex: answerIndex ?? -1,
      isCorrect: false, // Will be set in _checkAnswer
      timeSpent: timeSpent,
    );
    
    // Add or update the answer in the list
    if (_userAnswers.length > _currentQuestionIndex) {
      _userAnswers[_currentQuestionIndex] = userAnswer;
    } else {
      _userAnswers.add(userAnswer);
    }
    
    // Auto-check answer after selection
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkAnswer();
      }
    });
  }

  void _checkAnswer() {
    if (_questions.isEmpty) return;
    
    final currentQuestion = _questions[_currentQuestionIndex];
    
    bool isCorrect = false;
    int points = 0;
    
    if (currentQuestion.questionType == QuestionType.multipleChoice && 
        currentQuestion.multipleChoiceOptions != null &&
        _selectedAnswerIndex != null) {
      // Find correct answer index
      final options = currentQuestion.multipleChoiceOptions!;
      int correctIndex = -1;
      for (int i = 0; i < options.length; i++) {
        if (options[i].isCorrect) {
          correctIndex = i;
          break;
        }
      }
      
      isCorrect = _selectedAnswerIndex == correctIndex;
      if (isCorrect) {
        points = currentQuestion.points;
        _correctAnswers++;
        _score += points;
      }
    }

    // Update the UserAnswer object with correct status
    if (_userAnswers.length > _currentQuestionIndex) {
      final existingAnswer = _userAnswers[_currentQuestionIndex];
      _userAnswers[_currentQuestionIndex] = UserAnswer(
        questionId: existingAnswer.questionId,
        selectedAnswerIndex: existingAnswer.selectedAnswerIndex,
        isCorrect: isCorrect,
        timeSpent: existingAnswer.timeSpent,
      );
    }

    setState(() {
      _showCorrectAnswer = true;
    });

    // Move to next question after showing result
    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_questions.isEmpty) return;
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _isAnswerSelected = false;
        _showCorrectAnswer = false;
      });

      _questionAnimationController.reset();
      _answerAnimationController.reset();
      _questionAnimationController.forward();
      _updateProgressAnimation();
      
      // Reset timer for next question
      _timer?.cancel();
      _startTimer();
      // _questionStartTime = DateTime.now().millisecondsSinceEpoch; // Unused
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();
    
    try {
      // Save quiz result to leaderboard
      await _leaderboardService.saveQuizResult(
        studentId: 'current_student_id', // You'll need to get this from auth
        quizId: widget.quiz.id,
        score: _score,
        totalQuestions: _questions.length,
        correctAnswers: _correctAnswers,
        completionTime: DateTime.now(),
        answers: _userAnswers,
      );

      // Navigate to leaderboard screen
      if (mounted) {
        final totalTimeSpent = (_questions.length * 2 * 60) - _timeRemaining;
        final quizResult = QuizResult(
          quizId: widget.quiz.id,
          score: _score,
          totalQuestions: _questions.length,
          correctAnswers: _correctAnswers,
          timeSpent: totalTimeSpent,
          completedAt: DateTime.now(),
          answers: _userAnswers,
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              chapter: widget.chapter,
              result: quizResult,
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error - still navigate to result screen but without leaderboard
      if (mounted) {
        final totalTimeSpent = (_questions.length * 2 * 60) - _timeRemaining;
        final quizResult = QuizResult(
          quizId: widget.quiz.id,
          score: _score,
          totalQuestions: _questions.length,
          correctAnswers: _correctAnswers,
          timeSpent: totalTimeSpent,
          completedAt: DateTime.now(),
          answers: _userAnswers,
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              chapter: widget.chapter,
              result: quizResult,
            ),
          ),
        );
      }
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Keluar Quiz?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Progress quiz akan hilang jika kamu keluar sekarang.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mock question model for demonstration
class MockQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  MockQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });
}