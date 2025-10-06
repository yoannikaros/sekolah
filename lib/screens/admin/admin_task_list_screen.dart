import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/task_models.dart';
import '../../models/chapter_models.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/task_service.dart';
import '../../services/admin_service.dart';
import 'admin_task_submission_screen.dart';

class AdminTaskListScreen extends StatefulWidget {
  final Chapter chapter;
  final List<Teacher> teachers;
  final List<Subject> subjects;

  const AdminTaskListScreen({
    super.key, 
    required this.chapter,
    required this.teachers,
    required this.subjects,
  });

  @override
  State<AdminTaskListScreen> createState() => _AdminTaskListScreenState();
}

class _AdminTaskListScreenState extends State<AdminTaskListScreen> {
  final TaskService _taskService = TaskService();
  final AdminService _adminService = AdminService();
  List<TaskWithDetails> _tasks = [];
  List<Teacher> _teachers = [];
  List<Subject> _subjects = [];
  List<ClassCode?> _classes = [];
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
        _taskService.getTasksWithDetailsByChapter(widget.chapter.id),
        _adminService.getAllClassCodes(),
      ]);

      setState(() {
        _tasks = futures[0] as List<TaskWithDetails>;
        _teachers = widget.teachers; // Use teachers from previous screen
        _subjects = widget.subjects; // Use subjects from previous screen
        _classes = futures[1] as List<ClassCode?>;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tasks: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  Future<void> _showTaskDialog({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(text: task?.description ?? '');
    final taskLinkController = TextEditingController(text: task?.taskLink ?? '');
    
    // Validate that the selected teacher ID exists in the teachers list
    String? selectedTeacherId = task?.teacherId ?? widget.chapter.teacherId;
    if (!_teachers.any((teacher) => teacher.id == selectedTeacherId)) {
      selectedTeacherId = null; // Reset if not found in the list
    }
    
    // Validate that the selected subject ID exists in the subjects list
    String? selectedSubjectId = task?.subjectId;
    if (selectedSubjectId != null && !_subjects.any((subject) => subject.id == selectedSubjectId)) {
      selectedSubjectId = null; // Reset if not found in the list
    }
    
    List<String> selectedClassIds = [];
    
    DateTime openDate = task?.openDate ?? DateTime.now();
    DateTime dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 7));

    // Load existing class assignments if editing
    if (task != null) {
      final taskClasses = await _taskService.getTaskClassesByTask(task.id);
      selectedClassIds = taskClasses.map((tc) => tc.classId).toList();
    }

    if (!mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(task == null ? 'Tambah Tugas' : 'Edit Tugas'),
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
                          labelText: 'Judul Tugas *',
                          border: OutlineInputBorder(),
                          hintText: 'Contoh: Latihan Soal Bab 1',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Tugas *',
                          border: OutlineInputBorder(),
                          hintText: 'Deskripsi detail tugas',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: taskLinkController,
                        decoration: const InputDecoration(
                          labelText: 'Link Tugas *',
                          border: OutlineInputBorder(),
                          hintText: 'https://docs.google.com/...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedTeacherId,
                        decoration: const InputDecoration(
                          labelText: 'Guru *',
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
                        value: selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Mata Pelajaran *',
                          border: OutlineInputBorder(),
                        ),
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
                      ),
                      const SizedBox(height: 16),
                      const Text('Kelas yang Ditugaskan:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _classes.where((classCode) => classCode != null).map<Widget>((classCode) {
                          final nonNullClassCode = classCode!;
                          final isSelected = selectedClassIds.contains(nonNullClassCode.id);
                          return FilterChip(
                            label: Text(nonNullClassCode.code),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedClassIds.add(nonNullClassCode.id);
                                } else {
                                  selectedClassIds.remove(nonNullClassCode.id);
                                }
                              });
                            },
                          );
                        }).toList()
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tanggal Buka *', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final context = this.context;
                                    if (!context.mounted) return;
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: openDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      if (!context.mounted) return;
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(openDate),
                                      );
                                      if (time != null) {
                                        setDialogState(() {
                                          openDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${openDate.day}/${openDate.month}/${openDate.year} ${openDate.hour.toString().padLeft(2, '0')}:${openDate.minute.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tanggal Tutup *', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final context = this.context;
                                    if (!context.mounted) return;
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: dueDate,
                                      firstDate: openDate,
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      if (!context.mounted) return;
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(dueDate),
                                      );
                                      if (time != null) {
                                        setDialogState(() {
                                          dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${dueDate.day}/${dueDate.month}/${dueDate.year} ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                        descriptionController.text.isEmpty ||
                        taskLinkController.text.isEmpty ||
                        selectedTeacherId == null ||
                        selectedSubjectId == null ||
                        selectedClassIds.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mohon lengkapi semua field yang wajib diisi')),
                        );
                      }
                      return;
                    }

                    try {
                      final now = DateTime.now();
                      final taskData = Task(
                        id: task?.id ?? '',
                        teacherId: selectedTeacherId!,
                        subjectId: selectedSubjectId!,
                        chapterId: widget.chapter.id,
                        title: titleController.text,
                        description: descriptionController.text,
                        createdAt: task?.createdAt ?? now,
                        openDate: openDate,
                        dueDate: dueDate,
                        taskLink: taskLinkController.text,
                        isActive: true,
                        updatedAt: now,
                      );

                      if (task == null) {
                        final taskId = await _taskService.createTask(taskData);
                        if (taskId != null) {
                          await _taskService.assignTaskToClasses(taskId, selectedClassIds);
                        }
                      } else {
                        await _taskService.updateTask(task.id, taskData);
                        await _taskService.assignTaskToClasses(task.id, selectedClassIds);
                      }

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      await _loadData();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(task == null ? 'Tugas berhasil ditambahkan' : 'Tugas berhasil diperbarui')),
                      );
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error saving task: $e');
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(task == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus tugas "${task.title}"?'),
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
        await _taskService.deleteTask(task.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil dihapus')),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting task: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error menghapus tugas: $e')),
          );
        }
      }
    }
  }

  void _navigateToSubmissions(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTaskSubmissionScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tugas - ${widget.chapter.title}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _tasks.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada tugas',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap tombol + untuk menambah tugas baru',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final taskWithDetails = _tasks[index];
                        final task = taskWithDetails.task;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.assignment, color: Colors.white),
                            ),
                            title: Text(
                              task.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(task.description),
                                const SizedBox(height: 4),
                                Text('Guru: ${taskWithDetails.teacherName}'),
                                Text('Mata Pelajaran: ${taskWithDetails.subjectName}'),
                                Text('Kelas: ${taskWithDetails.classNames.join(', ')}'),
                                Text('Pengumpulan: ${taskWithDetails.submissionCount}/${taskWithDetails.totalStudents}'),
                                Text('Buka: ${task.openDate.day}/${task.openDate.month}/${task.openDate.year}'),
                                Text('Tutup: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}'),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showTaskDialog(task: task);
                                    break;
                                  case 'delete':
                                    _deleteTask(task);
                                    break;
                                  case 'submissions':
                                    _navigateToSubmissions(task);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'submissions',
                                  child: ListTile(
                                    leading: Icon(Icons.upload_file),
                                    title: Text('Lihat Pengumpulan'),
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
                            onTap: () => _navigateToSubmissions(task),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        tooltip: 'Tambah Tugas',
        child: const Icon(Icons.add),
      ),
    );
  }
}