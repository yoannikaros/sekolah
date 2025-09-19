import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import '../../utils/app_colors.dart';

class QuizTakeScreen extends StatefulWidget {
  final String quizId;
  final String attemptId;

  const QuizTakeScreen({
    super.key,
    required this.quizId,
    required this.attemptId,
  });

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  int currentQuestionIndex = 0;
  Map<String, String> selectedAnswers = {};
  Timer? _timer;
  int remainingSeconds = 0;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuiz();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeQuiz() {
    final quizProvider = context.read<QuizProvider>();
    final quiz = quizProvider.currentQuiz;
    
    if (quiz != null) {
      remainingSeconds = quiz.timeLimit * 60; // Convert minutes to seconds
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz(autoSubmit: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (await _showExitDialog()) {
            if (context.mounted) {
              context.pop();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _showExitDialog()) {
                if (context.mounted) {
                  context.pop();
                }
              }
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTimerColor(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 16, color: AppColors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(remainingSeconds),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Consumer<QuizProvider>(
          builder: (context, quizProvider, child) {
            final quiz = quizProvider.currentQuiz;
            final questions = quizProvider.currentQuestions;
            
            if (quiz == null || questions.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final currentQuestion = questions[currentQuestionIndex];

            return Column(
              children: [
                _buildProgressBar(questions.length),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildQuestionCard(currentQuestion),
                        const SizedBox(height: 24),
                        _buildAnswerOptions(currentQuestion),
                      ],
                    ),
                  ),
                ),
                _buildNavigationBar(questions.length),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar(int totalQuestions) {
    final progress = (currentQuestionIndex + 1) / totalQuestions;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soal ${currentQuestionIndex + 1} dari $totalQuestions',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getQuestionTypeName(question.type),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${question.points} poin',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(QuizQuestion question) {
    return Column(
      children: (question.options ?? []).asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final optionKey = String.fromCharCode(65 + index); // A, B, C, D
        final isSelected = selectedAnswers[question.id.toString()] == option;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedAnswers[question.id.toString()] = option;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.grey200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        optionKey,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationBar(int totalQuestions) {
    final isLastQuestion = currentQuestionIndex == totalQuestions - 1;
    final canGoNext = currentQuestionIndex < totalQuestions - 1;
    final canGoPrevious = currentQuestionIndex > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.grey200),
        ),
      ),
      child: Row(
        children: [
          if (canGoPrevious)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    currentQuestionIndex--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Sebelumnya'),
              ),
            ),
          if (canGoPrevious && (canGoNext || isLastQuestion))
            const SizedBox(width: 16),
          if (canGoNext)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentQuestionIndex++;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Selanjutnya'),
              ),
            ),
          if (isLastQuestion && !canGoNext)
            Expanded(
              child: ElevatedButton(
                onPressed: isSubmitting ? null : () => _submitQuiz(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Text('Selesai'),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    if (remainingSeconds > 300) { // > 5 minutes
      return AppColors.success;
    } else if (remainingSeconds > 60) { // > 1 minute
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getQuestionTypeName(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Pilihan Ganda';
      case 'true_false':
        return 'Benar/Salah';
      case 'essay':
        return 'Essay';
      case 'multiple_answer':
        return 'Pilihan Ganda (Banyak Jawaban)';
      default:
        return 'Pilihan Ganda';
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keluar dari Quiz'),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Progres quiz akan hilang dan tidak dapat dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _submitQuiz({bool autoSubmit = false}) async {
    if (isSubmitting) return;

    // Check if all questions are answered
    final quizProvider = context.read<QuizProvider>();
    final quiz = quizProvider.currentQuiz;
    final questions = quizProvider.currentQuestions;
    if (quiz == null || questions.isEmpty) return;

    final unansweredQuestions = questions
        .where((q) => !selectedAnswers.containsKey(q.id.toString()))
        .toList();

    if (unansweredQuestions.isNotEmpty && !autoSubmit) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Soal Belum Dijawab'),
            content: Text(
              'Masih ada ${unansweredQuestions.length} soal yang belum dijawab. '
              'Apakah Anda yakin ingin menyelesaikan quiz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      );

      if (shouldContinue != true) return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      _timer?.cancel();

      final quizProvider = context.read<QuizProvider>();
      
      // Submit all answers
      for (final entry in selectedAnswers.entries) {
        await quizProvider.submitAnswer(entry.value);
      }

      // Complete the quiz
      await quizProvider.completeQuiz();

      if (context.mounted) {
        context.pushReplacement('/quiz/${widget.quizId}/result/${widget.attemptId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan quiz: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}