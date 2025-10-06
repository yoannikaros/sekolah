import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../../services/chapter_service.dart';
import 'quiz_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({super.key});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen>
    with TickerProviderStateMixin {
  final ChapterService _chapterService = ChapterService();
  final AuthService _authService = AuthService();
  
  List<String> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _classCode;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSubjects();
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
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadSubjects() async {
    try {
      // Get user's class code
      final userProfile = await _authService.getCurrentUserProfile();
      final classCode = userProfile?.classCode;
      
      if (classCode == null || classCode.isEmpty) {
        setState(() {
          _errorMessage = 'Kode kelas tidak ditemukan. Silakan hubungi admin.';
          _isLoading = false;
        });
        return;
      }

      _classCode = classCode;

      // Get all chapters for this class code
      final chapters = await _chapterService.getAllChapters();
      final filteredChapters = chapters.where((chapter) => 
        chapter.classCode == classCode && chapter.isActive
      ).toList();

      // Extract unique subjects
      final subjectSet = <String>{};
      for (final chapter in filteredChapters) {
        subjectSet.add(chapter.subjectName);
      }

      setState(() {
        _subjects = subjectSet.toList()..sort();
        _isLoading = false;
      });

      if (_subjects.isEmpty) {
        setState(() {
          _errorMessage = 'Tidak ada mata pelajaran tersedia untuk kelas Anda.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memuat mata pelajaran: $e';
        _isLoading = false;
      });
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
          'Pilih Mata Pelajaran',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildSubjectList(),
    );
  }

  Widget _buildErrorState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    LucideIcons.alertCircle,
                    size: 40,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadSubjects();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Coba Lagi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildSubjects(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.bookOpen,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Mata Pelajaran',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Kelas: ${_classCode ?? 'Unknown'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih mata pelajaran untuk memulai quiz interaktif',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjects() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subject = _subjects[index];
            return _buildSubjectCard(subject, index);
          },
          childCount: _subjects.length,
        ),
      ),
    );
  }

  Widget _buildSubjectCard(String subject, int index) {
    final colors = [
      const Color(0xFF4F46E5),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFF0891B2),
      const Color(0xFFE11D48),
      const Color(0xFF7C2D12),
    ];
    
    final icons = [
      LucideIcons.calculator,
      LucideIcons.globe,
      LucideIcons.beaker, // Changed from flask to beaker
      LucideIcons.bookOpen,
      LucideIcons.palette,
      LucideIcons.music,
      LucideIcons.activity,
      LucideIcons.cpu,
    ];
    
    final color = colors[index % colors.length];
    final icon = icons[index % icons.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToQuiz(subject),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mulai quiz untuk mata pelajaran ini',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.arrowRight,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToQuiz(String subjectName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          subjectName: subjectName,
          classCode: _classCode!,
        ),
      ),
    );
  }
}