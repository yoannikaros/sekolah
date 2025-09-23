import 'package:flutter/material.dart';
import '../../models/quiz_models.dart';
import '../../services/admin_service.dart';

class AdminQuizzesScreen extends StatefulWidget {
  const AdminQuizzesScreen({super.key});

  @override
  State<AdminQuizzesScreen> createState() => _AdminQuizzesScreenState();
}

class _AdminQuizzesScreenState extends State<AdminQuizzesScreen> {
  final AdminService _adminService = AdminService();
  List<Quiz> _quizzes = [];
  List<ClassCode> _classCodes = [];
  List<Question> _questions = [];
  bool _isLoading = true;
  String? _selectedClassCode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final quizzes = await _adminService.getAllQuizzes();
    final classCodes = await _adminService.getAllClassCodes();
    final questions = await _adminService.getAllQuestions();
    setState(() {
      _quizzes = quizzes;
      _classCodes = classCodes;
      _questions = questions;
      _isLoading = false;
    });
  }

  List<Quiz> get _filteredQuizzes {
    if (_selectedClassCode == null) return _quizzes;
    return _quizzes.where((q) => q.classCodeId == _selectedClassCode).toList();
  }

  String _getCategoryName(QuestionCategory category) {
    switch (category) {
      case QuestionCategory.reading:
        return 'Membaca';
      case QuestionCategory.writing:
        return 'Menulis';
      case QuestionCategory.math:
        return 'Matematika';
      case QuestionCategory.science:
        return 'Sains';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Quiz'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedClassCode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Semua Kelas'),
              ),
              ..._classCodes.map((classCode) => PopupMenuItem(
                value: classCode.id,
                child: Text(classCode.name),
              )),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuizDialog(),
        backgroundColor: Colors.purple[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedClassCode != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.purple[50],
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.purple[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Filter: ${_classCodes.firstWhere((c) => c.id == _selectedClassCode).name}',
                          style: TextStyle(
                            color: Colors.purple[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _selectedClassCode = null),
                          child: const Text('Hapus Filter'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _filteredQuizzes.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada quiz',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap tombol + untuk menambah quiz baru',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredQuizzes.length,
                            itemBuilder: (context, index) {
                              final quiz = _filteredQuizzes[index];
                              final classCode = _classCodes.firstWhere(
                                (c) => c.id == quiz.classCodeId,
                                orElse: () => ClassCode(
                                  id: '',
                                  code: '',
                                  name: 'Unknown',
                                  description: '',
                                  teacherId: '',
                                  schoolId: '', // Add required schoolId parameter
                                  createdAt: DateTime.now(),
                                ),
                              );
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.purple[100],
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Icon(
                                      Icons.assignment,
                                      color: Colors.purple[600],
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    quiz.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        quiz.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              classCode.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.purple[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getCategoryName(quiz.category),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.purple[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${quiz.questionIds.length} soal',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${quiz.timeLimit} menit',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(Icons.star, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${quiz.totalPoints} poin',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          _showQuizDialog(quiz: quiz);
                                          break;
                                        case 'delete':
                                          _confirmDelete(quiz);
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
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showQuizDialog({Quiz? quiz}) {
    final isEdit = quiz != null;
    final titleController = TextEditingController(text: quiz?.title ?? '');
    final descriptionController = TextEditingController(text: quiz?.description ?? '');
    final timeLimitController = TextEditingController(text: quiz?.timeLimit.toString() ?? '30');
    
    String selectedClassCodeId = quiz?.classCodeId ?? (_classCodes.isNotEmpty ? _classCodes.first.id : '');
    QuestionCategory selectedCategory = quiz?.category ?? QuestionCategory.reading;
    List<String> selectedQuestionIds = List.from(quiz?.questionIds ?? []);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Quiz' : 'Tambah Quiz'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Quiz',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedClassCodeId.isEmpty ? null : selectedClassCodeId,
                          decoration: const InputDecoration(
                            labelText: 'Kelas',
                            border: OutlineInputBorder(),
                          ),
                          items: _classCodes.map((classCode) => DropdownMenuItem(
                            value: classCode.id,
                            child: Text(classCode.name),
                          )).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedClassCodeId = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<QuestionCategory>(
                          value: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            border: OutlineInputBorder(),
                          ),
                          items: QuestionCategory.values.map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryName(category)),
                          )).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategory = value!;
                              // Reset selected questions when category changes
                              selectedQuestionIds.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: timeLimitController,
                    decoration: const InputDecoration(
                      labelText: 'Batas Waktu (menit)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Soal:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _questions.where((q) => q.category == selectedCategory).length,
                      itemBuilder: (context, index) {
                        final categoryQuestions = _questions.where((q) => q.category == selectedCategory).toList();
                        final question = categoryQuestions[index];
                        final isSelected = selectedQuestionIds.contains(question.id);
                        
                        return CheckboxListTile(
                          title: Text(
                            question.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('${question.points} poin'),
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedQuestionIds.add(question.id);
                              } else {
                                selectedQuestionIds.remove(question.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dipilih: ${selectedQuestionIds.length} soal',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => _saveQuiz(
                isEdit,
                quiz?.id,
                titleController.text,
                descriptionController.text,
                selectedClassCodeId,
                selectedCategory,
                selectedQuestionIds,
                int.tryParse(timeLimitController.text) ?? 30,
              ),
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuiz(
    bool isEdit,
    String? id,
    String title,
    String description,
    String classCodeId,
    QuestionCategory category,
    List<String> questionIds,
    int timeLimit,
  ) async {
    if (title.isEmpty || description.isEmpty || questionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi dan minimal 1 soal dipilih')),
      );
      return;
    }

    Navigator.pop(context);

    // Calculate total points
    final selectedQuestions = _questions.where((q) => questionIds.contains(q.id)).toList();
    final totalPoints = selectedQuestions.fold<int>(0, (sum, q) => sum + q.points);

    final newQuiz = Quiz(
      id: id ?? '',
      title: title,
      description: description,
      questionIds: questionIds,
      category: category,
      totalPoints: totalPoints,
      timeLimit: timeLimit,
      classCodeId: classCodeId,
      subjectId: '', // Add required subjectId parameter
      createdAt: DateTime.now(),
    );

    bool success;
    if (isEdit && id != null) {
      success = await _adminService.updateQuiz(id, newQuiz);
    } else {
      final result = await _adminService.createQuiz(newQuiz);
      success = result != null;
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Quiz berhasil diupdate' : 'Quiz berhasil ditambahkan'),
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan quiz')),
        );
      }
    }
  }

  void _confirmDelete(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus quiz "${quiz.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteQuiz(quiz.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuiz(String id) async {
    Navigator.pop(context);
    
    final success = await _adminService.deleteQuiz(id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz berhasil dihapus')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus quiz')),
        );
      }
    }
  }
}