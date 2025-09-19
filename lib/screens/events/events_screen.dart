import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Event Planner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDatePicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEventDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hari Ini'),
            Tab(text: 'Mendatang'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayEvents(),
          _buildUpcomingEvents(),
          _buildCompletedEvents(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayEvents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hari Ini',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: AppColors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '3 acara hari ini',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Today's Events
          _buildEventCard(
            context,
            title: 'Rapat Guru',
            time: '08:00 - 10:00',
            location: 'Ruang Guru',
            type: 'meeting',
            status: 'ongoing',
            description: 'Rapat koordinasi mingguan dengan seluruh guru',
          ),
          
          _buildEventCard(
            context,
            title: 'Ujian Matematika',
            time: '10:30 - 12:00',
            location: 'Kelas 9A',
            type: 'exam',
            status: 'upcoming',
            description: 'Ujian tengah semester mata pelajaran matematika',
          ),
          
          _buildEventCard(
            context,
            title: 'Ekstrakurikuler Basket',
            time: '15:00 - 17:00',
            location: 'Lapangan Basket',
            type: 'activity',
            status: 'upcoming',
            description: 'Latihan rutin ekstrakurikuler basket',
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acara Mendatang',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // This Week
          _buildSectionHeader('Minggu Ini'),
          _buildEventCard(
            context,
            title: 'Pertemuan Orang Tua',
            time: '19:00 - 21:00',
            location: 'Aula Sekolah',
            type: 'meeting',
            status: 'scheduled',
            description: 'Pertemuan rutin dengan orang tua siswa',
            date: 'Besok',
          ),
          
          _buildEventCard(
            context,
            title: 'Lomba Karya Tulis',
            time: '08:00 - 15:00',
            location: 'Perpustakaan',
            type: 'competition',
            status: 'scheduled',
            description: 'Lomba karya tulis ilmiah tingkat sekolah',
            date: 'Jumat, 19 Jan',
          ),
          
          const SizedBox(height: 20),
          
          // Next Week
          _buildSectionHeader('Minggu Depan'),
          _buildEventCard(
            context,
            title: 'Study Tour',
            time: '07:00 - 18:00',
            location: 'Museum Nasional',
            type: 'trip',
            status: 'scheduled',
            description: 'Kunjungan edukatif ke Museum Nasional Jakarta',
            date: 'Senin, 22 Jan',
          ),
          
          _buildEventCard(
            context,
            title: 'Pelatihan Guru',
            time: '13:00 - 16:00',
            location: 'Ruang Multimedia',
            type: 'training',
            status: 'scheduled',
            description: 'Pelatihan penggunaan teknologi dalam pembelajaran',
            date: 'Rabu, 24 Jan',
          ),
          
          _buildEventCard(
            context,
            title: 'Pameran Sains',
            time: '08:00 - 15:00',
            location: 'Halaman Sekolah',
            type: 'exhibition',
            status: 'scheduled',
            description: 'Pameran karya sains siswa-siswi sekolah',
            date: 'Sabtu, 27 Jan',
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedEvents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acara Selesai',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildCompletedEventCard(
            context,
            title: 'Upacara Bendera',
            time: '07:00 - 08:00',
            location: 'Lapangan Sekolah',
            type: 'ceremony',
            date: 'Senin, 15 Jan',
            participants: 450,
          ),
          
          _buildCompletedEventCard(
            context,
            title: 'Workshop Coding',
            time: '13:00 - 16:00',
            location: 'Lab Komputer',
            type: 'workshop',
            date: 'Sabtu, 13 Jan',
            participants: 25,
          ),
          
          _buildCompletedEventCard(
            context,
            title: 'Turnamen Futsal',
            time: '08:00 - 17:00',
            location: 'Lapangan Futsal',
            type: 'competition',
            date: 'Jumat, 12 Jan',
            participants: 120,
          ),
          
          _buildCompletedEventCard(
            context,
            title: 'Seminar Karir',
            time: '09:00 - 12:00',
            location: 'Aula Sekolah',
            type: 'seminar',
            date: 'Kamis, 11 Jan',
            participants: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required String title,
    required String time,
    required String location,
    required String type,
    required String status,
    required String description,
    String? date,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEventDetails(context, title, description),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEventTypeIcon(type),
                      color: _getEventTypeColor(type),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (date != null)
                          Text(
                            date,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedEventCard(
    BuildContext context, {
    required String title,
    required String time,
    required String location,
    required String type,
    required String date,
    required int participants,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$date • $time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$participants peserta',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
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

  IconData _getEventTypeIcon(String type) {
    switch (type) {
      case 'meeting':
        return Icons.groups;
      case 'exam':
        return Icons.quiz;
      case 'activity':
        return Icons.sports_basketball;
      case 'competition':
        return Icons.emoji_events;
      case 'trip':
        return Icons.directions_bus;
      case 'training':
        return Icons.school;
      case 'exhibition':
        return Icons.museum;
      case 'ceremony':
        return Icons.flag;
      case 'workshop':
        return Icons.build;
      case 'seminar':
        return Icons.mic;
      default:
        return Icons.event;
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'meeting':
        return AppColors.primary;
      case 'exam':
        return AppColors.error;
      case 'activity':
        return AppColors.success;
      case 'competition':
        return AppColors.warning;
      case 'trip':
        return AppColors.info;
      case 'training':
        return AppColors.secondary;
      case 'exhibition':
        return AppColors.accent;
      default:
        return AppColors.grey400;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ongoing':
        return AppColors.success;
      case 'upcoming':
        return AppColors.warning;
      case 'scheduled':
        return AppColors.info;
      case 'completed':
        return AppColors.grey400;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ongoing':
        return 'Berlangsung';
      case 'upcoming':
        return 'Segera';
      case 'scheduled':
        return 'Terjadwal';
      case 'completed':
        return 'Selesai';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final days = [
      'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
    ];
    
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tanggal dipilih: ${_formatDate(picked)}'),
          ),
        );
      }
    }
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Acara Baru'),
          content: const Text('Fitur pembuatan acara akan segera tersedia.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur pembuatan acara akan segera hadir'),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showEventDetails(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bergabung dengan acara: $title'),
                  ),
                );
              },
              child: const Text('Bergabung'),
            ),
          ],
        );
      },
    );
  }
}