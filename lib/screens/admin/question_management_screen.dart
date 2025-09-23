import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/chapter_models.dart';
import '../../services/chapter_service.dart';
import 'create_question_screen.dart';
import 'edit_question_screen.dart';

class QuestionManagementScreen extends StatefulWidget {
  final Quiz quiz;

  const QuestionManagementScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends State<QuestionManagementScreen> {
  final _chapterService = ChapterService();
  List<Question> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    
    try {
      if (kDebugMode) {
        print('QuestionManagementScreen: Loading questions for quiz ${widget.quiz.id}...');
        print('Quiz title: ${widget.quiz.title}');
      }
      
      final questions = await _chapterService.getQuestionsByQuizId(widget.quiz.id);
      
      if (kDebugMode) {
        print('QuestionManagementScreen: Loaded ${questions.length} questions');
        for (int i = 0; i < questions.length; i++) {
          final question = questions[i];
          print('Question ${i + 1}: ${question.questionText.substring(0, question.questionText.length > 50 ? 50 : question.questionText.length)}...');
          print('  Type: ${question.questionType}');
          print('  Points: ${question.points}');
          if (question.multipleChoiceOptions != null) {
            print('  Options: ${question.multipleChoiceOptions!.length}');
          }
        }
      }
      
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('QuestionManagementScreen: Error loading questions: $e');
      }
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat soal: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _navigateToCreateQuestion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateQuestionScreen(quiz: widget.quiz),
      ),
    );
    
    // Reload questions if a question was created
    if (result == true) {
      await _loadQuestions();
    }
  }

  Future<void> _navigateToEditQuestion(Question question) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuestionScreen(question: question),
      ),
    );
    
    // Reload questions if a question was updated or deleted
    if (result == true || result == 'deleted') {
      await _loadQuestions();
    }
  }

  Future<void> _confirmDeleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus soal "${question.questionText.length > 50 ? '${question.questionText.substring(0, 50)}...' : question.questionText}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteQuestion(question);
    }
  }

  Future<void> _deleteQuestion(Question question) async {
    try {
      if (kDebugMode) {
        print('QuestionManagementScreen: Deleting question ${question.id}...');
      }

      await _chapterService.deleteQuestion(question.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soal berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadQuestions(); // Reload the list
      }
    } catch (e) {
      if (kDebugMode) {
        print('QuestionManagementScreen: Error deleting question: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menghapus soal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getQuestionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Pilihan Ganda';
      case QuestionType.essay:
        return 'Essay';
    }
  }

  Widget _buildQuestionCard(Question question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          child: Text('${index + 1}'),
        ),
        title: Text(
          question.questionText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  question.questionType == QuestionType.multipleChoice
                      ? Icons.radio_button_checked
                      : Icons.edit_note,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _getQuestionTypeText(question.questionType),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  '${question.points} poin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (question.questionType == QuestionType.multipleChoice && question.multipleChoiceOptions != null) ...[
              const SizedBox(height: 4),
              Text(
                '${question.multipleChoiceOptions!.length} opsi pilihan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Dibuat: ${question.createdAt.toString().substring(0, 16)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _navigateToEditQuestion(question);
                break;
              case 'delete':
                _confirmDeleteQuestion(question);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToEditQuestion(question),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Soal'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Quiz info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.quiz.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Soal: ${_questions.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                if (_questions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total Poin: ${_questions.fold<int>(0, (sum, q) => sum + q.points)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Questions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada soal',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap tombol + untuk menambah soal baru',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuestions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            return _buildQuestionCard(_questions[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateQuestion,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}