import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/leaderboard_models.dart';
import '../../services/leaderboard_service.dart';
import '../../services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final AuthService _authService = AuthService();
  
  ClassLeaderboard? _leaderboard;
  bool _isLoading = true;
  String? _error;
  String? _currentStudentId;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current student info
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final studentData = await _authService.getStudentData(currentUser.uid);
      if (studentData == null) {
        setState(() {
          _error = 'Data siswa tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      _currentStudentId = studentData.id;
      final classCodeId = studentData.classCodeId;

      if (classCodeId.isEmpty) {
        setState(() {
          _error = 'Kelas tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      // Get leaderboard for the class
      final leaderboard = await _leaderboardService.getClassLeaderboard(classCodeId);
      
      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Gagal memuat leaderboard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Leaderboard Kelas',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF64748B)),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_leaderboard == null || _leaderboard!.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.trophy,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data leaderboard',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai mengerjakan quiz untuk muncul di leaderboard',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassInfo(),
            const SizedBox(height: 24),
            _buildTopThree(),
            const SizedBox(height: 24),
            _buildAllRankings(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfo() {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.users,
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
                  _leaderboard!.classCodeName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_leaderboard!.totalStudents} siswa • ${_leaderboard!.totalQuizzes} quiz',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rata-rata skor: ${_leaderboard!.averageScore.toStringAsFixed(1)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree() {
    final topThree = _leaderboard!.entries.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top 3 Siswa',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Second place
            if (topThree.length > 1)
              Expanded(child: _buildPodiumCard(topThree[1], 2)),
            const SizedBox(width: 8),
            // First place
            if (topThree.isNotEmpty)
              Expanded(child: _buildPodiumCard(topThree[0], 1)),
            const SizedBox(width: 8),
            // Third place
            if (topThree.length > 2)
              Expanded(child: _buildPodiumCard(topThree[2], 3)),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumCard(LeaderboardEntry entry, int position) {
    final colors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };

    final heights = {1: 120.0, 2: 100.0, 3: 80.0};
    final isCurrentStudent = entry.studentId == _currentStudentId;

    return Container(
      height: heights[position],
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentStudent 
            ? Border.all(color: const Color(0xFF4F46E5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: entry.profileImageUrl != null 
                    ? NetworkImage(entry.profileImageUrl!)
                    : null,
                child: entry.profileImageUrl == null
                    ? Text(
                        entry.studentName.isNotEmpty 
                            ? entry.studentName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors[position],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '$position',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.studentName,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.totalScore} poin',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors[position],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllRankings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semua Peringkat',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _leaderboard!.entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = _leaderboard!.entries[index];
            return _buildRankingCard(entry);
          },
        ),
      ],
    );
  }

  Widget _buildRankingCard(LeaderboardEntry entry) {
    final isCurrentStudent = entry.studentId == _currentStudentId;
    final isTopThree = entry.rank <= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentStudent 
            ? Border.all(color: const Color(0xFF4F46E5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isTopThree 
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isTopThree ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Profile picture
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: entry.profileImageUrl != null 
                ? NetworkImage(entry.profileImageUrl!)
                : null,
            child: entry.profileImageUrl == null
                ? Text(
                    entry.studentName.isNotEmpty 
                        ? entry.studentName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentStudent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Anda',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${entry.totalQuizzes} quiz',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.accuracy.toStringAsFixed(1)}% akurasi',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalScore}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              Text(
                'poin',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}