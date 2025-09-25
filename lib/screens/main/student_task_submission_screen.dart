import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

class StudentTaskSubmissionScreen extends StatefulWidget {
  const StudentTaskSubmissionScreen({super.key});

  @override
  State<StudentTaskSubmissionScreen> createState() => _StudentTaskSubmissionScreenState();
}

class _StudentTaskSubmissionScreenState extends State<StudentTaskSubmissionScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  List<AdminTask> _tasks = [];
  bool _isLoading = true;
  String? _currentClassCode;
  String? _currentStudentId;
  String? _currentStudentName;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      _currentClassCode = userProfile?.classCode;
      _currentStudentId = _authService.currentUser?.uid;
      
      if (_currentStudentId != null) {
        final student = await _adminService.getStudentById(_currentStudentId!);
        if (student != null) {
          _currentStudentName = student.name;
          _currentClassCode = student.classCodeId;
        }
      }
      
      if (_currentClassCode != null) {
        await _loadTasks();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showNoClassCodeDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat data siswa: $e');
    }
  }

  Future<void> _loadTasks() async {
    if (_currentClassCode == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _adminService.getTasksByClassCode(_currentClassCode!);
      setState(() {
        _tasks = tasks.where((task) => 
          task.isActive && 
          task.tanggalBerakhir.isAfter(DateTime.now())
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat tugas: $e');
    }
  }

  List<AdminTask> get _filteredTasks {
    List<AdminTask> filtered = _tasks;
    
    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) =>
        task.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        task.mataPelajaran.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        task.deskripsi.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filter berdasarkan status
    if (_selectedFilter != 'Semua') {
      final now = DateTime.now();
      switch (_selectedFilter) {
        case 'Aktif':
          filtered = filtered.where((task) => 
            task.tanggalDibuka.isBefore(now) && 
            task.tanggalBerakhir.isAfter(now)
          ).toList();
          break;
        case 'Akan Datang':
          filtered = filtered.where((task) => 
            task.tanggalDibuka.isAfter(now)
          ).toList();
          break;
        case 'Sudah Dikumpulkan':
          filtered = filtered.where((task) => 
            task.submissions.any((submission) => 
              submission.studentId == _currentStudentId
            )
          ).toList();
          break;
        case 'Belum Dikumpulkan':
          filtered = filtered.where((task) => 
            !task.submissions.any((submission) => 
              submission.studentId == _currentStudentId
            )
          ).toList();
          break;
      }
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Pengumpulan Tugas",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Color(0xFF4F46E5)),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilter(),
                Expanded(
                  child: _filteredTasks.isEmpty
                      ? _buildEmptyState()
                      : _buildTasksList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari tugas...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Semua',
                'Aktif',
                'Akan Datang',
                'Sudah Dikumpulkan',
                'Belum Dikumpulkan',
              ].map((filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    filter,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _selectedFilter == filter
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: const Color(0xFFF1F5F9),
                  selectedColor: const Color(0xFF4F46E5),
                  checkmarkColor: Colors.white,
                  side: BorderSide.none,
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(AdminTask task) {
    final now = DateTime.now();
    final isActive = task.tanggalDibuka.isBefore(now) && task.tanggalBerakhir.isAfter(now);
    final isUpcoming = task.tanggalDibuka.isAfter(now);
    final hasSubmitted = task.submissions.any((submission) => 
      submission.studentId == _currentStudentId
    );
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (hasSubmitted) {
      statusColor = const Color(0xFF10B981);
      statusText = 'Sudah Dikumpulkan';
      statusIcon = LucideIcons.checkCircle;
    } else if (isUpcoming) {
      statusColor = const Color(0xFF3B82F6);
      statusText = 'Akan Datang';
      statusIcon = LucideIcons.clock;
    } else if (isActive) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Aktif';
      statusIcon = LucideIcons.alertCircle;
    } else {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Berakhir';
      statusIcon = LucideIcons.xCircle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  task.mataPelajaran,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              task.judul,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              task.deskripsi,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Dates
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Dibuka: ${_formatDate(task.tanggalDibuka)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Berakhir: ${_formatDate(task.tanggalBerakhir)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            
            if ((task.linkSoal?.isNotEmpty ?? false) || (task.linkPdf?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (task.linkSoal?.isNotEmpty ?? false)
                    _buildLinkButton('Soal', task.linkSoal!, LucideIcons.fileText),
                  if ((task.linkSoal?.isNotEmpty ?? false) && (task.linkPdf?.isNotEmpty ?? false))
                    const SizedBox(width: 8),
                  if (task.linkPdf?.isNotEmpty ?? false)
                    _buildLinkButton('PDF', task.linkPdf!, LucideIcons.file),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasSubmitted 
                    ? () => _showSubmissionDetails(task)
                    : (isActive ? () => _showSubmissionDialog(task) : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSubmitted 
                      ? const Color(0xFF10B981)
                      : (isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8)),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasSubmitted 
                          ? LucideIcons.eye
                          : (isActive ? LucideIcons.upload : LucideIcons.clock),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasSubmitted 
                          ? 'Lihat Pengumpulan'
                          : (isActive ? 'Kumpulkan Tugas' : 'Belum Aktif'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkButton(String label, String url, IconData icon) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _openUrl(url),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F46E5),
          side: const BorderSide(color: Color(0xFF4F46E5)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.fileText,
            size: 80,
            color: const Color(0xFF64748B).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "Tidak Ada Tugas",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Belum ada tugas yang tersedia untuk kelas Anda",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSubmissionDialog(AdminTask task) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Kumpulkan Tugas',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tugas: ${task.judul}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title Field
              Text(
                'Judul Pengumpulan *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Masukkan judul pengumpulan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description Field
              Text(
                'Deskripsi *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Jelaskan tentang pengumpulan Anda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Link Field
              Text(
                'Link Pengumpulan *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'https://drive.google.com/...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _submitTask(
              task,
              titleController.text,
              descriptionController.text,
              linkController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Kumpulkan',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDetails(AdminTask task) {
    final submission = task.submissions.firstWhere(
      (s) => s.studentId == _currentStudentId,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detail Pengumpulan',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tugas', task.judul),
              _buildDetailRow('Judul', submission.title),
              _buildDetailRow('Deskripsi', submission.description),
              _buildDetailRow('Dikumpulkan', _formatDate(submission.submittedAt)),
              if (submission.score != null)
                _buildDetailRow('Nilai', '${submission.score}/100'),
              if (submission.feedback != null && submission.feedback!.isNotEmpty)
                _buildDetailRow('Feedback', submission.feedback!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openUrl(submission.link),
                  child: Text(
                    'Buka Link Pengumpulan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTask(AdminTask task, String title, String description, String link) async {
    if (title.trim().isEmpty || description.trim().isEmpty || link.trim().isEmpty) {
      _showErrorSnackBar('Semua field harus diisi');
      return;
    }
    
    if (_currentStudentId == null || _currentStudentName == null) {
      _showErrorSnackBar('Data siswa tidak ditemukan');
      return;
    }

    Navigator.pop(context); // Close dialog
    
    try {
      final submission = StudentSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        taskId: task.id,
        studentId: _currentStudentId!,
        studentName: _currentStudentName!,
        title: title.trim(),
        description: description.trim(),
        link: link.trim(),
        submittedAt: DateTime.now(),
      );
      
      final updatedTask = task.copyWith(
        submissions: [...task.submissions, submission],
      );
      
      final success = await _adminService.updateTask(task.id, updatedTask);
      
      if (success) {
        _showSuccessSnackBar('Tugas berhasil dikumpulkan!');
        await _loadTasks(); // Refresh tasks
      } else {
        _showErrorSnackBar('Gagal mengumpulkan tugas');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  void _openUrl(String url) {
    // TODO: Implement URL launcher
    _showErrorSnackBar('Fitur buka link akan segera tersedia');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showNoClassCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Kelas Tidak Ditemukan',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Anda belum terdaftar dalam kelas manapun. Silakan hubungi guru atau admin untuk mendaftarkan Anda ke dalam kelas.',
          style: GoogleFonts.poppins(
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}