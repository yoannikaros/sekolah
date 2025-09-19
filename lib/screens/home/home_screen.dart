import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang!',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                   color: AppColors.white.withValues(alpha: 0.9),
                                 ),
                              ),
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return Text(
                                    authProvider.user?.fullName ?? 'User',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: AppColors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  // TODO: Implement notifications
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fitur notifikasi akan segera hadir'),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.white,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.white,
                                ),
                                onSelected: (value) {
                                  if (value == 'logout') {
                                    _showLogoutDialog(context);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'profile',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_outline),
                                        SizedBox(width: 8),
                                        Text('Profil'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'settings',
                                    child: Row(
                                      children: [
                                        Icon(Icons.settings_outlined),
                                        SizedBox(width: 8),
                                        Text('Pengaturan'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout),
                                        SizedBox(width: 8),
                                        Text('Keluar'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Quick Stats
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Peran Anda',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                           color: AppColors.white.withValues(alpha: 0.8),
                                         ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getRoleDisplayName(authProvider.user?.role ?? ''),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.white.withValues(alpha: 0.3),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Status',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                           color: AppColors.white.withValues(alpha: 0.8),
                                         ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Aktif',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Main Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    Text(
                      'Aksi Cepat',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildQuickActionCard(
                          context,
                          icon: Icons.quiz_outlined,
                          title: 'Quiz Center',
                          subtitle: 'Latihan soal interaktif',
                          color: AppColors.primary,
                          onTap: () => context.go('/quiz'),
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.event_outlined,
                          title: 'Event Planner',
                          subtitle: 'Jadwal kegiatan sekolah',
                          color: AppColors.secondary,
                          onTap: () => context.go('/events'),
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.article_outlined,
                          title: 'Mading Online',
                          subtitle: 'Karya dan pengumuman',
                          color: AppColors.accent,
                          onTap: () => context.go('/mading'),
                        ),
                        _buildQuickActionCard(
                          context,
                          icon: Icons.photo_library_outlined,
                          title: 'Galeri Foto',
                          subtitle: 'Album kegiatan sekolah',
                          color: AppColors.info,
                          onTap: () => context.go('/gallery'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Recent Activities
                    Text(
                      'Aktivitas Terbaru',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildActivityCard(
                      context,
                      icon: Icons.quiz,
                      title: 'Quiz Matematika Dasar',
                      subtitle: 'Selesaikan quiz untuk mendapatkan badge',
                      time: '2 jam yang lalu',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(
                      context,
                      icon: Icons.event,
                      title: 'Pertemuan Orang Tua',
                      subtitle: 'Jadwal konsultasi dengan wali kelas',
                      time: '1 hari yang lalu',
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 12),
                    _buildActivityCard(
                      context,
                      icon: Icons.photo,
                      title: 'Album Kegiatan Olahraga',
                      subtitle: '25 foto baru ditambahkan',
                      time: '3 hari yang lalu',
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                 icon,
                 color: color,
                 size: 20,
               ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            context.go('/chat');
            break;
          case 2:
            context.go('/quiz');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_outlined),
          activeIcon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz_outlined),
          activeIcon: Icon(Icons.quiz),
          label: 'Quiz',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'student':
        return 'Siswa';
      case 'teacher':
        return 'Guru';
      case 'parent':
        return 'Orang Tua';
      case 'school_admin':
        return 'Admin Sekolah';
      case 'owner':
        return 'Pemilik';
      default:
        return 'User';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }
}