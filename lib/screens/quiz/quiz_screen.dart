import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/app_colors.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizzes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quiz Center'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.grey300,
          indicatorColor: AppColors.white,
          tabs: const [
            Tab(text: 'Tersedia'),
            Tab(text: 'Selesai'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableQuizzes(),
          _buildCompletedQuizzes(),
          _buildLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildAvailableQuizzes() {
    return Consumer<QuizProvider>(
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
                  onPressed: () => quizProvider.loadQuizzes(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final availableQuizzes = quizProvider.quizzes
            .where((quiz) => quiz.isActive)
            .toList();

        if (availableQuizzes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: AppColors.grey400),
                SizedBox(height: 16),
                Text(
                  'Belum ada quiz tersedia',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => quizProvider.loadQuizzes(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availableQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = availableQuizzes[index];
              return _buildQuizCard(quiz);
            },
          ),
        );
      },
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/quiz/${quiz.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _buildDifficultyChip(quiz.difficulty),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                quiz.description ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.quiz, '${quiz.questionCount ?? 0} soal'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.timer, '${quiz.timeLimit} menit'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.star, 'Quiz ${quiz.difficulty}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kategori: ${_getCategoryName(quiz.category)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Mulai Quiz',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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

  Widget _buildCompletedQuizzes() {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final completedAttempts = quizProvider.userAttempts
            .where((attempt) => attempt.completedAt != null)
            .toList();

        if (completedAttempts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.grey400),
                SizedBox(height: 16),
                Text(
                  'Belum ada quiz yang diselesaikan',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedAttempts.length,
          itemBuilder: (context, index) {
            final attempt = completedAttempts[index];
            return _buildCompletedQuizCard(attempt);
          },
        );
      },
    );
  }

  Widget _buildCompletedQuizCard(QuizAttempt attempt) {
    final scorePercentage = attempt.percentage.round();
    final isPassed = attempt.percentage >= 70; // Assuming 70% passing

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quiz #${attempt.quizId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPassed ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPassed ? 'LULUS' : 'TIDAK LULUS',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Skor: ${attempt.totalScore}/${attempt.maxScore}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$scorePercentage%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Diselesaikan: ${_formatDate(attempt.completedAt!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: AppColors.grey400),
          SizedBox(height: 16),
          Text(
            'Leaderboard akan segera hadir',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}