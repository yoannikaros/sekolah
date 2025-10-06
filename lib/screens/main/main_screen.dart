import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sekangkatanapp/screens/main/student_progress_screen.dart';
import 'package:sekangkatanapp/services/task_service.dart';
import 'package:sekangkatanapp/models/task_models.dart';
import 'package:sekangkatanapp/models/chapter_models.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ClassScreen(),
    const StudentProgressScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, LucideIcons.home, "Beranda"),
                _buildNavItem(1, LucideIcons.graduationCap, "Kelas"),
                _buildNavItem(2, LucideIcons.barChart3, "Progress"),
                _buildNavItem(3, LucideIcons.user, "Profil"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  final TaskService _taskService = TaskService();
  
  List<Task> _upcomingTasks = [];
  List<Quiz> _upcomingQuizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load upcoming tasks (due within next 7 days)
      final allTasks = await _taskService.getAllTasks();
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      
      _upcomingTasks = allTasks.where((task) {
        return task.isActive && 
               task.dueDate.isAfter(now) && 
               task.dueDate.isBefore(nextWeek);
      }).toList();
      
      // Sort by due date (closest first)
      _upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      // Load upcoming quizzes (starting within next 7 days)
      // Note: We'll need to get all chapters first, then their quizzes
      // For now, we'll create a simplified approach
      _upcomingQuizzes = [];
      
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Kelas Saya",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReminders,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reminders Section
              if (!_isLoading && (_upcomingTasks.isNotEmpty || _upcomingQuizzes.isNotEmpty))
                _buildRemindersSection(),
              
              if (!_isLoading && (_upcomingTasks.isNotEmpty || _upcomingQuizzes.isNotEmpty))
                const SizedBox(height: 24),

              // Quiz Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.brain,
                                color: Color(0xFF4F46E5),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Quiz & Latihan",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Uji kemampuanmu dengan berbagai soal",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Coming Soon Cards
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                SizedBox(
                  height: 300,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.graduationCap,
                          size: 80,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Fitur Lainnya Segera Hadir",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Kami sedang mengembangkan fitur-fitur\nmenarik lainnya untuk kelasmu",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pengingat",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        
        // Task Reminders
        if (_upcomingTasks.isNotEmpty) ...[
          ..._upcomingTasks.take(3).map((task) => _buildTaskReminderCard(task)),
          if (_upcomingTasks.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "dan ${_upcomingTasks.length - 3} tugas lainnya...",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
        
        // Quiz Reminders
        if (_upcomingQuizzes.isNotEmpty) ...[
          ..._upcomingQuizzes.take(3).map((quiz) => _buildQuizReminderCard(quiz)),
          if (_upcomingQuizzes.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "dan ${_upcomingQuizzes.length - 3} quiz lainnya...",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTaskReminderCard(Task task) {
    final now = DateTime.now();
    final daysUntilDue = task.dueDate.difference(now).inDays;
    final hoursUntilDue = task.dueDate.difference(now).inHours;
    
    String timeText;
    Color urgencyColor;
    
    if (daysUntilDue == 0) {
      if (hoursUntilDue <= 1) {
        timeText = "Jatuh tempo dalam ${task.dueDate.difference(now).inMinutes} menit";
        urgencyColor = Colors.red;
      } else {
        timeText = "Jatuh tempo hari ini";
        urgencyColor = Colors.orange;
      }
    } else if (daysUntilDue == 1) {
      timeText = "Jatuh tempo besok";
      urgencyColor = Colors.orange;
    } else {
      timeText = "Jatuh tempo dalam $daysUntilDue hari";
      urgencyColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: urgencyColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.fileText,
              color: urgencyColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: urgencyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(task.dueDate),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.clock,
            color: urgencyColor,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizReminderCard(Quiz quiz) {
    final now = DateTime.now();
    final daysUntilStart = quiz.startDateTime.difference(now).inDays;
    final hoursUntilStart = quiz.startDateTime.difference(now).inHours;
    
    String timeText;
    Color urgencyColor;
    
    if (daysUntilStart == 0) {
      if (hoursUntilStart <= 1) {
        timeText = "Dimulai dalam ${quiz.startDateTime.difference(now).inMinutes} menit";
        urgencyColor = Colors.red;
      } else {
        timeText = "Dimulai hari ini";
        urgencyColor = Colors.orange;
      }
    } else if (daysUntilStart == 1) {
      timeText = "Dimulai besok";
      urgencyColor = Colors.orange;
    } else {
      timeText = "Dimulai dalam $daysUntilStart hari";
      urgencyColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: urgencyColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.brain,
              color: urgencyColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: urgencyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(quiz.startDateTime),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.clock,
            color: urgencyColor,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Progress Belajar",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.barChart3,
              size: 80,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 16),
            Text(
              "Progress Belajar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Pantau perkembangan belajarmu setiap hari",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}