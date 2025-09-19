import 'package:flutter/material.dart';
import '../../models/quiz.dart';
import '../../utils/app_colors.dart';

class QuestionWidget extends StatefulWidget {
  final QuizQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final String? selectedAnswer;
  final List<String>? selectedAnswers;
  final Function(String) onAnswerSelected;
  final Function(List<String>) onMultipleAnswersSelected;
  final bool isReviewMode;
  final String? correctAnswer;
  final List<String>? correctAnswers;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    this.selectedAnswer,
    this.selectedAnswers,
    required this.onAnswerSelected,
    required this.onMultipleAnswersSelected,
    this.isReviewMode = false,
    this.correctAnswer,
    this.correctAnswers,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildQuestionContent(),
          ),
        );
      },
    );
  }

  Widget _buildQuestionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionHeader(),
        const SizedBox(height: 24),
        _buildQuestionText(),
        const SizedBox(height: 24),
        _buildAnswerOptions(),
        if (widget.isReviewMode && widget.question.explanation != null) ...[
          const SizedBox(height: 24),
          _buildExplanation(),
        ],
      ],
    );
  }

  Widget _buildQuestionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${widget.questionNumber}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soal ${widget.questionNumber} dari ${widget.totalQuestions}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _getQuestionTypeText(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getQuestionTypeColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${widget.question.points} poin',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getQuestionTypeColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
      ),
      child: Text(
        widget.question.question,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }



  Widget _buildAnswerOptions() {
    switch (widget.question.type) {
      case 'multiple_choice':
        return _buildMultipleChoiceOptions();
      case 'multiple_answer':
        return _buildMultipleAnswerOptions();
      case 'true_false':
        return _buildTrueFalseOptions();
      case 'essay':
        return _buildEssayInput();
      default:
        return _buildMultipleChoiceOptions();
    }
  }

  Widget _buildMultipleChoiceOptions() {
    final options = widget.question.options ?? [];
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
        final isSelected = widget.selectedAnswer == option;
        final isCorrect = widget.isReviewMode && widget.correctAnswer == option;
        final isWrong = widget.isReviewMode && 
                       isSelected && 
                       widget.correctAnswer != option;

        Color backgroundColor = AppColors.white;
        Color borderColor = AppColors.grey200;
        Color textColor = AppColors.textPrimary;

        if (widget.isReviewMode) {
          if (isCorrect) {
            backgroundColor = AppColors.success.withValues(alpha: 0.1);
            borderColor = AppColors.success;
            textColor = AppColors.success;
          } else if (isWrong) {
            backgroundColor = AppColors.error.withValues(alpha: 0.1);
            borderColor = AppColors.error;
            textColor = AppColors.error;
          }
        } else if (isSelected) {
          backgroundColor = AppColors.primary.withValues(alpha: 0.1);
          borderColor = AppColors.primary;
          textColor = AppColors.primary;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: widget.isReviewMode ? null : () {
              widget.onAnswerSelected(option);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected || isCorrect || isWrong
                          ? borderColor
                          : AppColors.grey200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.isReviewMode && (isCorrect || isWrong)
                          ? Icon(
                              isCorrect ? Icons.check : Icons.close,
                              color: AppColors.white,
                              size: 18,
                            )
                          : Text(
                              optionLetter,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        fontWeight: isSelected || isCorrect || isWrong
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleAnswerOptions() {
    final selectedAnswers = widget.selectedAnswers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pilih semua jawaban yang benar',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...(widget.question.options ?? []).asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final optionLetter = String.fromCharCode(65 + index);
          final isSelected = selectedAnswers.contains(option);
          final isCorrect = widget.isReviewMode && 
                           widget.correctAnswers?.contains(option) == true;
          final isWrong = widget.isReviewMode && 
                         isSelected && 
                         widget.correctAnswers?.contains(option) != true;

          Color backgroundColor = AppColors.white;
          Color borderColor = AppColors.grey200;
          Color textColor = AppColors.textPrimary;

          if (widget.isReviewMode) {
            if (isCorrect) {
              backgroundColor = AppColors.success.withValues(alpha: 0.1);
              borderColor = AppColors.success;
              textColor = AppColors.success;
            } else if (isWrong) {
              backgroundColor = AppColors.error.withValues(alpha: 0.1);
              borderColor = AppColors.error;
              textColor = AppColors.error;
            }
          } else if (isSelected) {
            backgroundColor = AppColors.primary.withValues(alpha: 0.1);
            borderColor = AppColors.primary;
            textColor = AppColors.primary;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: widget.isReviewMode ? null : () {
                final newSelectedAnswers = List<String>.from(selectedAnswers);
                if (isSelected) {
                  newSelectedAnswers.remove(option);
                } else {
                  newSelectedAnswers.add(option);
                }
                widget.onMultipleAnswersSelected(newSelectedAnswers);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected || isCorrect || isWrong
                            ? borderColor
                            : AppColors.grey200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: widget.isReviewMode && (isCorrect || isWrong)
                            ? Icon(
                                isCorrect ? Icons.check : Icons.close,
                                color: AppColors.white,
                                size: 16,
                              )
                            : isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 16,
                                  )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      optionLetter,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                          fontWeight: isSelected || isCorrect || isWrong
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalseOptions() {
    return Row(
      children: [
        Expanded(
          child: _buildTrueFalseOption('Benar', true),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTrueFalseOption('Salah', false),
        ),
      ],
    );
  }

  Widget _buildTrueFalseOption(String text, bool value) {
    final stringValue = value.toString();
    final isSelected = widget.selectedAnswer == stringValue;
    final isCorrect = widget.isReviewMode && widget.correctAnswer == stringValue;
    final isWrong = widget.isReviewMode && 
                   isSelected && 
                   widget.correctAnswer != stringValue;

    Color backgroundColor = AppColors.white;
    Color borderColor = AppColors.grey200;
    Color textColor = AppColors.textPrimary;
    IconData icon = value ? Icons.check_circle : Icons.cancel;

    if (widget.isReviewMode) {
      if (isCorrect) {
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        borderColor = AppColors.success;
        textColor = AppColors.success;
      } else if (isWrong) {
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
      }
    } else if (isSelected) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.1);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return InkWell(
      onTap: widget.isReviewMode ? null : () {
        widget.onAnswerSelected(stringValue);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: borderColor,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssayInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
      ),
      child: TextField(
        maxLines: 8,
        decoration: const InputDecoration(
          hintText: 'Tulis jawaban Anda di sini...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
        onChanged: (value) {
          widget.onAnswerSelected(value);
        },
      ),
    );
  }

  Widget _buildExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.info,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Penjelasan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.explanation!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getQuestionTypeText() {
    switch (widget.question.type) {
      case 'multiple_choice':
        return 'Pilihan Ganda';
      case 'multiple_answer':
        return 'Pilihan Ganda (Banyak Jawaban)';
      case 'true_false':
        return 'Benar/Salah';
      case 'essay':
        return 'Essay';
      default:
        return 'Pilihan Ganda';
    }
  }

  Color _getQuestionTypeColor() {
    switch (widget.question.type) {
      case 'multiple_choice':
        return AppColors.primary;
      case 'multiple_answer':
        return AppColors.warning;
      case 'true_false':
        return AppColors.success;
      case 'essay':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }
}