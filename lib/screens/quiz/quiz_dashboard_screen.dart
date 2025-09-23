import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz_models.dart';
import 'quiz_screen.dart';
import '../main/class_code_screen.dart';
import 'quiz_profile_screen.dart';

class QuizDashboardScreen extends StatefulWidget {
  final String classCodeId;

  const QuizDashboardScreen({
    super.key,
    required this.classCodeId,
  });

  @override
  State<QuizDashboardScreen> createState() => _QuizDashboardScreenState();
}

class _QuizDashboardScreenState extends State<QuizDashboardScreen> {
  final QuizService _quizService = QuizService();
  List<Quiz> _quizzes = [];
  UserProgress? _userProgress;
  String _className = '';
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _className = prefs.getString('class_name') ?? 'Kelas';

      // Load quizzes and user progress
      final quizzes = await _quizService.getQuizzesByClassCode(widget.classCodeId);
      final userId = prefs.getString('user_id') ?? 'default_user';
      final progress = await _quizService.getUserProgress(userId, widget.classCodeId);

      setState(() {
        _quizzes = quizzes;
        _userProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _changeClass() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('class_code_id');
    await prefs.remove('class_code');
    await prefs.remove('class_name');

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ClassCodeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: _selectedIndex == 0 ? _buildDashboard() : _buildProfile(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue.shade600,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _className,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade600,
                        Colors.blue.shade800,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  onPressed: _changeClass,
                  tooltip: 'Ganti Kelas',
                ),
              ],
            ),

            // Progress Summary
            if (_userProgress != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
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
                        'Progress Anda',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProgressCard(
                              'Total Poin',
                              _userProgress!.totalPoints.toString(),
                              Icons.star,
                              Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildProgressCard(
                              'Streak',
                              '${_userProgress!.streak} hari',
                              Icons.local_fire_department,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildProgressCard(
                              'Badge',
                              _userProgress!.earnedBadges.length.toString(),
                              Icons.emoji_events,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Kategori Quiz',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Category Grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildListDelegate([
                  _buildCategoryCard(
                    'Membaca',
                    QuestionCategory.reading,
                    Icons.menu_book,
                    Colors.green,
                  ),
                  _buildCategoryCard(
                    'Menulis',
                    QuestionCategory.writing,
                    Icons.edit,
                    Colors.blue,
                  ),
                  _buildCategoryCard(
                    'Matematika',
                    QuestionCategory.math,
                    Icons.calculate,
                    Colors.red,
                  ),
                  _buildCategoryCard(
                    'Sains',
                    QuestionCategory.science,
                    Icons.science,
                    Colors.purple,
                  ),
                ]),
              ),
            ),

            // Recent Quizzes
            if (_quizzes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Quiz Terbaru',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final quiz = _quizzes[index];
                    return _buildQuizCard(quiz);
                  },
                  childCount: _quizzes.length > 5 ? 5 : _quizzes.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return QuizProfileScreen(
      classCode: widget.classCodeId,
    );
  }

  Widget _buildProgressCard(String title, String value, IconData icon, Color color) {
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
              fontSize: 18,
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

  Widget _buildCategoryCard(String title, QuestionCategory category, IconData icon, Color color) {
    final categoryQuizzes = _quizzes.where((quiz) => quiz.category == category).toList();
    final completedQuizzes = _userProgress?.quizResults.keys
        .where((quizId) => categoryQuizzes.any((quiz) => quiz.id == quizId))
        .length ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CategoryQuizzesScreen(
              category: category,
              categoryName: title,
              classCodeId: widget.classCodeId,
            ),
          ),
        );
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$completedQuizzes/${categoryQuizzes.length} selesai',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    final isCompleted = _userProgress?.quizResults.containsKey(quiz.id) ?? false;
    final result = _userProgress?.quizResults[quiz.id];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.quiz,
            color: isCompleted ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          quiz.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${quiz.timeLimit} menit',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.star, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${quiz.totalPoints} poin',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            if (isCompleted && result != null) ...[
              const SizedBox(height: 4),
              Text(
                'Skor: ${result.score}/${quiz.totalPoints}',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                quiz: quiz,
                classCodeId: widget.classCodeId,
              ),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }
}

class CategoryQuizzesScreen extends StatefulWidget {
  final QuestionCategory category;
  final String categoryName;
  final String classCodeId;

  const CategoryQuizzesScreen({
    super.key,
    required this.category,
    required this.categoryName,
    required this.classCodeId,
  });

  @override
  State<CategoryQuizzesScreen> createState() => _CategoryQuizzesScreenState();
}

class _CategoryQuizzesScreenState extends State<CategoryQuizzesScreen> {
  final QuizService _quizService = QuizService();
  List<Quiz> _quizzes = [];
  UserProgress? _userProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quizzes = await _quizService.getQuizzesByCategory(widget.classCodeId, widget.category);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'default_user';
      final progress = await _quizService.getUserProgress(userId, widget.classCodeId);

      setState(() {
        _quizzes = quizzes;
        _userProgress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? const Center(
                  child: Text('Belum ada quiz untuk kategori ini'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    final isCompleted = _userProgress?.quizResults.containsKey(quiz.id) ?? false;
                    final result = _userProgress?.quizResults[quiz.id];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_circle : Icons.quiz,
                            color: isCompleted ? Colors.green : Colors.blue,
                          ),
                        ),
                        title: Text(
                          quiz.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quiz.description),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${quiz.timeLimit} menit',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.star, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${quiz.totalPoints} poin',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                            if (isCompleted && result != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Skor: ${result.score}/${quiz.totalPoints}',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade400,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                quiz: quiz,
                                classCodeId: widget.classCodeId,
                              ),
                            ),
                          ).then((_) => _loadQuizzes());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}