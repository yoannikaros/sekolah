import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/quiz.dart';
import '../../utils/app_colors.dart';

class QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback? onTap;
  final bool showProgress;
  final double? progress;

  const QuizCard({
    super.key,
    required this.quiz,
    this.onTap,
    this.showProgress = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap ?? () => context.push('/quiz/${quiz.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildDescription(),
              const SizedBox(height: 16),
              _buildMetadata(),
              if (showProgress && progress != null) ...[
                const SizedBox(height: 12),
                _buildProgress(),
              ],
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getCategoryText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getCategoryColor(),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getDifficultyColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getDifficultyText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getDifficultyColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      quiz.title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      quiz.description ?? '',
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetadata() {
    return Row(
      children: [
        _buildMetadataItem(
          Icons.quiz,
          '${quiz.questionCount ?? 0} soal',
        ),
        const SizedBox(width: 16),
        _buildMetadataItem(
          Icons.access_time,
          '${quiz.timeLimit} menit',
        ),
      ],
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(progress! * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.grey200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (quiz.isActive) ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Aktif',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else ...[
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Tidak Aktif',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const Spacer(),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (quiz.category) {
      case 'mathematics':
        return AppColors.primary;
      case 'science':
        return AppColors.success;
      case 'history':
        return AppColors.warning;
      case 'language':
        return AppColors.info;
      case 'general':
      default:
        return AppColors.secondary;
    }
  }

  String _getCategoryText() {
    switch (quiz.category) {
      case 'mathematics':
        return 'Matematika';
      case 'science':
        return 'Sains';
      case 'history':
        return 'Sejarah';
      case 'language':
        return 'Bahasa';
      case 'general':
      default:
        return 'Umum';
    }
  }

  Color _getDifficultyColor() {
    switch (quiz.difficulty) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDifficultyText() {
    switch (quiz.difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        return 'Unknown';
    }
  }
}

class QuizGridCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback? onTap;

  const QuizGridCard({
    super.key,
    required this.quiz,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () => context.push('/quiz/${quiz.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: _getCategoryColor(),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getDifficultyText(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getDifficultyColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                quiz.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.quiz,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quiz.questionCount ?? 0}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quiz.timeLimit}m',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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

  Color _getCategoryColor() {
    switch (quiz.category) {
      case 'mathematics':
        return AppColors.primary;
      case 'science':
        return AppColors.success;
      case 'history':
        return AppColors.warning;
      case 'language':
        return AppColors.info;
      case 'general':
      default:
        return AppColors.secondary;
    }
  }

  IconData _getCategoryIcon() {
    switch (quiz.category) {
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'language':
        return Icons.translate;
      case 'general':
      default:
        return Icons.quiz;
    }
  }

  Color _getDifficultyColor() {
    switch (quiz.difficulty) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDifficultyText() {
    switch (quiz.difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        return 'Unknown';
    }
  }
}