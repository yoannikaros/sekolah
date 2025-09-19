import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/app_colors.dart';

class QuizResultScreen extends StatefulWidget {
  final String quizId;
  final String attemptId;

  const QuizResultScreen({
    super.key,
    required this.quizId,
    required this.attemptId,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutBack,
    ));

    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuizResult();
      _startAnimations();
    });
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _loadQuizResult() {
    // Load quiz result data if needed
    // For now, we'll use the data from QuizProvider
  }

  void _startAnimations() {
    _scoreAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _progressAnimationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hasil Quiz'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/quiz'),
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          final quiz = quizProvider.currentQuiz;
          final attempt = quizProvider.userAttempts
              .where((a) => a.id == int.parse(widget.attemptId))
              .firstOrNull;

          if (quiz == null || attempt == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildResultHeader(quiz, attempt),
                const SizedBox(height: 24),
                _buildScoreCard(quiz, attempt),
                const SizedBox(height: 24),
                _buildPerformanceAnalysis(quiz, attempt),
                const SizedBox(height: 24),
                _buildBadgeSection(attempt),
                const SizedBox(height: 32),
                _buildActionButtons(quiz),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultHeader(Quiz quiz, QuizAttempt attempt) {
    final isPassed = attempt.percentage >= 60.0; // Assuming 60% is passing
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed 
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scoreAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPassed ? Icons.check_circle : Icons.cancel,
                    size: 48,
                    color: AppColors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Selamat!' : 'Belum Berhasil',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPassed 
                ? 'Anda telah lulus quiz ini'
                : 'Anda belum mencapai nilai minimum',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            quiz.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(Quiz quiz, QuizAttempt attempt) {
    final scorePercentage = attempt.percentage;
    final isPassed = attempt.percentage >= 60.0; // Assuming 60% is passing

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Skor Anda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                final totalQuestions = quiz.questionCount ?? 0;
                final correctAnswers = (attempt.percentage * totalQuestions / 100).round();
                final animatedScore = (correctAnswers * _scoreAnimation.value).round();
                final animatedPercentage = (scorePercentage * _scoreAnimation.value);
                
                return Column(
                  children: [
                    Text(
                      '$animatedScore',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isPassed ? AppColors.success : AppColors.error,
                      ),
                    ),
                    Text(
                      'dari $totalQuestions soal',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${animatedPercentage.round()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isPassed ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Nilai Lulus: 60%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (scorePercentage / 100) * _progressAnimation.value,
                      backgroundColor: AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPassed ? AppColors.success : AppColors.error,
                      ),
                      minHeight: 8,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceAnalysis(Quiz quiz, QuizAttempt attempt) {
    final totalQuestions = quiz.questionCount ?? 0;
    final correctAnswers = (attempt.percentage * totalQuestions / 100).round();
    final incorrectAnswers = totalQuestions - correctAnswers;
    final accuracy = attempt.percentage;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analisis Performa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.check_circle,
                    'Benar',
                    '$correctAnswers',
                    AppColors.success,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.cancel,
                    'Salah',
                    '$incorrectAnswers',
                    AppColors.error,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.percent,
                    'Akurasi',
                    '${accuracy.round()}%',
                    AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTimeInfo(attempt),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(QuizAttempt attempt) {
    // Calculate duration based on timeSpent (in seconds)
    final totalSeconds = attempt.timeSpent;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Waktu Pengerjaan: ${minutes}m ${seconds}s',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSection(QuizAttempt attempt) {
    // This would be implemented based on the badge system
    // For now, we'll show a placeholder
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Badge Pencapaian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 40,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quiz Completer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Menyelesaikan quiz dengan baik',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Quiz quiz) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Kembali ke Daftar Quiz',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push('/quiz/${quiz.id}'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // Share result functionality
            _shareResult();
          },
          child: const Text(
            'Bagikan Hasil',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _shareResult() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur berbagi akan segera hadir'),
      ),
    );
  }
}