import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../models/chapter_models.dart';
import 'quiz_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final Quiz quiz;
  final Chapter chapter;
  final QuizResult result;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.chapter,
    required this.result,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _scoreAnimationController;
  late AnimationController _celebrationController;
  late AnimationController _badgeController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scoreAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _badgeRotationAnimation;
  late Animation<double> _badgeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.result.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    
    _badgeRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));
    
    _badgeScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreAnimationController.forward();
    });
    
    if (_getPerformanceLevel() != 'Perlu Belajar Lagi') {
      Future.delayed(const Duration(milliseconds: 800), () {
        _celebrationController.forward();
      });
      
      Future.delayed(const Duration(milliseconds: 1200), () {
        _badgeController.forward();
      });
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _scoreAnimationController.dispose();
    _celebrationController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildScoreSection(),
                        const SizedBox(height: 24),
                        _buildStatsSection(),
                        const SizedBox(height: 24),
                        _buildPerformanceSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                LucideIcons.x,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizScreen(),
                ),
                (route) => false,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Selesai!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.chapter.title,
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
    );
  }

  Widget _buildScoreSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Celebration particles
              if (_getPerformanceLevel() != 'Perlu Belajar Lagi')
                AnimatedBuilder(
                  animation: _celebrationAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _celebrationAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _getAccentColor().withValues(alpha: 0.2),
                              _getAccentColor().withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              
              // Score circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getAccentColor(),
                      _getAccentColor().withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getAccentColor().withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (context, child) {
                          return Text(
                            _scoreAnimation.value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      Text(
                        'Poin',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Badge
              if (_getPerformanceLevel() != 'Perlu Belajar Lagi')
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _badgeController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _badgeRotationAnimation.value,
                        child: Transform.scale(
                          scale: _badgeScaleAnimation.value,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.star,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _getPerformanceLevel(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _getAccentColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getPerformanceMessage(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final accuracy = (widget.result.correctAnswers / widget.result.totalQuestions * 100).round();
    final timeMinutes = widget.result.timeSpent ~/ 60;
    final timeSeconds = widget.result.timeSpent % 60;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Quiz',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: LucideIcons.target,
                  label: 'Akurasi',
                  value: '$accuracy%',
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: LucideIcons.checkCircle,
                  label: 'Benar',
                  value: '${widget.result.correctAnswers}/${widget.result.totalQuestions}',
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: LucideIcons.clock,
                  label: 'Waktu',
                  value: '${timeMinutes}m ${timeSeconds}s',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: LucideIcons.zap,
                  label: 'Skor',
                  value: widget.result.score.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Performa',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildPerformanceBar(),
          const SizedBox(height: 16),
          Text(
            _getDetailedFeedback(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar() {
    final accuracy = widget.result.correctAnswers / widget.result.totalQuestions;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tingkat Pemahaman',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              '${(accuracy * 100).round()}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getAccentColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: accuracy,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_getAccentColor(), _getAccentColor().withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const QuizScreen(),
              ),
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Kembali ke Quiz',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFF4F46E5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Kembali ke Beranda',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor() {
    final accuracy = widget.result.correctAnswers / widget.result.totalQuestions;
    if (accuracy >= 0.8) {
      return const Color(0xFF10B981); // Green
    } else if (accuracy >= 0.6) {
      return const Color(0xFF3B82F6); // Blue
    } else if (accuracy >= 0.4) {
      return const Color(0xFFF59E0B); // Orange
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }

  Color _getAccentColor() {
    final accuracy = widget.result.correctAnswers / widget.result.totalQuestions;
    if (accuracy >= 0.8) {
      return const Color(0xFF10B981); // Green
    } else if (accuracy >= 0.6) {
      return const Color(0xFF3B82F6); // Blue
    } else if (accuracy >= 0.4) {
      return const Color(0xFFF59E0B); // Orange
    } else {
      return const Color(0xFFEF4444); // Red
    }
  }

  String _getPerformanceLevel() {
    final accuracy = widget.result.correctAnswers / widget.result.totalQuestions;
    if (accuracy >= 0.8) {
      return 'Luar Biasa!';
    } else if (accuracy >= 0.6) {
      return 'Bagus!';
    } else if (accuracy >= 0.4) {
      return 'Cukup Baik';
    } else {
      return 'Perlu Belajar Lagi';
    }
  }

  String _getPerformanceMessage() {
    final accuracy = widget.result.correctAnswers / widget.result.totalQuestions;
    if (accuracy >= 0.8) {
      return 'Kamu menguasai materi dengan sangat baik! Pertahankan semangat belajarmu.';
    } else if (accuracy >= 0.6) {
      return 'Pemahaman kamu sudah cukup baik. Terus berlatih untuk hasil yang lebih optimal.';
    } else if (accuracy >= 0.4) {
      return 'Masih ada ruang untuk perbaikan. Coba pelajari kembali materi yang belum dikuasai.';
    } else {
      return 'Jangan menyerah! Pelajari kembali materi dan coba lagi untuk hasil yang lebih baik.';
    }
  }

  String _getDetailedFeedback() {
    final accuracy = widget.result.correctAnswers / widget.result.totalQuestions;
    final timePerQuestion = widget.result.timeSpent / widget.result.totalQuestions;
    
    String feedback = '';
    
    if (accuracy >= 0.8) {
      feedback += 'Tingkat akurasi kamu sangat tinggi. ';
    } else if (accuracy >= 0.6) {
      feedback += 'Tingkat akurasi kamu cukup baik. ';
    } else {
      feedback += 'Tingkat akurasi perlu ditingkatkan. ';
    }
    
    if (timePerQuestion <= 30) {
      feedback += 'Kamu juga menjawab dengan cepat dan efisien.';
    } else if (timePerQuestion <= 60) {
      feedback += 'Waktu pengerjaan kamu cukup optimal.';
    } else {
      feedback += 'Cobalah untuk menjawab lebih cepat di quiz berikutnya.';
    }
    
    return feedback;
  }
}