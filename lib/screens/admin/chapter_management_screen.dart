import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/chapter_models.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/chapter_service.dart';
import '../../services/admin_service.dart';
import 'quiz_management_screen.dart';

class ChapterManagementScreen extends StatefulWidget {
  const ChapterManagementScreen({super.key});

  @override
  State<ChapterManagementScreen> createState() => _ChapterManagementScreenState();
}

class _ChapterManagementScreenState extends State<ChapterManagementScreen> {
  final ChapterService _chapterService = ChapterService();
  final AdminService _adminService = AdminService();
  List<ChapterSummary> _chapterSummaries = [];
  List<Subject> _subjects = [];
  List<ClassCode> _classCodes = [];
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
        print('Starting to load data...');
      }
      
      // Load subjects first
      if (kDebugMode) {
        print('Loading subjects...');
      }
      final subjects = await _adminService.getAllSubjects();
      if (!mounted) return;
      if (kDebugMode) {
        print('Loaded ${subjects.length} subjects');
      }
      
      // Load class codes
      if (kDebugMode) {
        print('Loading class codes...');
      }
      final classCodes = await _adminService.getAllClassCodes();
      if (!mounted) return;
      if (kDebugMode) {
        print('Loaded ${classCodes.length} class codes');
      }
      
      // Load chapters
      if (kDebugMode) {
        print('Loading chapters...');
      }
      final chapters = await _chapterService.getAllChapters();
      if (!mounted) return;
      if (kDebugMode) {
        print('Loaded ${chapters.length} chapters');
      }
      
      // Create chapter summaries
      final summaries = <ChapterSummary>[];
      for (final chapter in chapters) {
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
        _subjects = subjects;
        _classCodes = classCodes;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('Data loading completed successfully');
        print('Final state: ${summaries.length} chapters, ${subjects.length} subjects, ${classCodes.length} class codes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
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
      appBar: AppBar(
        title: const Text('Manajemen Bab'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
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
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChapters.isEmpty
                    ? _buildEmptyState()
                    : _buildChapterList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChapterDialog(),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Belum ada bab' : 'Bab tidak ditemukan',
            style: TextStyle(
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredChapters.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty 
                    ? 'Belum ada bab yang tersedia\nTarik ke bawah untuk refresh'
                    : 'Tidak ada bab yang sesuai dengan pencarian',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                if (kDebugMode) ...[
                  Text(
                    'Debug Info:',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total chapters loaded: ${_chapterSummaries.length}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  Text(
                    'Subjects loaded: ${_subjects.length}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  Text(
                    'Class codes loaded: ${_classCodes.length}',
                    style: TextStyle(color: Colors.red[600]),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${chapter.subjectName} • ${chapter.classCode}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
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
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
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
                  style: TextStyle(
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
                    icon: Icons.quiz,
                    label: '${summary.totalQuizzes} Kuis',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                     icon: Icons.help_outline,
                     label: '${summary.totalQuestions} Soal',
                     color: Colors.orange,
                   ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.star_outline,
                    label: '${summary.totalPoints} Poin',
                    color: Colors.purple,
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
            style: TextStyle(
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
      print('ChapterManagement: Navigating to QuizManagement with chapter ID: ${chapter.id}');
      print('ChapterManagement: Chapter title: ${chapter.title}');
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
      final subject = _subjects.firstWhere(
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
      final classCode = _classCodes.firstWhere(
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
          title: Text(isEdit ? 'Edit Bab' : 'Tambah Bab Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Bab *',
                    hintText: 'Contoh: Bab 1 – Aljabar Dasar',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Bab (Opsional)',
                    hintText: 'Deskripsi singkat tentang bab ini',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran *',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Pilih Mata Pelajaran'),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject.id,
                      child: Text(subject.name),
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
                  decoration: const InputDecoration(
                    labelText: 'Kode Kelas *',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Pilih Kode Kelas'),
                  items: _classCodes.map((classCode) {
                    return DropdownMenuItem<String>(
                      value: classCode.id,
                      child: Text('${classCode.name} (${classCode.code})'),
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
              child: const Text('Batal'),
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
              child: Text(isEdit ? 'Update' : 'Simpan'),
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
          const SnackBar(content: Text('Mohon isi judul bab')),
        );
      }
      return;
    }

    if (selectedSubjectId == null || selectedSubjectId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih mata pelajaran')),
        );
      }
      return;
    }

    if (selectedClassCodeId == null || selectedClassCodeId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih kode kelas')),
        );
      }
      return;
    }

    Navigator.pop(context);

    try {
      // Get subject and class code names for backward compatibility
      final subject = _subjects.firstWhere((s) => s.id == selectedSubjectId);
      final classCode = _classCodes.firstWhere((cc) => cc.id == selectedClassCodeId);

      final chapter = Chapter(
        id: chapterId ?? '',
        title: title.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        subjectName: subject.name,
        classCode: classCode.code,
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
            SnackBar(content: Text('Bab berhasil ${isEdit ? 'diupdate' : 'ditambahkan'}')),
          );
        }
        _loadData();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal ${isEdit ? 'mengupdate' : 'menambahkan'} bab')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _confirmDeleteChapter(Chapter chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus bab ini? Semua kuis dan soal dalam bab ini akan ikut terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteChapter(context, chapter),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
            const SnackBar(content: Text('Bab berhasil dihapus')),
          );
        }
        _loadData();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus bab')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}