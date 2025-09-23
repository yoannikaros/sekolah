import 'package:flutter/material.dart' hide Badge;
import '../../models/quiz_models.dart';

class QuizResultScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizResult result;
  final List<Question> questions;
  final List<Badge> newBadges;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.result,
    required this.questions,
    required this.newBadges,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _badgeController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.result.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    _badgeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
    });

    if (widget.newBadges.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        _badgeController.forward();
      });
    }
  }

  Color _getScoreColor() {
    final percentage = widget.result.correctAnswers / widget.result.totalQuestions;
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage() {
    final percentage = widget.result.correctAnswers / widget.result.totalQuestions;
    if (percentage >= 0.9) return 'Luar Biasa! 🌟';
    if (percentage >= 0.8) return 'Bagus Sekali! 👏';
    if (percentage >= 0.7) return 'Baik! 👍';
    if (percentage >= 0.6) return 'Cukup Baik 😊';
    return 'Tetap Semangat! 💪';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.result.correctAnswers / widget.result.totalQuestions;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      'Hasil Quiz',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Score Circle
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getScoreMessage(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Animated Score Circle
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background circle
                                 Container(
                                   width: 150,
                                   height: 150,
                                   decoration: BoxDecoration(
                                     shape: BoxShape.circle,
                                     color: _getScoreColor().withValues(alpha: 0.1),
                                   ),
                                 ),
                                
                                // Progress circle
                                SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: CircularProgressIndicator(
                                    value: percentage,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
                                  ),
                                ),
                                
                                // Score text
                                AnimatedBuilder(
                                  animation: _scoreAnimation,
                                  builder: (context, child) {
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                           '${_scoreAnimation.value.round()}',
                                           style: TextStyle(
                                             fontSize: 32,
                                             fontWeight: FontWeight.bold,
                                             color: _getScoreColor(),
                                           ),
                                         ),
                                        Text(
                                          '/${widget.quiz.totalPoints}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          Text(
                            '${(percentage * 100).round()}% Benar',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistics
                    Container(
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
                          Text(
                            'Statistik',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Benar',
                                  '${widget.result.correctAnswers}',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Salah',
                                  '${widget.result.totalQuestions - widget.result.correctAnswers}',
                                  Icons.cancel,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Waktu',
                                  _formatTime(widget.result.timeSpent),
                                  Icons.timer,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // New Badges
                    if (widget.newBadges.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _badgeAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _badgeAnimation.value,
                            child: Container(
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
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    size: 48,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Badge Baru! 🎉',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...widget.newBadges.map((badge) => _buildBadgeCard(badge)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Review Answers Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => QuizReviewScreen(
                                quiz: widget.quiz,
                                result: widget.result,
                                questions: widget.questions,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.blue.shade600),
                        ),
                        child: Text(
                          'Review Jawaban',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Back to Dashboard Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Kembali ke Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
     return Container(
       padding: const EdgeInsets.all(12),
       decoration: BoxDecoration(
         color: color.withValues(alpha: 0.1),
         borderRadius: BorderRadius.circular(12),
       ),
       child: Column(
         children: [
           Icon(icon, color: color, size: 24),
           const SizedBox(height: 8),
           Text(
             value,
             style: TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.bold,
               color: color,
             ),
           ),
           Text(
             title,
             style: TextStyle(
               fontSize: 12,
               color: Colors.grey.shade600,
             ),
             textAlign: TextAlign.center,
           ),
         ],
       ),
     );
   }

  Widget _buildBadgeCard(Badge badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _badgeController.dispose();
    super.dispose();
  }
}

class QuizReviewScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizResult result;
  final List<Question> questions;

  const QuizReviewScreen({
    super.key,
    required this.quiz,
    required this.result,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Jawaban'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final userAnswer = result.answers[index];
          final isCorrect = userAnswer.isCorrect;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                         color: isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                         shape: BoxShape.circle,
                       ),
                      child: Icon(
                        isCorrect ? Icons.check : Icons.close,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Soal ${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${userAnswer.timeSpent}s',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Question text
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Options
                ...question.options.asMap().entries.map((entry) {
                  final optionIndex = entry.key;
                  final option = entry.value;
                  final isUserAnswer = optionIndex == userAnswer.selectedAnswerIndex;
                  final isCorrectAnswer = optionIndex == question.correctAnswerIndex;
                  
                  Color backgroundColor = Colors.transparent;
                  Color borderColor = Colors.grey.shade300;
                  Color textColor = Colors.black87;
                  
                  if (isCorrectAnswer) {
                     backgroundColor = Colors.green.withValues(alpha: 0.1);
                     borderColor = Colors.green;
                     textColor = Colors.green.shade700;
                   } else if (isUserAnswer && !isCorrect) {
                     backgroundColor = Colors.red.withValues(alpha: 0.1);
                     borderColor = Colors.red;
                     textColor = Colors.red.shade700;
                   }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCorrectAnswer ? Colors.green : (isUserAnswer && !isCorrect ? Colors.red : Colors.transparent),
                            border: Border.all(
                              color: isCorrectAnswer ? Colors.green : (isUserAnswer && !isCorrect ? Colors.red : Colors.grey.shade400),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + optionIndex),
                              style: TextStyle(
                                color: isCorrectAnswer ? Colors.white : (isUserAnswer && !isCorrect ? Colors.white : Colors.grey.shade600),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: isCorrectAnswer || isUserAnswer ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isCorrectAnswer)
                          const Icon(Icons.check, color: Colors.green, size: 16),
                        if (isUserAnswer && !isCorrect)
                          const Icon(Icons.close, color: Colors.red, size: 16),
                      ],
                    ),
                  );
                }),
                
                // Explanation
                if (question.explanation != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Penjelasan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.explanation!,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}