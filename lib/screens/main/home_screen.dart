import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import 'quiz_screen.dart';
import 'social_media_screen.dart';
import 'student_material_screen.dart';
import 'student_task_submission_screen.dart';
import 'event_planner_student_screen.dart';
import '../chat/chat_room_list_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  final AuthService _authService = AuthService();

  final List<BannerData> _banners = [
    BannerData(
      title: "Selamat Datang",
      subtitle: "Platform belajar terbaik untuk siswa Indonesia",
      color: const Color(0xFF4F46E5),
      icon: LucideIcons.graduationCap,
    ),
    BannerData(
      title: "Belajar Kapan Saja",
      subtitle: "Akses ribuan materi pembelajaran berkualitas",
      color: const Color(0xFF059669),
      icon: LucideIcons.bookOpen,
    ),
    BannerData(
      title: "Raih Prestasi Terbaik",
      subtitle: "Tingkatkan nilai dan kemampuan akademikmu",
      color: const Color(0xFFDC2626),
      icon: LucideIcons.trophy,
    ),
  ];

  final List<MenuData> _menuItems = [
    MenuData(
      name: "Wali Kelas Virtual 0.1",
      description: "Nada ramah, reminder tugas, etika online dasar",
      icon: LucideIcons.userCheck,
      color: const Color(0xFF3B82F6),
      isAvailable: true,
    ),
    MenuData(
      name: "Quiz Interaktif Dasar",
      description: "Baca–tulis–hitung, sains ringan, gamified badge",
      icon: LucideIcons.brain,
      color: const Color(0xFF10B981),
      isAvailable: true,
    ),
    MenuData(
      name: "Mading Online",
      description: "Karya gambar/foto tugas; komentar terkurasi",
      icon: LucideIcons.clipboard,
      color: const Color(0xFF8B5CF6),
      isAvailable: true,
    ),
    MenuData(
      name: "Galeri Foto",
      description: "Album kegiatan kelas, watermark sekolah",
      icon: LucideIcons.camera,
      color: const Color(0xFFF59E0B),
      isAvailable: true,
    ),
    MenuData(
      name: "Room Chat Kelas",
      description: "Mode \"slow mode\", stiker aman; Parent Channel terpisah",
      icon: LucideIcons.messageSquare,
      color: const Color(0xFFEF4444),
      isAvailable: true,
    ),
    MenuData(
      name: "DNA Tracker",
      description: "Minat awal (musik, olahraga, sains) via quiz pendek",
      icon: LucideIcons.dna,
      color: const Color(0xFF06B6D4),
      isAvailable: false,
      badge: "Soon",
    ),
    MenuData(
      name: "Event Planner (Lite)",
      description: "Jadwal pertemuan orang tua, lomba kelas",
      icon: LucideIcons.calendar,
      color: const Color(0xFF84CC16),
      isAvailable: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildBannerSection(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              const SizedBox(height: 30),
              _buildMenuSection(),
              const SizedBox(height: 30),
              _buildRecentActivity(),
              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(LucideIcons.user, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Pagi!",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  "Siswa Seangkatan",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.bell,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [banner.color, banner.color.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(banner.icon, color: Colors.white, size: 32),
                          const SizedBox(height: 12),
                          Text(
                            banner.title,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color:
                    _currentBannerIndex == index
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Aksi Cepat",
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
                child: _buildQuickActionCard(
                  "Tugas Kelas",
                  LucideIcons.video,
                  const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const StudentTaskSubmissionScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  "Materi Kelas",
                  LucideIcons.fileText,
                  const Color(0xFF10B981),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentMaterialScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  "Social Media",
                  LucideIcons.users,
                  const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SocialMediaScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  "Ranking",
                  LucideIcons.trophy,
                  const Color(0xFFEF4444),
                  onTap: () {
                    // TODO: Navigate to ranking screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur Ranking akan segera hadir!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withValues(alpha: 0.15),
                              color.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Menu Utama",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final menuItem = _menuItems[index];
              return GestureDetector(
                onTap: () {
                  if (menuItem.isAvailable) {
                    _handleMenuTap(menuItem.name);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: menuItem.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              menuItem.icon,
                              color: menuItem.color,
                              size: 24,
                            ),
                          ),
                          if (menuItem.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                menuItem.badge!,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        menuItem.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              menuItem.isAvailable
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          menuItem.description,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color:
                                menuItem.isAvailable
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Aktivitas Terbaru",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  "Menyelesaikan Latihan Matematika",
                  "2 jam yang lalu",
                  LucideIcons.checkCircle,
                  const Color(0xFF10B981),
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  "Mengikuti Kelas Live Bahasa Indonesia",
                  "1 hari yang lalu",
                  LucideIcons.video,
                  const Color(0xFF3B82F6),
                ),
                const Divider(height: 24),
                _buildActivityItem(
                  "Diskusi tentang Ekosistem",
                  "2 hari yang lalu",
                  LucideIcons.messageCircle,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuTap(String menuName) async {
    switch (menuName) {
      case "Wali Kelas Virtual 0.1":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIChatScreen()),
        );
        break;
      case "Quiz Interaktif Dasar":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuizScreen()),
        );
        break;
      case "Room Chat Kelas":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatRoomListScreen()),
        );
        break;
      case "Event Planner (Lite)":
        // Get saved class code from Firebase user profile
        String? savedClassCode;
        try {
          final userProfile = await _authService.getCurrentUserProfile();
          savedClassCode = userProfile?.classCode;
        } catch (e) {
          debugPrint('Error retrieving class code: $e');
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      EventPlannerStudentScreen(classCode: savedClassCode),
            ),
          );
        }
        break;
      default:
        // Handle other menu items
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$menuName akan segera tersedia!'),
            backgroundColor: const Color(0xFF4F46E5),
          ),
        );
        break;
    }
  }
}

class BannerData {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  BannerData({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class MenuData {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isAvailable;
  final String? badge;

  MenuData({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isAvailable,
    this.badge,
  });
}