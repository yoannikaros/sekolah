import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/task_models.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/task_service.dart';
import '../../services/admin_service.dart';

class AdminTaskScreen extends StatefulWidget {
  const AdminTaskScreen({super.key});

  @override
  State<AdminTaskScreen> createState() => _AdminTaskScreenState();
}

class _AdminTaskScreenState extends State<AdminTaskScreen> {
  final TaskService _taskService = TaskService();
  final AdminService _adminService = AdminService();
  List<TaskWithDetails> _tasks = [];
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
        _taskService.getTasksWithDetails(),
        _adminService.getAllTeachers(),
        _adminService.getAllSubjects(),
        _adminService.getAllClassCodes(),
      ]);

      setState(() {
        _tasks = futures[0] as List<TaskWithDetails>;
        _teachers = futures[1] as List<Teacher>;
        _subjects = futures[2] as List<Subject>;
        _classes = futures[3] as List<ClassCode>;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _showTaskDialog({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(text: task?.description ?? '');
    final taskLinkController = TextEditingController(text: task?.taskLink ?? '');
    
    String? selectedTeacherId = task?.teacherId;
    String? selectedSubjectId = task?.subjectId;
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
                          hintText: 'Contoh: BAB 1 - Pengenalan Matematika',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Tugas *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Teacher Selection
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
                      
                      // Subject Selection
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
                      
                      // Class Selection
                      const Text(
                        'Kelas yang Ditugaskan *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: _classes.length,
                          itemBuilder: (context, index) {
                            final classCode = _classes[index];
                            final isSelected = selectedClassIds.contains(classCode.id);
                            
                            return CheckboxListTile(
                              title: Text(classCode.name),
                              subtitle: Text('Kode: ${classCode.code}'),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedClassIds.add(classCode.id);
                                  } else {
                                    selectedClassIds.remove(classCode.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Date Selection
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tanggal Dibuka *'),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final currentContext = context;
                                    final date = await showDatePicker(
                                      context: currentContext,
                                      initialDate: openDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null && currentContext.mounted) {
                                      final time = await showTimePicker(
                                        context: currentContext,
                                        initialTime: TimeOfDay.fromDateTime(openDate),
                                      );
                                      if (time != null && currentContext.mounted) {
                                        setDialogState(() {
                                          openDate = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
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
                                const Text('Tanggal Selesai *'),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final currentContext = context;
                                    final date = await showDatePicker(
                                      context: currentContext,
                                      initialDate: dueDate,
                                      firstDate: openDate,
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null && currentContext.mounted) {
                                      final time = await showTimePicker(
                                        context: currentContext,
                                        initialTime: TimeOfDay.fromDateTime(dueDate),
                                      );
                                      if (time != null && currentContext.mounted) {
                                        setDialogState(() {
                                          dueDate = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
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
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: taskLinkController,
                        decoration: const InputDecoration(
                          labelText: 'Link Soal *',
                          border: OutlineInputBorder(),
                          hintText: 'https://docs.google.com/document/...',
                        ),
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
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        selectedTeacherId == null ||
                        selectedSubjectId == null ||
                        selectedClassIds.isEmpty ||
                        taskLinkController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mohon lengkapi semua field yang wajib diisi'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      if (task == null) {
                        // Create new task
                        final newTask = Task(
                          id: '',
                          teacherId: selectedTeacherId!,
                          subjectId: selectedSubjectId!,
                          title: titleController.text,
                          description: descriptionController.text,
                          createdAt: DateTime.now(),
                          openDate: openDate,
                          dueDate: dueDate,
                          taskLink: taskLinkController.text,
                        );

                        final taskId = await _taskService.createTask(newTask);
                        if (taskId != null) {
                          // Assign task to classes
                          await _taskService.assignTaskToClasses(taskId, selectedClassIds);
                          
                          if (mounted) {
                            final currentContext = context;
                            if (currentContext.mounted) {
                              Navigator.of(currentContext).pop();
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Tugas berhasil dibuat'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            }
                          }
                        }
                      } else {
                        // Update existing task
                        final updatedTask = task.copyWith(
                          teacherId: selectedTeacherId!,
                          subjectId: selectedSubjectId!,
                          title: titleController.text,
                          description: descriptionController.text,
                          openDate: openDate,
                          dueDate: dueDate,
                          taskLink: taskLinkController.text,
                          updatedAt: DateTime.now(),
                        );

                        final success = await _taskService.updateTask(task.id, updatedTask);
                        if (success) {
                          // Update class assignments
                          await _taskService.assignTaskToClasses(task.id, selectedClassIds);
                          
                          if (mounted) {
                            final currentContext = context;
                            if (currentContext.mounted) {
                              Navigator.of(currentContext).pop();
                              ScaffoldMessenger.of(currentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Tugas berhasil diperbarui'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadData();
                            }
                          }
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        final currentContext = context;
                        if (currentContext.mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(task == null ? 'Tambah' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTask(TaskWithDetails taskWithDetails) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus tugas "${taskWithDetails.task.title}"?'),
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
        final success = await _taskService.deleteTask(taskWithDetails.task.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error menghapus tugas: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildTaskCard(TaskWithDetails taskWithDetails) {
    final task = taskWithDetails.task;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (task.isOverdue) {
      statusColor = Colors.red;
      statusText = 'Terlambat';
      statusIcon = Icons.schedule;
    } else if (task.isOpen) {
      statusColor = Colors.green;
      statusText = 'Aktif';
      statusIcon = Icons.play_circle;
    } else if (task.isUpcoming) {
      statusColor = Colors.orange;
      statusText = 'Akan Datang';
      statusIcon = Icons.upcoming;
    } else {
      statusColor = Colors.grey;
      statusText = 'Selesai';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        taskWithDetails.subjectName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  taskWithDetails.teacherName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.class_, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    taskWithDetails.classNames.join(', '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Dibuka: ${task.openDate.day}/${task.openDate.month}/${task.openDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.event, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Deadline: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: taskWithDetails.submissionPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      taskWithDetails.submissionPercentage > 80 ? Colors.green :
                      taskWithDetails.submissionPercentage > 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${taskWithDetails.submissionCount}/${taskWithDetails.totalStudents} (${taskWithDetails.submissionPercentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showTaskDialog(task: task),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteTask(taskWithDetails),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manajemen Tugas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total Tugas: ${_tasks.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showTaskDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Tugas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tasks.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada tugas',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            return _buildTaskCard(_tasks[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}