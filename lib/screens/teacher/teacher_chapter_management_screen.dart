import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/chapter_models.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/chapter_service.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../admin/quiz_management_screen.dart';

class TeacherChapterManagementScreen extends StatefulWidget {
  const TeacherChapterManagementScreen({super.key});

  @override
  State<TeacherChapterManagementScreen> createState() => _TeacherChapterManagementScreenState();
}

class _TeacherChapterManagementScreenState extends State<TeacherChapterManagementScreen> {
  final ChapterService _chapterService = ChapterService();
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  List<ChapterSummary> _chapterSummaries = [];
  List<Subject> _teacherSubjects = [];
  List<ClassCode> _schoolClassCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('Starting to load teacher chapter data...');
      }
      
      // Load current teacher first
      final teacher = await _authService.getCurrentTeacher();
      if (teacher == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Teacher data not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (!mounted) return;
      
      if (kDebugMode) {
        print('Teacher loaded: ${teacher.name}, School: ${teacher.schoolId}');
        print('Teacher subjects: ${teacher.subjectIds}');
      }
      
      // Load all subjects and filter by teacher's subjects
      final allSubjects = await _adminService.getAllSubjects();
      final teacherSubjects = allSubjects.where((subject) => 
        teacher.subjectIds.contains(subject.id) && 
        subject.schoolId == teacher.schoolId
      ).toList();
      
      if (!mounted) return;
      if (kDebugMode) {
        print('Loaded ${teacherSubjects.length} teacher subjects');
      }
      
      // Load class codes for the teacher's school
      final allClassCodes = await _adminService.getAllClassCodes();
      final schoolClassCodes = allClassCodes.where((classCode) => 
        classCode.schoolId == teacher.schoolId
      ).toList();
      
      if (!mounted) return;
      if (kDebugMode) {
        print('Loaded ${schoolClassCodes.length} school class codes');
      }
      
      // Load chapters and filter by teacher's subjects
      final allChapters = await _chapterService.getAllChapters();
      final teacherSubjectNames = teacherSubjects.map((s) => s.name).toSet();
      final filteredChapters = allChapters.where((chapter) => 
        teacherSubjectNames.contains(chapter.subjectName)
      ).toList();
      
      if (!mounted) return;
      if (kDebugMode) {
        print('Loaded ${filteredChapters.length} filtered chapters');
      }
      
      // Create chapter summaries
      final summaries = <ChapterSummary>[];
      for (final chapter in filteredChapters) {
        if (!mounted) return;
        try {
          final summary = await _chapterService.getChapterSummary(chapter.id);
          if (!mounted) return;
          summaries.add(summary);
        } catch (e) {
          if (kDebugMode) {
            print('Error loading summary for chapter ${chapter.id}: $e');
          }
          // Create a basic summary if detailed summary fails
          summaries.add(ChapterSummary(
            chapter: chapter,
            totalQuizzes: 0,
            totalQuestions: 0,
            totalPoints: 0,
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _chapterSummaries = summaries;
        _teacherSubjects = teacherSubjects;
        _schoolClassCodes = schoolClassCodes;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('Teacher chapter data loading completed successfully');
        print('Final state: ${summaries.length} chapters, ${teacherSubjects.length} subjects, ${schoolClassCodes.length} class codes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading teacher chapter data: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _searchQuery = '';

  List<ChapterSummary> get _filteredChapters {
    if (_searchQuery.isEmpty) return _chapterSummaries;
    return _chapterSummaries.where((summary) {
      final chapter = summary.chapter;
      return chapter.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             chapter.subjectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             chapter.classCode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF1F2937),
          ),
        ),
        title: Text(
          'Kelola Bab',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              onChanged: (value) {
                if (mounted) {
                  setState(() => _searchQuery = value);
                }
              },
              decoration: InputDecoration(
                hintText: 'Cari bab, mata pelajaran, atau kelas...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  color: Color(0xFF10B981),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
                  ))
                : _filteredChapters.isEmpty
                    ? _buildEmptyState()
                    : _buildChapterList(),
          ),
        ],
      ),
      floatingActionButton: _teacherSubjects.isEmpty || _schoolClassCodes.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _showChapterDialog(),
              backgroundColor: const Color(0xFF10B981),
              child: const Icon(LucideIcons.plus, color: Colors.white),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.book,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Belum ada bab' : 'Bab tidak ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Tambahkan bab pertama dengan menekan tombol +'
                : 'Coba kata kunci lain',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_teacherSubjects.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Anda belum memiliki mata pelajaran.\nHubungi admin untuk menambahkan mata pelajaran.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(
        color: Color(0xFF10B981),
      ));
    }

    if (_filteredChapters.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF10B981),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.book,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty 
                    ? 'Belum ada bab yang tersedia\nTarik ke bawah untuk refresh'
                    : 'Tidak ada bab yang sesuai dengan pencarian',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                if (kDebugMode) ...[
                  Text(
                    'Debug Info:',
                    style: GoogleFonts.poppins(
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total chapters loaded: ${_chapterSummaries.length}',
                    style: GoogleFonts.poppins(color: Colors.red[600]),
                  ),
                  Text(
                    'Teacher subjects loaded: ${_teacherSubjects.length}',
                    style: GoogleFonts.poppins(color: Colors.red[600]),
                  ),
                  Text(
                    'School class codes loaded: ${_schoolClassCodes.length}',
                    style: GoogleFonts.poppins(color: Colors.red[600]),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF10B981),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredChapters.length,
        itemBuilder: (context, index) {
          final summary = _filteredChapters[index];
          return _buildChapterCard(summary);
        },
      ),
    );
  }

  Widget _buildChapterCard(ChapterSummary summary) {
    final chapter = summary.chapter;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToQuizManagement(chapter),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${chapter.subjectName} • ${chapter.classCode}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showChapterDialog(chapter: chapter);
                          break;
                        case 'delete':
                          _confirmDeleteChapter(chapter);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: GoogleFonts.poppins(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Hapus',
                              style: GoogleFonts.poppins(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Description
              if (chapter.description != null && chapter.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  chapter.description!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Statistics
              Row(
                children: [
                  _buildStatChip(
                    icon: LucideIcons.fileQuestion,
                    label: '${summary.totalQuizzes} Kuis',
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                     icon: LucideIcons.helpCircle,
                     label: '${summary.totalQuestions} Soal',
                     color: const Color(0xFFF59E0B),
                   ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: LucideIcons.star,
                    label: '${summary.totalPoints} Poin',
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
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
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToQuizManagement(Chapter chapter) {
    // Debug print untuk memastikan chapter ID tersedia
    if (kDebugMode) {
      print('TeacherChapterManagement: Navigating to QuizManagement with chapter ID: ${chapter.id}');
      print('TeacherChapterManagement: Chapter title: ${chapter.title}');
    }
    
    // Validasi chapter ID sebelum navigasi - harus berupa string yang valid
    if (chapter.id.isEmpty || chapter.id.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Chapter ID tidak valid. Silakan refresh halaman dan coba lagi.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    
    // Validasi tambahan untuk memastikan ID adalah string yang valid (bukan angka)
    final chapterId = chapter.id.trim();
    if (chapterId.length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Chapter ID terlalu pendek. Silakan refresh halaman.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizManagementScreen(
          chapter: chapter,
          chapterId: chapterId, // Kirim ID yang sudah divalidasi
        ),
      ),
    ).then((_) => _loadData()); // Refresh when returning
  }

  void _showChapterDialog({Chapter? chapter}) {
    final isEdit = chapter != null;
    final titleController = TextEditingController(text: chapter?.title ?? '');
    final descriptionController = TextEditingController(text: chapter?.description ?? '');
    
    // Find selected subject and class code based on chapter data
    String? selectedSubjectId;
    String? selectedClassCodeId;
    
    if (chapter != null) {
      // Find subject by name (for backward compatibility)
      final subject = _teacherSubjects.firstWhere(
        (s) => s.name == chapter.subjectName,
        orElse: () => Subject(
          id: '',
          name: '',
          description: '',
          code: '',
          schoolId: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (subject.id.isNotEmpty) {
        selectedSubjectId = subject.id;
      }
      
      // Find class code by code (for backward compatibility)
      final classCode = _schoolClassCodes.firstWhere(
        (cc) => cc.code == chapter.classCode,
        orElse: () => ClassCode(
          id: '',
          code: '',
          name: '',
          description: '',
          teacherId: '',
          schoolId: '',
          createdAt: DateTime.now(),
        ),
      );
      if (classCode.id.isNotEmpty) {
        selectedClassCodeId = classCode.id;
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEdit ? 'Edit Bab' : 'Tambah Bab Baru',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Judul Bab *',
                    labelStyle: GoogleFonts.poppins(),
                    hintText: 'Contoh: Bab 1 – Aljabar Dasar',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Bab (Opsional)',
                    labelStyle: GoogleFonts.poppins(),
                    hintText: 'Deskripsi singkat tentang bab ini',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: 'Mata Pelajaran *',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                  hint: Text(
                    'Pilih Mata Pelajaran',
                    style: GoogleFonts.poppins(color: Colors.grey[500]),
                  ),
                  items: _teacherSubjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject.id,
                      child: Text(
                        subject.name,
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSubjectId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih mata pelajaran';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClassCodeId,
                  decoration: InputDecoration(
                    labelText: 'Kode Kelas *',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                  hint: Text(
                    'Pilih Kode Kelas',
                    style: GoogleFonts.poppins(color: Colors.grey[500]),
                  ),
                  items: _schoolClassCodes.map((classCode) {
                    return DropdownMenuItem<String>(
                      value: classCode.id,
                      child: Text(
                        '${classCode.name} (${classCode.code})',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedClassCodeId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih kode kelas';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => _saveChapter(
                context,
                isEdit,
                chapter?.id,
                titleController.text,
                descriptionController.text,
                selectedSubjectId,
                selectedClassCodeId,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: Text(
                isEdit ? 'Update' : 'Simpan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChapter(
    BuildContext context,
    bool isEdit,
    String? chapterId,
    String title,
    String description,
    String? selectedSubjectId,
    String? selectedClassCodeId,
  ) async {
    if (title.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mohon isi judul bab',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (selectedSubjectId == null || selectedSubjectId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mohon pilih mata pelajaran',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (selectedClassCodeId == null || selectedClassCodeId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mohon pilih kode kelas',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    Navigator.pop(context);

    try {
      // Get subject and class code names for backward compatibility
      final subject = _teacherSubjects.firstWhere((s) => s.id == selectedSubjectId);
      final classCode = _schoolClassCodes.firstWhere((cc) => cc.id == selectedClassCodeId);

      final chapter = Chapter(
        id: chapterId ?? '',
        title: title.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        subjectName: subject.name,
        classCode: classCode.code,
        schoolId: subject.schoolId,
        teacherId: classCode.teacherId, // Use teacherId from classCode
        createdAt: isEdit ? _chapterSummaries.firstWhere((s) => s.chapter.id == chapterId).chapter.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      bool success;
      if (isEdit) {
        success = await _chapterService.updateChapter(chapterId!, chapter);
      } else {
        final id = await _chapterService.createChapter(chapter);
        success = id != null;
      }

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bab berhasil ${isEdit ? 'diupdate' : 'ditambahkan'}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        _loadData();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal ${isEdit ? 'mengupdate' : 'menambahkan'} bab',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteChapter(Chapter chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Hapus',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus bab ini? Semua kuis dan soal dalam bab ini akan ikut terhapus.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteChapter(context, chapter),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChapter(BuildContext context, Chapter chapter) async {
    Navigator.pop(context);

    try {
      final success = await _chapterService.deleteChapter(chapter.id);
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bab berhasil dihapus',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        _loadData();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menghapus bab',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}