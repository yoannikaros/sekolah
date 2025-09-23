import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/chapter_models.dart';
import '../../services/chapter_service.dart';
import 'question_management_screen.dart';

class QuizManagementScreen extends StatefulWidget {
  final Chapter chapter;

  const QuizManagementScreen({
    super.key,
    required this.chapter,
  });

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  final ChapterService _chapterService = ChapterService();
  List<Quiz> _quizzes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('QuizManagementScreen: Starting to load quizzes for chapter ${widget.chapter.id}...');
        print('QuizManagementScreen: Chapter title: ${widget.chapter.title}');
      }
      
      final quizzes = await _chapterService.getQuizzesByChapterId(widget.chapter.id);
      
      if (kDebugMode) {
        print('QuizManagementScreen: Loaded ${quizzes.length} quizzes');
      }
      
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('QuizManagementScreen: Quiz loading completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('QuizManagementScreen: Error loading quizzes: $e');
        print('QuizManagementScreen: Stack trace: ${StackTrace.current}');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quizzes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Quiz> get _filteredQuizzes {
    if (_searchQuery.isEmpty) return _quizzes;
    return _quizzes.where((quiz) {
      return quiz.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manajemen Kuis', style: TextStyle(fontSize: 18)),
            Text(
              widget.chapter.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chapter Info & Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Chapter Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.book, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.chapter.subjectName} • ${widget.chapter.classCode}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.chapter.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.chapter.description!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari kuis...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuizzes.isEmpty
                    ? _buildEmptyState()
                    : _buildQuizList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuizDialog(),
        backgroundColor: Colors.green[600],
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
            Icons.quiz_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Belum ada kuis' : 'Kuis tidak ditemukan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Tambahkan kuis pertama untuk bab ini'
                : 'Coba kata kunci lain',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Tarik ke bawah untuk refresh',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            // Debug info in debug mode
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chapter ID: ${widget.chapter.id}',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                    Text(
                      'Total quizzes loaded: ${_quizzes.length}',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                    Text(
                      'Loading state: $_isLoading',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuizList() {
    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredQuizzes.length,
        itemBuilder: (context, index) {
          final quiz = _filteredQuizzes[index];
          return _buildQuizCard(quiz);
        },
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    final now = DateTime.now();
    final isActive = quiz.isActive && now.isAfter(quiz.startDateTime) && now.isBefore(quiz.endDateTime);
    final isUpcoming = quiz.isActive && now.isBefore(quiz.startDateTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToQuestionManagement(quiz),
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
                          quiz.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dibuat: ${DateFormat('dd/MM/yyyy').format(quiz.createdDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(isActive, isUpcoming),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showQuizDialog(quiz: quiz);
                          break;
                        case 'delete':
                          _confirmDeleteQuiz(quiz);
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
              
              const SizedBox(height: 12),
              
              // Schedule
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Jadwal Kuis',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mulai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(quiz.startDateTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selesai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(quiz.endDateTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
              
              const SizedBox(height: 12),
              
              // Statistics
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.help_outline,
                    label: '${quiz.totalQuestions ?? 0} Soal',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.star_outline,
                    label: '${quiz.totalPoints ?? 0} Poin',
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

  Widget _buildStatusChip(bool isActive, bool isUpcoming) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (isActive) {
      statusColor = Colors.green;
      statusText = 'Aktif';
      statusIcon = Icons.play_circle;
    } else if (isUpcoming) {
      statusColor = Colors.orange;
      statusText = 'Akan Datang';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.red;
      statusText = 'Berakhir';
      statusIcon = Icons.stop_circle;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToQuestionManagement(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionManagementScreen(
          chapter: widget.chapter,
          quiz: quiz,
        ),
      ),
    ).then((_) => _loadQuizzes()); // Refresh when returning
  }

  void _showQuizDialog({Quiz? quiz}) {
    final isEdit = quiz != null;
    final titleController = TextEditingController(text: quiz?.title ?? '');
    
    DateTime selectedStartDate = quiz?.startDateTime ?? DateTime.now();
    TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(selectedStartDate);
    DateTime selectedEndDate = quiz?.endDateTime ?? DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(selectedEndDate);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Kuis' : 'Tambah Kuis Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Kuis *',
                    hintText: 'Contoh: Kuis Harian Aljabar',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                
                // Start Date & Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedStartDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                selectedStartTime.hour,
                                selectedStartTime.minute,
                              );
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Mulai',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy').format(selectedStartDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedStartTime,
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedStartTime = time;
                              selectedStartDate = DateTime(
                                selectedStartDate.year,
                                selectedStartDate.month,
                                selectedStartDate.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Jam Mulai',
                            border: OutlineInputBorder(),
                          ),
                          child: Text('${selectedStartTime.hour.toString().padLeft(2, '0')}:${selectedStartTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // End Date & Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedEndDate,
                            firstDate: selectedStartDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedEndDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                selectedEndTime.hour,
                                selectedEndTime.minute,
                              );
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Selesai',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy').format(selectedEndDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedEndTime,
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedEndTime = time;
                              selectedEndDate = DateTime(
                                selectedEndDate.year,
                                selectedEndDate.month,
                                selectedEndDate.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Jam Selesai',
                            border: OutlineInputBorder(),
                          ),
                          child: Text('${selectedEndTime.hour.toString().padLeft(2, '0')}:${selectedEndTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ),
                  ],
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
              onPressed: () => _saveQuiz(
                context,
                isEdit,
                quiz?.id,
                titleController.text,
                selectedStartDate,
                selectedEndDate,
              ),
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuiz(
    BuildContext context,
    bool isEdit,
    String? quizId,
    String title,
    DateTime startDateTime,
    DateTime endDateTime,
  ) async {
    if (title.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon isi judul kuis')),
        );
      }
      return;
    }

    if (startDateTime.isAfter(endDateTime)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waktu mulai tidak boleh setelah waktu selesai')),
        );
      }
      return;
    }

    Navigator.pop(context);

    try {
      final quiz = Quiz(
        id: quizId ?? '',
        chapterId: widget.chapter.id,
        title: title.trim(),
        createdDate: isEdit ? _quizzes.firstWhere((q) => q.id == quizId).createdDate : DateTime.now(),
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        isActive: true,
      );

      bool success;
      if (isEdit) {
        success = await _chapterService.updateQuiz(quizId!, quiz);
      } else {
        final id = await _chapterService.createQuiz(quiz);
        success = id != null;
      }

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kuis berhasil ${isEdit ? 'diupdate' : 'ditambahkan'}')),
          );
        }
        _loadQuizzes();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal ${isEdit ? 'mengupdate' : 'menambahkan'} kuis')),
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

  void _confirmDeleteQuiz(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus kuis "${quiz.title}"?\n\nSemua soal dalam kuis ini akan ikut terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteQuiz(context, quiz),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuiz(BuildContext context, Quiz quiz) async {
    Navigator.pop(context);

    try {
      final success = await _chapterService.deleteQuiz(quiz.id);
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kuis berhasil dihapus')),
          );
        }
        _loadQuizzes();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus kuis')),
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