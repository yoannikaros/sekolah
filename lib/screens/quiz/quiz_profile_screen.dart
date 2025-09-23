import 'package:flutter/material.dart';
import '../../models/quiz_models.dart' as quiz_models;
import '../../services/quiz_service.dart';

class QuizProfileScreen extends StatefulWidget {
  final String classCode;

  const QuizProfileScreen({
    super.key,
    required this.classCode,
  });

  @override
  State<QuizProfileScreen> createState() => _QuizProfileScreenState();
}

class _QuizProfileScreenState extends State<QuizProfileScreen> with TickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  quiz_models.UserProgress? _userProgress;
  List<quiz_models.Badge> _badges = [];
  bool _isLoading = true;
  late AnimationController _progressController;
  late AnimationController _badgeController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  Future<void> _loadUserData() async {
    try {
      // For now, we'll use a placeholder userId - in a real app, this would come from authentication
      final userId = 'user_${widget.classCode}';
      final progress = await _quizService.getUserProgress(userId, widget.classCode);
      // getUserBadges method doesn't exist, so we'll initialize empty list
      final badges = <quiz_models.Badge>[];

      setState(() {
        _userProgress = progress;
        _badges = badges;
        _isLoading = false;
      });

      _progressController.forward();
      _badgeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  String _getProgressMessage() {
    if (_userProgress == null) return 'Mulai belajar!';
    
    final totalQuizzes = _userProgress!.quizResults.length;
    if (totalQuizzes >= 50) return 'Master Learner! 🏆';
    if (totalQuizzes >= 25) return 'Advanced Learner! 🌟';
    if (totalQuizzes >= 10) return 'Active Learner! 📚';
    if (totalQuizzes >= 5) return 'Good Start! 👍';
    return 'Keep Learning! 💪';
  }

  Color _getProgressColor() {
    if (_userProgress == null) return Colors.grey;
    
    final totalQuizzes = _userProgress!.quizResults.length;
    if (totalQuizzes >= 25) return Colors.purple;
    if (totalQuizzes >= 10) return Colors.green;
    if (totalQuizzes >= 5) return Colors.blue;
    return Colors.orange;
  }

  double _calculateAverageScore() {
    if (_userProgress?.quizResults.isEmpty ?? true) return 0.0;
    
    final results = _userProgress!.quizResults.values;
    final totalScore = results.fold<double>(0.0, (sum, result) => sum + (result.score / result.totalQuestions * 100));
    return totalScore / results.length;
  }

  // Calculate user level based on total points
  int _getUserLevel() {
    if (_userProgress == null) return 1;
    return (_userProgress!.totalPoints ~/ 100) + 1;
  }

  // Calculate total XP (same as totalPoints for now)
  int _getTotalXP() {
    return _userProgress?.totalPoints ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile Quiz'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    const SizedBox(height: 24),

                    // Statistics Cards
                    _buildStatisticsSection(),
                    const SizedBox(height: 24),

                    // Progress by Category
                    _buildCategoryProgress(),
                    const SizedBox(height: 24),

                    // Badges Section
                    _buildBadgesSection(),
                    const SizedBox(height: 24),

                    // Recent Activity
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getProgressColor(), _getProgressColor().withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getProgressColor().withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar and Level
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelas ${widget.classCode}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getProgressMessage(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level ${_getUserLevel()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // XP Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP: ${_getTotalXP()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Next: ${_getUserLevel() * 100}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  final currentXP = _userProgress?.totalPoints ?? 0;
                  final progress = (currentXP % 100) / 100;
                  
                  return LinearProgressIndicator(
                    value: progress * _progressController.value,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
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
                 'Quiz Selesai',
                 '${_userProgress?.quizResults.length ?? 0}',
                 Icons.quiz,
                 Colors.blue,
               ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rata-rata Skor',
                '${_calculateAverageScore().toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Streak Hari',
                '${_userProgress?.streak ?? 0}',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Badge Earned',
                '${_badges.length}',
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildCategoryProgress() {
    final categories = quiz_models.QuestionCategory.values;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress per Kategori',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: categories.map((category) {
              final categoryProgress = _userProgress?.categoryProgress[category]?.accuracy ?? 0.0;
              final categoryName = _getCategoryName(category);
              final categoryIcon = _getCategoryIcon(category);
              final categoryColor = _getCategoryColor(category);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(categoryIcon, color: categoryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(categoryProgress * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: categoryProgress * _progressController.value,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                          minHeight: 6,
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Badge Collection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_badges.length} Badge',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_badges.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada badge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selesaikan quiz untuk mendapatkan badge pertama!',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          AnimatedBuilder(
            animation: _badgeController,
            builder: (context, child) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: _badges.length,
                itemBuilder: (context, index) {
                  final badge = _badges[index];
                  return Transform.scale(
                    scale: _badgeController.value,
                    child: _buildBadgeCard(badge),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildBadgeCard(quiz_models.Badge badge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getBadgeColor(badge.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getBadgeIcon(badge.type),
              color: _getBadgeColor(badge.type),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentQuizzes = _userProgress?.quizResults.values.take(5).toList() ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivitas Terbaru',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (recentQuizzes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada aktivitas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mulai mengerjakan quiz untuk melihat aktivitas!',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: recentQuizzes.asMap().entries.map((entry) {
                final index = entry.key;
                final quizResult = entry.value;
                final isLast = index == recentQuizzes.length - 1;
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: isLast ? null : Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.quiz,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quiz Selesai',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Skor: ${quizResult.score}/${quizResult.totalQuestions}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _getCategoryName(quiz_models.QuestionCategory category) {
    switch (category) {
      case quiz_models.QuestionCategory.reading:
        return 'Membaca';
      case quiz_models.QuestionCategory.writing:
        return 'Menulis';
      case quiz_models.QuestionCategory.math:
        return 'Matematika';
      case quiz_models.QuestionCategory.science:
        return 'Sains';
    }
  }

  IconData _getCategoryIcon(quiz_models.QuestionCategory category) {
    switch (category) {
      case quiz_models.QuestionCategory.reading:
        return Icons.book;
      case quiz_models.QuestionCategory.writing:
        return Icons.edit;
      case quiz_models.QuestionCategory.math:
        return Icons.calculate;
      case quiz_models.QuestionCategory.science:
        return Icons.science;
    }
  }

  Color _getCategoryColor(quiz_models.QuestionCategory category) {
    switch (category) {
      case quiz_models.QuestionCategory.reading:
        return Colors.blue;
      case quiz_models.QuestionCategory.writing:
        return Colors.green;
      case quiz_models.QuestionCategory.math:
        return Colors.orange;
      case quiz_models.QuestionCategory.science:
        return Colors.purple;
    }
  }

  Color _getBadgeColor(quiz_models.BadgeType type) {
    switch (type) {
      case quiz_models.BadgeType.streak:
        return Colors.orange;
      case quiz_models.BadgeType.achievement:
        return Colors.blue;
      case quiz_models.BadgeType.milestone:
        return Colors.green;
      case quiz_models.BadgeType.category:
        return Colors.purple;
    }
  }

  IconData _getBadgeIcon(quiz_models.BadgeType type) {
    switch (type) {
      case quiz_models.BadgeType.streak:
        return Icons.local_fire_department;
      case quiz_models.BadgeType.achievement:
        return Icons.star;
      case quiz_models.BadgeType.milestone:
        return Icons.flag;
      case quiz_models.BadgeType.category:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _badgeController.dispose();
    super.dispose();
  }
}