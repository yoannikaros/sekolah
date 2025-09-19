import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/app_colors.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizDetails(int.parse(widget.quizId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Quiz'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (quizProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${quizProvider.error}',
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => quizProvider.loadQuizDetails(int.parse(widget.quizId)),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final quiz = quizProvider.currentQuiz;
          if (quiz == null) {
            return const Center(
              child: Text('Quiz tidak ditemukan'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuizHeader(quiz),
                const SizedBox(height: 24),
                _buildQuizInfo(quiz),
                const SizedBox(height: 24),
                _buildQuizDescription(quiz),
                const SizedBox(height: 24),
                _buildQuizRules(),
                const SizedBox(height: 32),
                _buildStartButton(quiz, quizProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizHeader(Quiz quiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
              _buildDifficultyChip(quiz.difficulty),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kategori: ${_getCategoryName(quiz.category)}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfo(Quiz quiz) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Quiz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.quiz,
                    'Total Soal',
                    '${quiz.questionCount ?? 0} soal',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.timer,
                    'Waktu',
                    '${quiz.timeLimit} menit',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.star,
                    'Nilai Lulus',
                    '60%',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.refresh,
                    'Percobaan',
                    'Unlimited',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizDescription(Quiz quiz) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              quiz.description ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizRules() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aturan Quiz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildRuleItem('Jawab semua pertanyaan sebelum waktu habis'),
            _buildRuleItem('Setiap soal memiliki satu jawaban yang benar'),
            _buildRuleItem('Tidak dapat kembali ke soal sebelumnya'),
            _buildRuleItem('Quiz akan otomatis selesai jika waktu habis'),
            _buildRuleItem('Hasil akan ditampilkan setelah quiz selesai'),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              rule,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(Quiz quiz, QuizProvider quizProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: quizProvider.isLoading
            ? null
            : () => _startQuiz(quiz, quizProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: quizProvider.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Text(
                'Mulai Quiz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    String text;

    switch (difficulty) {
      case 'easy':
        color = AppColors.success;
        text = 'Mudah';
        break;
      case 'medium':
        color = AppColors.warning;
        text = 'Sedang';
        break;
      case 'hard':
        color = AppColors.error;
        text = 'Sulit';
        break;
      default:
        color = AppColors.primary;
        text = 'Sedang';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'general':
        return 'Umum';
      case 'science':
        return 'Sains';
      case 'history':
        return 'Sejarah';
      case 'sports':
        return 'Olahraga';
      case 'entertainment':
        return 'Hiburan';
      case 'technology':
        return 'Teknologi';
      case 'mathematics':
        return 'Matematika';
      case 'language':
        return 'Bahasa';
      default:
        return 'Umum';
    }
  }

  void _startQuiz(Quiz quiz, QuizProvider quizProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mulai Quiz'),
          content: Text(
            'Apakah Anda siap memulai "${quiz.title}"?\n\n'
            'Pastikan Anda memiliki waktu ${quiz.timeLimit} menit untuk menyelesaikan quiz ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  final attemptId = await quizProvider.startQuizAttempt(quiz.id);
                  if (context.mounted) {
                    context.push('/quiz/${quiz.id}/take/$attemptId');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal memulai quiz: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Mulai'),
            ),
          ],
        );
      },
    );
  }
}