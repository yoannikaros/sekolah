import 'package:flutter/material.dart';
import '../../models/quiz_models.dart';
import '../../services/admin_service.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  final AdminService _adminService = AdminService();
  List<Question> _questions = [];
  bool _isLoading = true;
  QuestionCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final questions = await _adminService.getAllQuestions();
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  List<Question> get _filteredQuestions {
    if (_selectedCategory == null) return _questions;
    return _questions.where((q) => q.category == _selectedCategory).toList();
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
        title: const Text('Kelola Soal'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<QuestionCategory?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Semua Kategori'),
              ),
              ...QuestionCategory.values.map((category) => PopupMenuItem(
                value: category,
                child: Text(_getCategoryName(category)),
              )),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuestionDialog(),
        backgroundColor: Colors.orange[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedCategory != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange[50],
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.orange[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Filter: ${_getCategoryName(_selectedCategory!)}',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _selectedCategory = null),
                          child: const Text('Hapus Filter'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _filteredQuestions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.quiz, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada soal',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap tombol + untuk menambah soal baru',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadQuestions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredQuestions.length,
                            itemBuilder: (context, index) {
                              final question = _filteredQuestions[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ExpansionTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.quiz,
                                      color: Colors.orange[600],
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    question.question,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getCategoryName(question.category),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${question.points} poin',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          _showQuestionDialog(question: question);
                                          break;
                                        case 'delete':
                                          _confirmDelete(question);
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
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Pilihan Jawaban:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          ...question.options.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final option = entry.value;
                                            final isCorrect = index == question.correctAnswerIndex;
                                            
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 4),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isCorrect 
                                                    ? Colors.green[50] 
                                                    : Colors.grey[50],
                                                border: Border.all(
                                                  color: isCorrect 
                                                      ? Colors.green 
                                                      : Colors.grey[300]!,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: isCorrect 
                                                          ? Colors.green 
                                                          : Colors.grey[400],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        String.fromCharCode(65 + index),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text(option)),
                                                  if (isCorrect)
                                                    const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 20,
                                                    ),
                                                ],
                                              ),
                                            );
                                          }),
                                          if (question.explanation != null) ...[
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Penjelasan:',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(question.explanation!),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
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

  void _showQuestionDialog({Question? question}) {
    final isEdit = question != null;
    final questionController = TextEditingController(text: question?.question ?? '');
    final explanationController = TextEditingController(text: question?.explanation ?? '');
    final pointsController = TextEditingController(text: question?.points.toString() ?? '10');
    
    List<TextEditingController> optionControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: question != null && index < question.options.length 
            ? question.options[index] 
            : '',
      ),
    );
    
    QuestionCategory selectedCategory = question?.category ?? QuestionCategory.reading;
    QuestionType selectedType = question?.type ?? QuestionType.multipleChoice;
    int correctAnswerIndex = question?.correctAnswerIndex ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Soal' : 'Tambah Soal'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'Pertanyaan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
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
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: pointsController,
                          decoration: const InputDecoration(
                            labelText: 'Poin',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilihan Jawaban:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: correctAnswerIndex,
                            onChanged: (value) {
                              setDialogState(() {
                                correctAnswerIndex = value!;
                              });
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Pilihan ${String.fromCharCode(65 + index)}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  TextField(
                    controller: explanationController,
                    decoration: const InputDecoration(
                      labelText: 'Penjelasan (Opsional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
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
              onPressed: () => _saveQuestion(
                isEdit,
                question?.id,
                questionController.text,
                optionControllers.map((c) => c.text).toList(),
                correctAnswerIndex,
                selectedCategory,
                selectedType,
                int.tryParse(pointsController.text) ?? 10,
                explanationController.text.isEmpty ? null : explanationController.text,
              ),
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion(
    bool isEdit,
    String? id,
    String questionText,
    List<String> options,
    int correctAnswerIndex,
    QuestionCategory category,
    QuestionType type,
    int points,
    String? explanation,
  ) async {
    if (questionText.isEmpty || options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pertanyaan dan semua pilihan harus diisi')),
      );
      return;
    }

    Navigator.pop(context);

    final newQuestion = Question(
      id: id ?? '',
      question: questionText,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      type: type,
      category: category,
      points: points,
      explanation: explanation,
    );

    bool success;
    if (isEdit && id != null) {
      success = await _adminService.updateQuestion(id, newQuestion);
    } else {
      final result = await _adminService.createQuestion(newQuestion);
      success = result != null;
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Soal berhasil diupdate' : 'Soal berhasil ditambahkan'),
          ),
        );
        _loadQuestions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan soal')),
        );
      }
    }
  }

  void _confirmDelete(Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus soal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteQuestion(question.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(String id) async {
    Navigator.pop(context);
    
    final success = await _adminService.deleteQuestion(id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soal berhasil dihapus')),
        );
        _loadQuestions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus soal')),
        );
      }
    }
  }
}