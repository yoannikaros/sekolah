import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/chapter_models.dart';
import '../../models/leaderboard_models.dart';
import '../../services/chapter_service.dart';
import '../../services/leaderboard_service.dart';

class QuestionManagementScreen extends StatefulWidget {
  final Chapter chapter;
  final Quiz quiz;

  const QuestionManagementScreen({
    super.key,
    required this.chapter,
    required this.quiz,
  });

  @override
  State<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends State<QuestionManagementScreen> with SingleTickerProviderStateMixin {
  final ChapterService _chapterService = ChapterService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  late TabController _tabController;
  
  List<Question> _questions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  // Leaderboard related state
  ClassLeaderboard? _classLeaderboard;
  List<GameBadge> _availableBadges = [];
  bool _isLoadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuestions();
    _loadLeaderboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildQuestionsTab() {
    return Column(
      children: [
        // Quiz Info & Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[600],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Quiz Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.quiz, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.chapter.title} • ${widget.chapter.subjectName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.help_outline,
                          label: '${_questions.length} Soal',
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.star_outline,
                          label: '${_questions.fold<int>(0, (sum, q) => sum + q.points)} Poin',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Cari soal...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredQuestions.isEmpty
                  ? _buildEmptyState()
                  : _buildQuestionList(),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLoadingLeaderboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_classLeaderboard == null || _classLeaderboard!.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data leaderboard',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Siswa perlu mengerjakan quiz untuk muncul di leaderboard',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Class Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.class_, color: Colors.orange[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Statistik Kelas: ${_classLeaderboard!.classCodeName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Siswa',
                          '${_classLeaderboard!.totalStudents}',
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Rata-rata Skor',
                          _classLeaderboard!.averageScore.toStringAsFixed(1),
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Total Quiz',
                          '${_classLeaderboard!.totalQuizzes}',
                          Icons.quiz,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Leaderboard List
          Text(
            'Peringkat Siswa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          
          ...List.generate(_classLeaderboard!.entries.length, (index) {
            final entry = _classLeaderboard!.entries[index];
            return _buildLeaderboardCard(entry, index);
          }),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    if (_isLoadingLeaderboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableBadges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada badge tersedia',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Badge Tersedia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Badge yang bisa diraih siswa berdasarkan pencapaian mereka',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          ...List.generate(_availableBadges.length, (index) {
            final badge = _availableBadges[index];
            return _buildBadgeCard(badge);
          }),
        ],
      ),
    );
  }

  Future<void> _loadLeaderboardData() async {
    setState(() => _isLoadingLeaderboard = true);
    try {
      // Get class code from chapter
      final classCodeId = widget.chapter.classCode; // Assuming this contains the class code ID
      
      // Load leaderboard and badges
      final leaderboard = await _leaderboardService.getClassLeaderboard(classCodeId);
      final badges = await _leaderboardService.getAvailableBadges();
      
      setState(() {
        _classLeaderboard = leaderboard;
        _availableBadges = badges;
        _isLoadingLeaderboard = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading leaderboard data: $e');
      }
      setState(() => _isLoadingLeaderboard = false);
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('QuestionManagementScreen: Starting to load questions for quiz ${widget.quiz.id}...');
        print('QuestionManagementScreen: Quiz title: ${widget.quiz.title}');
      }
      
      final questions = await _chapterService.getQuestionsByQuizId(widget.quiz.id);
      
      if (kDebugMode) {
        print('QuestionManagementScreen: Loaded ${questions.length} questions');
      }
      
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('QuestionManagementScreen: Question loading completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('QuestionManagementScreen: Error loading questions: $e');
        print('QuestionManagementScreen: Stack trace: ${StackTrace.current}');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading questions: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Question> get _filteredQuestions {
    if (_searchQuery.isEmpty) return _questions;
    return _questions.where((question) {
      return question.questionText.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manajemen Soal', style: TextStyle(fontSize: 18)),
            Text(
              widget.quiz.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'Soal'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Badge'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionsTab(),
          _buildLeaderboardTab(),
          _buildBadgesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _showQuestionDialog(),
              backgroundColor: Colors.orange[600],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
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
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int index) {
    Color rankColor = Colors.grey;
    IconData rankIcon = Icons.person;
    
    if (entry.rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (entry.rank == 2) {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.emoji_events;
    } else if (entry.rank == 3) {
      rankColor = Colors.brown;
      rankIcon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rankColor.withValues(alpha: 0.2),
          child: entry.rank <= 3
              ? Icon(rankIcon, color: rankColor)
              : Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
        ),
        title: Text(
          entry.studentName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skor: ${entry.totalScore} • Akurasi: ${entry.accuracy.toStringAsFixed(1)}%'),
            if (entry.earnedBadgeIds.isNotEmpty)
              Text(
                '${entry.earnedBadgeIds.length} Badge',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalQuizzes} Quiz',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (entry.streak > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 12,
                    color: Colors.orange[600],
                  ),
                  Text(
                    '${entry.streak}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(GameBadge badge) {
    Color badgeColor = _getBadgeColor(badge.rarity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
          ),
          child: Icon(
            _getBadgeIcon(badge.iconName),
            color: badgeColor,
            size: 24,
          ),
        ),
        title: Text(
          badge.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge.rarity.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${badge.points} poin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.uncommon:
        return Colors.green;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }

  IconData _getBadgeIcon(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'gps_fixed':
        return Icons.gps_fixed;
      case 'school':
        return Icons.school;
      case 'speed':
        return Icons.speed;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.emoji_events;
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Belum ada soal' : 'Soal tidak ditemukan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Tambahkan soal pertama untuk kuis ini'
                : 'Coba kata kunci lain',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Tarik ke bawah untuk refresh',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            // Debug info in debug mode
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quiz ID: ${widget.quiz.id}',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                    Text(
                      'Total questions loaded: ${_questions.length}',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                    Text(
                      'Loading state: $_isLoading',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    return RefreshIndicator(
      onRefresh: _loadQuestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredQuestions.length,
        itemBuilder: (context, index) {
          final question = _filteredQuestions[index];
          return _buildQuestionCard(question, index + 1);
        },
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int number) {
    final isMultipleChoice = question.questionType == QuestionType.multipleChoice;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMultipleChoice ? Colors.blue[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isMultipleChoice ? 'Pilihan Ganda' : 'Essay',
                              style: TextStyle(
                                fontSize: 12,
                                color: isMultipleChoice ? Colors.blue[700] : Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${question.points} Poin',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showQuestionDialog(question: question);
                        break;
                      case 'delete':
                        _confirmDeleteQuestion(question);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Question Text
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Options or Essay Answer
            if (isMultipleChoice && question.multipleChoiceOptions != null) ...[
              ...question.multipleChoiceOptions!.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: option.isCorrect ? Colors.green[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: option.isCorrect ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          option.optionLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: option.isCorrect ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.optionText,
                        style: TextStyle(
                          fontSize: 14,
                          color: option.isCorrect ? Colors.green[700] : Colors.black87,
                          fontWeight: option.isCorrect ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (option.isCorrect)
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              )),
            ] else if (!isMultipleChoice && question.essayKeyAnswer != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.key, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Jawaban Kunci:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question.essayKeyAnswer!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuestionDialog({Question? question}) {
    final isEdit = question != null;
    final questionController = TextEditingController(text: question?.questionText ?? '');
    final pointsController = TextEditingController(text: question?.points.toString() ?? '10');
    final essayAnswerController = TextEditingController(text: question?.essayKeyAnswer ?? '');
    
    QuestionType selectedType = question?.questionType ?? QuestionType.multipleChoice;
    List<MultipleChoiceOption> options = question?.multipleChoiceOptions?.map((o) => o.copyWith()).toList() ?? [
      MultipleChoiceOption(id: '1', optionText: '', optionLabel: 'A', isCorrect: false),
      MultipleChoiceOption(id: '2', optionText: '', optionLabel: 'B', isCorrect: false),
      MultipleChoiceOption(id: '3', optionText: '', optionLabel: 'C', isCorrect: false),
      MultipleChoiceOption(id: '4', optionText: '', optionLabel: 'D', isCorrect: false),
    ];
    
    final optionControllers = options.map((o) => TextEditingController(text: o.optionText)).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Soal' : 'Tambah Soal Baru'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Text
                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'Pertanyaan *',
                      hintText: 'Masukkan pertanyaan...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  
                  // Question Type
                  const Text('Jenis Soal:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<QuestionType>(
                          title: const Text('Pilihan Ganda'),
                          value: QuestionType.multipleChoice,
                          groupValue: selectedType,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<QuestionType>(
                          title: const Text('Essay'),
                          value: QuestionType.essay,
                          groupValue: selectedType,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Multiple Choice Options
                  if (selectedType == QuestionType.multipleChoice) ...[
                    const Text('Pilihan Jawaban:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: RadioListTile<int>(
                                title: Text(options[index].optionLabel),
                                value: index,
                                groupValue: options.indexWhere((o) => o.isCorrect),
                                onChanged: (value) {
                                  setDialogState(() {
                                    for (int i = 0; i < options.length; i++) {
                                      options[i] = options[i].copyWith(isCorrect: i == value);
                                    }
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: optionControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Opsi ${options[index].optionLabel}',
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  options[index] = options[index].copyWith(optionText: value);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  
                  // Essay Key Answer
                  if (selectedType == QuestionType.essay) ...[
                    TextField(
                      controller: essayAnswerController,
                      decoration: const InputDecoration(
                        labelText: 'Jawaban Kunci (Opsional)',
                        hintText: 'Masukkan jawaban kunci untuk referensi...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Points
                  TextField(
                    controller: pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Poin / Skor *',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => _saveQuestion(
                context,
                isEdit,
                question?.id,
                questionController.text,
                selectedType,
                selectedType == QuestionType.multipleChoice ? options : null,
                selectedType == QuestionType.essay ? essayAnswerController.text : null,
                int.tryParse(pointsController.text) ?? 1,
              ),
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion(
    BuildContext context,
    bool isEdit,
    String? questionId,
    String questionText,
    QuestionType questionType,
    List<MultipleChoiceOption>? multipleChoiceOptions,
    String? essayKeyAnswer,
    int points,
  ) async {
    if (questionText.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon isi teks pertanyaan')),
        );
      }
      return;
    }

    if (questionType == QuestionType.multipleChoice) {
      if (multipleChoiceOptions == null || multipleChoiceOptions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mohon tambahkan minimal satu pilihan untuk soal pilihan ganda')),
          );
        }
        return;
      }
      
      if (!multipleChoiceOptions.any((option) => option.isCorrect)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mohon pilih jawaban yang benar')),
          );
        }
        return;
      }
    }

    if (points <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poin harus lebih dari 0')),
        );
      }
      return;
    }

    Navigator.pop(context);

    try {
      final question = Question(
        id: questionId ?? '',
        quizId: widget.quiz.id,
        questionText: questionText.trim(),
        questionType: questionType,
        multipleChoiceOptions: multipleChoiceOptions,
        essayKeyAnswer: essayKeyAnswer,
        points: points,
        createdAt: isEdit ? _questions.firstWhere((q) => q.id == questionId).createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      bool success;
      if (isEdit) {
        success = await _chapterService.updateQuestion(questionId!, question);
      } else {
        final id = await _chapterService.createQuestion(question);
        success = id != null;
      }

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Soal berhasil ${isEdit ? 'diupdate' : 'ditambahkan'}')),
          );
        }
        _loadQuestions();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal ${isEdit ? 'mengupdate' : 'menambahkan'} soal')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _confirmDeleteQuestion(Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus soal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteQuestion(context, question),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(BuildContext context, Question question) async {
    Navigator.pop(context);

    try {
      final success = await _chapterService.deleteQuestion(question.id);
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Soal berhasil dihapus')),
          );
        }
        _loadQuestions();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus soal')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}