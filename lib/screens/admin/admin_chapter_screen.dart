import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/chapter_models.dart';
import '../../models/chapter_with_details.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/chapter_service.dart';
import '../../services/admin_service.dart';
import 'admin_task_list_screen.dart';

class AdminChapterScreen extends StatefulWidget {
  const AdminChapterScreen({super.key});

  @override
  State<AdminChapterScreen> createState() => _AdminChapterScreenState();
}

class _AdminChapterScreenState extends State<AdminChapterScreen> {
  final ChapterService _chapterService = ChapterService();
  final AdminService _adminService = AdminService();
  List<ChapterWithDetails> _chapters = [];
  List<Teacher> _teachers = [];
  List<Subject> _subjects = [];
  List<ClassCode> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _chapterService.getChaptersWithDetails(),
        _adminService.getAllTeachers(),
        _adminService.getAllSubjects(),
        _adminService.getAllClassCodes(),
      ]);

      setState(() {
        _chapters = futures[0] as List<ChapterWithDetails>;
        _teachers = futures[1] as List<Teacher>;
        _subjects = futures[2] as List<Subject>;
        _classes = (futures[3] as List<ClassCode>).where((classCode) => classCode.code.isNotEmpty).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading chapters: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chapters: $e')),
        );
      }
    }
  }

  Future<void> _showChapterDialog({Chapter? chapter}) async {
    final titleController = TextEditingController(text: chapter?.title ?? '');
    final descriptionController = TextEditingController(text: chapter?.description ?? '');
    
    String? selectedTeacherId = chapter?.teacherId;
    String? selectedSubjectName = chapter?.subjectName;
    String? selectedClassCode = chapter?.classCode;

    if (!mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(chapter == null ? 'Tambah Bab' : 'Edit Bab'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Bab *',
                          border: OutlineInputBorder(),
                          hintText: 'Contoh: Bab 1 - Aljabar Dasar',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Bab',
                          border: OutlineInputBorder(),
                          hintText: 'Deskripsi singkat tentang bab ini',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedTeacherId,
                        decoration: const InputDecoration(
                          labelText: 'Guru Pembuat *',
                          border: OutlineInputBorder(),
                        ),
                        items: _teachers.map((teacher) {
                          return DropdownMenuItem<String>(
                            value: teacher.id,
                            child: Text(teacher.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedTeacherId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedSubjectName,
                        decoration: const InputDecoration(
                          labelText: 'Mata Pelajaran *',
                          border: OutlineInputBorder(),
                        ),
                        items: _subjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject.name,
                            child: Text(subject.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedSubjectName = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedClassCode,
                        decoration: const InputDecoration(
                          labelText: 'Kelas *',
                          border: OutlineInputBorder(),
                        ),
                        items: _classes
                            .map<DropdownMenuItem<String>>((classCode) {
                          return DropdownMenuItem<String>(
                            value: classCode.code,
                            child: Text(classCode.code),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedClassCode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final context = this.context;
                    if (titleController.text.isEmpty ||
                        selectedTeacherId == null ||
                        selectedSubjectName == null ||
                        selectedClassCode == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mohon lengkapi semua field yang wajib diisi')),
                        );
                      }
                      return;
                    }

                    try {
                      final now = DateTime.now();
                      final chapterData = Chapter(
                        id: chapter?.id ?? '',
                        title: titleController.text,
                        description: descriptionController.text,
                        teacherId: selectedTeacherId!,
                        subjectName: selectedSubjectName!,
                        classCode: selectedClassCode!,
                        schoolId: 'default_school', // TODO: Get from admin context
                        createdAt: chapter?.createdAt ?? now,
                        updatedAt: now,
                        isActive: true,
                      );

                      if (chapter == null) {
                        await _chapterService.createChapter(chapterData);
                      } else {
                        await _chapterService.updateChapter(chapter.id, chapterData);
                      }

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      await _loadData();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(chapter == null ? 'Bab berhasil ditambahkan' : 'Bab berhasil diperbarui')),
                      );
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error saving chapter: $e');
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(chapter == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus bab "${chapter.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chapterService.deleteChapter(chapter.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bab berhasil dihapus')),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting chapter: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error menghapus bab: $e')),
          );
        }
      }
    }
  }

  void _navigateToTasks(Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTaskListScreen(
          chapter: chapter,
          teachers: _teachers,
          subjects: _subjects,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menentukan Bab'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _chapters.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada bab',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap tombol + untuk menambah bab baru',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chapters.length,
                      itemBuilder: (context, index) {
                        final chapterWithDetails = _chapters[index];
                        final chapter = chapterWithDetails.chapter;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              chapter.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (chapter.description != null) ...[
                                  Text(chapter.description!),
                                  const SizedBox(height: 4),
                                ],
                                Text('Guru: ${chapterWithDetails.teacherName}'),
                                Text('Mata Pelajaran: ${chapter.subjectName}'),
                                Text('Kelas: ${chapter.classCode}'),
                                Text('Tugas: ${chapterWithDetails.activeTasks}/${chapterWithDetails.totalTasks}'),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showChapterDialog(chapter: chapter);
                                    break;
                                  case 'delete':
                                    _deleteChapter(chapter);
                                    break;
                                  case 'tasks':
                                    _navigateToTasks(chapter);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'tasks',
                                  child: ListTile(
                                    leading: Icon(Icons.assignment),
                                    title: Text('Lihat Tugas'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Edit'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete, color: Colors.red),
                                    title: Text('Hapus', style: TextStyle(color: Colors.red)),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _navigateToTasks(chapter),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChapterDialog(),
        tooltip: 'Tambah Bab',
        child: const Icon(Icons.add),
      ),
    );
  }
}