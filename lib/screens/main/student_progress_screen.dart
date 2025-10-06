import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/student_progress_models.dart';
import '../../services/student_progress_service.dart';
import '../../services/auth_service.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen>
    with TickerProviderStateMixin {
  final StudentProgressService _progressService = StudentProgressService();
  final AuthService _authService = AuthService();
  
  StudentLearningProgress? _progress;
  WeeklyProgressSummary? _weeklyProgress;
  bool _isLoading = true;
  String _selectedTab = 'overview';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProgressData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadProgressData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final progress = await _progressService.getStudentProgress(user.uid);
        final weeklyProgress = await _progressService.getWeeklyProgressSummary(user.uid);
        
        if (mounted) {
          setState(() {
            _progress = progress;
            _weeklyProgress = weeklyProgress;
            _isLoading = false;
          });
          _animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Progress Belajar',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6B73FF),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _progress == null
              ? _buildErrorState()
              : _buildProgressContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B73FF)),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat data progress...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 64,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat data progress',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Silakan coba lagi nanti',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadProgressData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B73FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildTabSelector(),
              const SizedBox(height: 20),
              if (_selectedTab == 'overview') ...[
                _buildOverviewTab(),
              ] else if (_selectedTab == 'subjects') ...[
                _buildSubjectsTab(),
              ] else if (_selectedTab == 'activity') ...[
                _buildActivityTab(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem('overview', 'Ringkasan', LucideIcons.pieChart),
          _buildTabItem('subjects', 'Mata Pelajaran', LucideIcons.bookOpen),
          _buildTabItem('activity', 'Aktivitas', LucideIcons.activity),
        ],
      ),
    );
  }

  Widget _buildTabItem(String tabId, String title, IconData icon) {
    final isSelected = _selectedTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabId;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B73FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        _buildStatsCards(),
        const SizedBox(height: 20),
        _buildProgressChart(),
        const SizedBox(height: 20),
        _buildWeeklyActivity(),
        const SizedBox(height: 20),
        _buildAchievements(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Poin',
                  _progress!.totalPoints.toString(),
                  LucideIcons.star,
                  const Color(0xFFFFB800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Akurasi',
                  '${_progress!.overallAccuracy.toStringAsFixed(1)}%',
                  LucideIcons.target,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Streak Saat Ini',
                  '${_progress!.currentStreak} hari',
                  LucideIcons.flame,
                  const Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tugas Selesai',
                  '${_progress!.totalTasksCompleted}/${_progress!.totalTasksAssigned}',
                  LucideIcons.checkCircle,
                  const Color(0xFF6B73FF),
                ),
              ),
            ],
          ),
        ],
      ),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Mingguan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildWeeklyChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyProgress == null || _weeklyProgress!.dailyActivities.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data aktivitas minggu ini',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
      );
    }

    final activities = _weeklyProgress!.dailyActivities;
    final maxPoints = activities.map((a) => a.pointsEarned).reduce((a, b) => a > b ? a : b);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxPoints > 0 ? maxPoints.toDouble() * 1.2 : 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF6B73FF),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final activity = activities[group.x.toInt()];
              return BarTooltipItem(
                '${_getDayName(activity.date)}\n${activity.pointsEarned} poin',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < activities.length) {
                  final activity = activities[value.toInt()];
                  return Text(
                    _getDayName(activity.date).substring(0, 3),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: activity.pointsEarned.toDouble(),
                color: activity.isActive ? const Color(0xFF6B73FF) : const Color(0xFFE2E8F0),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[date.weekday % 7];
  }

  Widget _buildWeeklyActivity() {
    if (_weeklyProgress == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Minggu Ini',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyStat(
                  'Hari Aktif',
                  '${_weeklyProgress!.totalActiveDays}/7',
                  LucideIcons.calendar,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWeeklyStat(
                  'Kuis Selesai',
                  _weeklyProgress!.totalQuizzesCompleted.toString(),
                  LucideIcons.brain,
                  const Color(0xFF6B73FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWeeklyStat(
                  'Tugas Selesai',
                  _weeklyProgress!.totalTasksCompleted.toString(),
                  LucideIcons.fileCheck,
                  const Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWeeklyStat(
                  'Waktu Belajar',
                  '${(_weeklyProgress!.totalLearningTimeMinutes / 60).toStringAsFixed(1)}h',
                  LucideIcons.clock,
                  const Color(0xFFFFB800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pencapaian',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (_progress!.achievements.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.trophy,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada pencapaian',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terus belajar untuk mendapatkan pencapaian!',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...(_progress!.achievements.map((achievement) => _buildAchievementItem(achievement))),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.trophy,
              size: 20,
              color: Color(0xFFFFB800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  achievement.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${achievement.pointsAwarded}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFB800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _progress!.subjectProgress.values.map((subject) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject.subjectName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSubjectColor(subject.accuracy).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${subject.accuracy.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getSubjectColor(subject.accuracy),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSubjectStat(
                        'Kuis',
                        '${subject.completedQuizzes}/${subject.totalQuizzes}',
                        LucideIcons.brain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSubjectStat(
                        'Tugas',
                        '${subject.completedTasks}/${subject.totalTasks}',
                        LucideIcons.fileText,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSubjectStat(
                        'Poin',
                        subject.totalPoints.toString(),
                        LucideIcons.star,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: subject.completionRate / 100,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getSubjectColor(subject.accuracy),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Progress: ${subject.completionRate.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF6B73FF),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Color _getSubjectColor(double accuracy) {
    if (accuracy >= 80) return const Color(0xFF10B981);
    if (accuracy >= 60) return const Color(0xFFFFB800);
    return const Color(0xFFEF4444);
  }

  Widget _buildActivityTab() {
    if (_weeklyProgress == null || _weeklyProgress!.dailyActivities.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.activity,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada aktivitas minggu ini',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai belajar untuk melihat aktivitas harian Anda',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _weeklyProgress!.dailyActivities.map((activity) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activity.isActive ? const Color(0xFF6B73FF).withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activity.isActive 
                            ? const Color(0xFF6B73FF).withValues(alpha: 0.1)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activity.isActive ? LucideIcons.checkCircle : LucideIcons.circle,
                        size: 16,
                        color: activity.isActive ? const Color(0xFF6B73FF) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getDayName(activity.date),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (activity.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${activity.pointsEarned}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFB800),
                          ),
                        ),
                      ),
                  ],
                ),
                if (activity.isActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (activity.quizzesCompleted > 0) ...[
                        Icon(
                          LucideIcons.brain,
                          size: 14,
                          color: const Color(0xFF6B73FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.quizzesCompleted} kuis',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (activity.tasksCompleted > 0) ...[
                        Icon(
                          LucideIcons.fileCheck,
                          size: 14,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.tasksCompleted} tugas',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (activity.learningTimeMinutes > 0) ...[
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: const Color(0xFFFF6B35),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.learningTimeMinutes}m',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (activity.subjectsStudied.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: activity.subjectsStudied.map((subject) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            subject,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B73FF),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}