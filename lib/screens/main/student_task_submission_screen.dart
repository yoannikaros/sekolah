import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_models.dart';
import '../../models/task_models.dart';
import '../../services/task_service.dart';

class StudentTaskSubmissionScreen extends StatefulWidget {
  final Subject subject;
  final Student student;
  final String schoolId;
  final String classCode;

  const StudentTaskSubmissionScreen({
    super.key,
    required this.subject,
    required this.student,
    required this.schoolId,
    required this.classCode,
  });

  @override
  State<StudentTaskSubmissionScreen> createState() => _StudentTaskSubmissionScreenState();
}

class _StudentTaskSubmissionScreenState extends State<StudentTaskSubmissionScreen> with TickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final TextEditingController _submissionLinkController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  List<TaskWithDetails> _tasks = [];
  Map<String, TaskSubmission?> _submissions = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadTasks();
  }

  @override
  void dispose() {
    _submissionLinkController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (kDebugMode) {
      print('=== StudentTaskSubmissionScreen: Starting _loadTasks ===');
      print('Subject: ${widget.subject.name} (${widget.subject.id})');
      print('Student: ${widget.student.name} (${widget.student.id})');
      print('School ID: ${widget.schoolId}');
      print('Class Code: ${widget.classCode}');
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First, find the class code document ID
      String? classCodeDocId;
      try {
        final classCodeQuery = await FirebaseFirestore.instance
            .collection('class_codes')
            .where('code', isEqualTo: widget.classCode)
            .where('schoolId', isEqualTo: widget.schoolId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
        
        if (classCodeQuery.docs.isNotEmpty) {
          classCodeDocId = classCodeQuery.docs.first.id;
          if (kDebugMode) {
            print('StudentTaskSubmissionScreen: Found class code document ID: $classCodeDocId');
          }
        } else {
          if (kDebugMode) {
            print('StudentTaskSubmissionScreen: Class code ${widget.classCode} not found');
          }
          setState(() {
            _isLoading = false;
            _errorMessage = 'Class code not found';
          });
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('StudentTaskSubmissionScreen: Error finding class code: $e');
        }
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error finding class code: $e';
        });
        return;
      }

      // Get tasks for this subject and class code document ID
      final tasks = await _taskService.getTasksBySubjectAndClassCode(
        widget.subject.id,
        classCodeDocId,
      );

      if (kDebugMode) {
        print('StudentTaskSubmissionScreen: Found ${tasks.length} tasks');
        for (var task in tasks) {
          print('  - Task: ${task.task.title} (${task.task.id})');
          print('    Open: ${task.task.openDate}');
          print('    Due: ${task.task.dueDate}');
          print('    Status: ${task.task.isOpen ? "Open" : "Closed"}');
        }
      }

      // Get existing submissions for each task
      Map<String, TaskSubmission?> submissions = {};
      for (var taskWithDetails in tasks) {
        try {
          final submission = await _taskService.getSubmissionByTaskAndStudent(
            taskWithDetails.task.id,
            widget.student.id,
          );
          submissions[taskWithDetails.task.id] = submission;
          
          if (kDebugMode) {
            if (submission != null) {
              print('  - Found submission for task ${taskWithDetails.task.id}: ${submission.submissionLink}');
            } else {
              print('  - No submission found for task ${taskWithDetails.task.id}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('  - Error getting submission for task ${taskWithDetails.task.id}: $e');
          }
          submissions[taskWithDetails.task.id] = null;
        }
      }

      setState(() {
        _tasks = tasks;
        _submissions = submissions;
        _isLoading = false;
      });

      _animationController.forward();

      if (kDebugMode) {
        print('StudentTaskSubmissionScreen: Data loaded successfully');
        print('  - Tasks count: ${_tasks.length}');
        print('  - Submissions count: ${_submissions.length}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('StudentTaskSubmissionScreen: Error loading tasks: $e');
      }
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memuat tugas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitTask(TaskWithDetails taskWithDetails) async {
    final submissionLink = _submissionLinkController.text.trim();
    final notes = _notesController.text.trim();

    if (submissionLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Link pengumpulan tidak boleh kosong'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (kDebugMode) {
      print('=== StudentTaskSubmissionScreen: Submitting task ===');
      print('Task ID: ${taskWithDetails.task.id}');
      print('Student ID: ${widget.student.id}');
      print('Submission Link: $submissionLink');
      print('Notes: $notes');
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final existingSubmission = _submissions[taskWithDetails.task.id];
      
      if (existingSubmission != null) {
        // Update existing submission
        if (kDebugMode) {
          print('StudentTaskSubmissionScreen: Updating existing submission ${existingSubmission.id}');
        }
        
        final updatedSubmission = existingSubmission.copyWith(
          submissionLink: submissionLink,
          submissionDate: DateTime.now(),
          notes: notes.isEmpty ? null : notes,
          isLate: DateTime.now().isAfter(taskWithDetails.task.dueDate),
        );
        
        await _taskService.updateSubmission(updatedSubmission);
        
        if (kDebugMode) {
          print('StudentTaskSubmissionScreen: Submission updated successfully');
        }
      } else {
        // Create new submission
        if (kDebugMode) {
          print('StudentTaskSubmissionScreen: Creating new submission');
        }
        
        final newSubmission = TaskSubmission(
          id: '', // Will be set by Firestore
          taskId: taskWithDetails.task.id,
          studentId: widget.student.id,
          submissionLink: submissionLink,
          submissionDate: DateTime.now(),
          notes: notes.isEmpty ? null : notes,
          isLate: DateTime.now().isAfter(taskWithDetails.task.dueDate),
        );
        
        await _taskService.createSubmission(newSubmission);
        
        if (kDebugMode) {
          print('StudentTaskSubmissionScreen: New submission created successfully');
        }
      }

      // Refresh submissions
      await _loadTasks();
      
      // Clear form
      _submissionLinkController.clear();
      _notesController.clear();
      
      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Tugas berhasil dikumpulkan'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

    } catch (e) {
      if (kDebugMode) {
        print('StudentTaskSubmissionScreen: Error submitting task: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal mengumpulkan tugas: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSubmissionDialog(TaskWithDetails taskWithDetails) {
    final existingSubmission = _submissions[taskWithDetails.task.id];
    
    if (kDebugMode) {
      print('StudentTaskSubmissionScreen: Showing submission dialog for task ${taskWithDetails.task.id}');
      print('Existing submission: ${existingSubmission?.submissionLink ?? "None"}');
    }

    // Pre-fill form if editing existing submission
    if (existingSubmission != null) {
      _submissionLinkController.text = existingSubmission.submissionLink;
      _notesController.text = existingSubmission.notes ?? '';
    } else {
      _submissionLinkController.clear();
      _notesController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        existingSubmission != null ? Icons.edit : Icons.upload,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            existingSubmission != null ? 'Edit Pengumpulan' : 'Kumpulkan Tugas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            taskWithDetails.task.title,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Link input
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _submissionLinkController,
                        decoration: InputDecoration(
                          labelText: 'Link Pengumpulan *',
                          hintText: 'https://drive.google.com/...',
                          prefixIcon: const Icon(Icons.link),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          labelStyle: TextStyle(color: Colors.blue[600]),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notes input
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Catatan (Opsional)',
                          hintText: 'Tambahkan catatan untuk guru...',
                          prefixIcon: const Icon(Icons.note),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          labelStyle: TextStyle(color: Colors.blue[600]),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    
                    // Existing submission info
                    if (existingSubmission != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[50]!, Colors.green[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Status Pengumpulan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Dikumpulkan: ${existingSubmission.submissionDate.toString().split('.')[0]}'),
                            if (existingSubmission.score != null) ...[
                              const SizedBox(height: 4),
                              Text('Nilai: ${existingSubmission.score}'),
                            ],
                            if (existingSubmission.feedback?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text('Feedback: ${existingSubmission.feedback}'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitTask(taskWithDetails),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(existingSubmission != null ? 'Update' : 'Kumpulkan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTaskLink(String? taskLink) async {
    if (taskLink == null || taskLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Link tugas tidak tersedia'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (kDebugMode) {
      print('StudentTaskSubmissionScreen: Opening task link: $taskLink');
    }

    try {
      final uri = Uri.parse(taskLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $taskLink';
      }
    } catch (e) {
      if (kDebugMode) {
        print('StudentTaskSubmissionScreen: Error opening link: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal membuka link: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }



  String _getTaskStatusText(Task task) {
    if (task.isOverdue) return 'Terlambat';
    if (task.isOpen) return 'Terbuka';
    if (task.isUpcoming) return 'Akan Datang';
    return 'Ditutup';
  }

  IconData _getTaskStatusIcon(Task task) {
    if (task.isOverdue) return Icons.schedule;
    if (task.isOpen) return Icons.check_circle_outline;
    if (task.isUpcoming) return Icons.upcoming;
    return Icons.lock;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.subject.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat tugas...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Oops! Terjadi Kesalahan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadTasks,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Modern Header with gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.assignment,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.subject.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Kelas: ${widget.classCode} • Kode: ${widget.subject.code}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.9),
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
                    
                    // Tasks list
                    Expanded(
                      child: _tasks.isEmpty
                          ? Center(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  margin: const EdgeInsets.all(20),
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withValues(alpha: 0.1),
                                        spreadRadius: 5,
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: Icon(
                                          Icons.assignment_outlined,
                                          size: 64,
                                          color: Colors.blue[400],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Belum ada tugas',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tugas untuk mata pelajaran ini\nbelum tersedia',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTasks,
                              color: Colors.blue[600],
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _tasks.length,
                                  itemBuilder: (context, index) {
                                    final taskWithDetails = _tasks[index];
                                    final task = taskWithDetails.task;
                                    final submission = _submissions[task.id];
                                    final hasSubmission = submission != null;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withValues(alpha: 0.1),
                                            spreadRadius: 0,
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Column(
                                          children: [
                                            // Task header with gradient
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: hasSubmission 
                                                      ? [Colors.green[400]!, Colors.green[300]!]
                                                      : [Colors.blue[400]!, Colors.blue[300]!],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(
                                                      hasSubmission ? Icons.check_circle : Icons.assignment,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      task.title,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          _getTaskStatusIcon(task),
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          _getTaskStatusText(task),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Task content
                                            Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Task description
                                                  if (task.description.isNotEmpty) ...[
                                                    Text(
                                                      task.description,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[700],
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                  ],
                                                  
                                                  // Task dates in modern cards
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green[50],
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(color: Colors.green[200]!),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons.play_circle_outline,
                                                                    size: 16,
                                                                    color: Colors.green[600],
                                                                  ),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    'Dibuka',
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: Colors.green[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                task.openDate.toString().split('.')[0],
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red[50],
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(color: Colors.red[200]!),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons.stop_circle_outlined,
                                                                    size: 16,
                                                                    color: Colors.red[600],
                                                                  ),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    'Ditutup',
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: Colors.red[600],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                task.dueDate.toString().split('.')[0],
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  
                                                  // Submission status
                                                  if (hasSubmission) ...[
                                                    const SizedBox(height: 16),
                                                    Container(
                                                      padding: const EdgeInsets.all(16),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Colors.green[50]!, Colors.green[100]!],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(color: Colors.green[200]!),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.green[600],
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: const Icon(
                                                              Icons.check,
                                                              color: Colors.white,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  'Sudah dikumpulkan',
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 14,
                                                                    color: Colors.green[700],
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  submission.submissionDate.toString().split('.')[0],
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.green[600],
                                                                  ),
                                                                ),
                                                                if (submission.score != null) ...[
                                                                  const SizedBox(height: 4),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal: 8,
                                                                      vertical: 2,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.green[600],
                                                                      borderRadius: BorderRadius.circular(10),
                                                                    ),
                                                                    child: Text(
                                                                      'Nilai: ${submission.score}',
                                                                      style: const TextStyle(
                                                                        fontSize: 10,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Colors.white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  
                                                  // Action buttons
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    children: [
                                                      if (task.taskLink.isNotEmpty)
                                                        Expanded(
                                                          child: OutlinedButton.icon(
                                                            onPressed: () => _openTaskLink(task.taskLink),
                                                            icon: const Icon(Icons.link, size: 18),
                                                            label: const Text('Buka Tugas'),
                                                            style: OutlinedButton.styleFrom(
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              side: BorderSide(color: Colors.blue[600]!),
                                                              foregroundColor: Colors.blue[600],
                                                            ),
                                                          ),
                                                        ),
                                                      if (task.taskLink.isNotEmpty)
                                                        const SizedBox(width: 12),
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          onPressed: task.isOpen
                                                              ? () => _showSubmissionDialog(taskWithDetails)
                                                              : null,
                                                          icon: Icon(
                                                            hasSubmission ? Icons.edit : Icons.upload,
                                                            size: 18,
                                                          ),
                                                          label: Text(hasSubmission ? 'Edit' : 'Kumpulkan'),
                                                          style: ElevatedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                            backgroundColor: hasSubmission 
                                                                ? Colors.orange[600] 
                                                                : Colors.blue[600],
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}