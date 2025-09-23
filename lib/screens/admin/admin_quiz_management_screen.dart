import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/admin_service.dart';

class AdminQuizManagementScreen extends StatefulWidget {
  const AdminQuizManagementScreen({super.key});

  @override
  State<AdminQuizManagementScreen> createState() => _AdminQuizManagementScreenState();
}

class _AdminQuizManagementScreenState extends State<AdminQuizManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  
  List<AdminQuiz> _quizzes = [];
  List<Subject> _subjects = [];
  List<ClassCode> _classCodes = [];
  List<QuizChapter> _chapters = [];
  List<AdminQuestion> _questions = [];
  AdminQuiz? _selectedQuiz;
  QuizChapter? _selectedChapter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _adminService.getAdminQuizzes(),
        _adminService.getAllSubjects(),
        _adminService.getAllClassCodes(),
      ]);
      
      setState(() {
        _quizzes = results[0] as List<AdminQuiz>;
        _subjects = results[1] as List<Subject>;
        _classCodes = results[2] as List<ClassCode>;
        _isLoading = false;
      });
      
      // Load chapters for the first quiz if available
      if (_quizzes.isNotEmpty && _selectedQuiz == null) {
        _selectedQuiz = _quizzes.first;
        await _loadChapters();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadChapters() async {
    if (_selectedQuiz == null) return;
    
    try {
      final chapters = await _adminService.getQuizChapters(_selectedQuiz!.id);
      setState(() {
        _chapters = chapters;
        _selectedChapter = null;
        _questions = [];
      });
      
      // Load questions for the first chapter if available
      if (_chapters.isNotEmpty && _selectedChapter == null) {
        _selectedChapter = _chapters.first;
        await _loadQuestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chapters: $e')),
        );
      }
    }
  }

  Future<void> _loadQuestions() async {
    if (_selectedChapter == null) return;
    
    try {
      final questions = await _adminService.getChapterQuestions(_selectedChapter!.id);
      setState(() {
        _questions = questions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Quiz'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Quiz', icon: Icon(Icons.quiz)),
            Tab(text: 'Bab', icon: Icon(Icons.book)),
            Tab(text: 'Soal', icon: Icon(Icons.question_answer)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQuizTab(),
                _buildChapterTab(),
                _buildQuestionTab(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton(
          onPressed: () => _showAddQuizDialog(),
          backgroundColor: Colors.blue[600],
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 1:
        if (_quizzes.isEmpty) return null;
        return FloatingActionButton(
          onPressed: () => _showAddChapterDialog(),
          backgroundColor: Colors.blue[600],
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 2:
        if (_chapters.isEmpty || _selectedChapter == null) return null;
        return FloatingActionButton(
          onPressed: () => _showAddQuestionDialog(),
          backgroundColor: Colors.blue[600],
          child: const Icon(Icons.add, color: Colors.white),
        );
      default:
        return null;
    }
  }

  Widget _buildQuizTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          final subject = _subjects.firstWhere(
            (s) => s.id == quiz.subjectId,
            orElse: () => Subject(
              id: '',
              name: 'Unknown Subject',
              description: '',
              code: '',
              schoolId: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          final classCode = _classCodes.firstWhere(
            (c) => c.id == quiz.classCodeId,
            orElse: () => ClassCode(
              id: '',
              code: 'Unknown',
              name: 'Unknown Class',
              description: '',
              teacherId: '',
              schoolId: '',
              createdAt: DateTime.now(),
            ),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                quiz.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.description),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.subject, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(subject.name, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(width: 16),
                      Icon(Icons.class_, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(classCode.name, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: quiz.isPublished ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          quiz.isPublished ? 'Published' : 'Draft',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${quiz.chapterIds.length} Bab',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'publish',
                    child: Row(
                      children: [
                        Icon(quiz.isPublished ? Icons.unpublished : Icons.publish),
                        const SizedBox(width: 8),
                        Text(quiz.isPublished ? 'Unpublish' : 'Publish'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) => _handleQuizAction(value, quiz),
              ),
              onTap: () => _showQuizDetails(quiz),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChapterTab() {
    if (_quizzes.isEmpty) {
      return const Center(
        child: Text('Belum ada quiz. Buat quiz terlebih dahulu.'),
      );
    }

    return Column(
      children: [
        // Quiz selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Quiz:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AdminQuiz>(
                value: _selectedQuiz,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _quizzes.map((quiz) {
                  return DropdownMenuItem(
                    value: quiz,
                    child: Text(quiz.title),
                  );
                }).toList(),
                onChanged: (quiz) async {
                  setState(() {
                    _selectedQuiz = quiz;
                    _chapters = [];
                    _selectedChapter = null;
                    _questions = [];
                  });
                  if (quiz != null) {
                    await _loadChapters();
                  }
                },
              ),
            ],
          ),
        ),
        // Chapters list
        Expanded(
          child: _selectedQuiz == null
              ? const Center(child: Text('Pilih quiz untuk melihat bab-bab'))
              : RefreshIndicator(
                  onRefresh: _loadChapters,
                  child: _chapters.isEmpty
                      ? const Center(child: Text('Belum ada bab. Tambah bab baru.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _chapters.length,
                          itemBuilder: (context, index) {
                            final chapter = _chapters[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  'Bab ${chapter.orderIndex + 1}: ${chapter.title}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(chapter.description),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${chapter.questionIds.length} soal',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) => _handleChapterAction(value, chapter),
                                ),
                                onTap: () {
                                  setState(() => _selectedChapter = chapter);
                                  _loadQuestions();
                                  _tabController.animateTo(2);
                                },
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildQuestionTab() {
    if (_quizzes.isEmpty) {
      return const Center(
        child: Text('Belum ada quiz. Buat quiz terlebih dahulu.'),
      );
    }

    if (_chapters.isEmpty) {
      return const Center(
        child: Text('Belum ada bab. Tambah bab terlebih dahulu.'),
      );
    }

    return Column(
      children: [
        // Quiz and Chapter selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Quiz:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AdminQuiz>(
                value: _selectedQuiz,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _quizzes.map((quiz) {
                  return DropdownMenuItem(
                    value: quiz,
                    child: Text(quiz.title),
                  );
                }).toList(),
                onChanged: (quiz) async {
                  setState(() {
                    _selectedQuiz = quiz;
                    _chapters = [];
                    _selectedChapter = null;
                    _questions = [];
                  });
                  if (quiz != null) {
                    await _loadChapters();
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Bab:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<QuizChapter>(
                value: _selectedChapter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _chapters.map((chapter) {
                  return DropdownMenuItem(
                    value: chapter,
                    child: Text('Bab ${chapter.orderIndex + 1}: ${chapter.title}'),
                  );
                }).toList(),
                onChanged: (chapter) async {
                  setState(() {
                    _selectedChapter = chapter;
                    _questions = [];
                  });
                  if (chapter != null) {
                    await _loadQuestions();
                  }
                },
              ),
            ],
          ),
        ),
        // Questions list
        Expanded(
          child: _selectedChapter == null
              ? const Center(child: Text('Pilih bab untuk melihat soal-soal'))
              : RefreshIndicator(
                  onRefresh: _loadQuestions,
                  child: _questions.isEmpty
                      ? const Center(child: Text('Belum ada soal. Tambah soal baru.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(
                                  'Soal ${question.orderIndex + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      question.questionText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: question.type == AdminQuestionType.multipleChoice
                                                ? Colors.blue
                                                : Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            question.type == AdminQuestionType.multipleChoice
                                                ? 'Pilihan Ganda'
                                                : 'Essay',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${question.points} poin',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) => _handleQuestionAction(value, question),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  void _showAddQuizDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedSubjectId;
    String? selectedClassCodeId;
    int? timeLimit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Quiz Baru'),
          content: SingleChildScrollView(
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
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran',
                    border: OutlineInputBorder(),
                  ),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem(
                      value: subject.id,
                      child: Text(subject.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedSubjectId = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClassCodeId,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
                    border: OutlineInputBorder(),
                  ),
                  items: _classCodes.map((classCode) {
                    return DropdownMenuItem(
                      value: classCode.id,
                      child: Text('${classCode.code} - ${classCode.name}'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedClassCodeId = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Batas Waktu (menit, opsional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    timeLimit = int.tryParse(value);
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
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (titleController.text.isNotEmpty &&
                    selectedSubjectId != null &&
                    selectedClassCodeId != null) {
                  await _createQuiz(
                    titleController.text,
                    descriptionController.text,
                    selectedSubjectId!,
                    selectedClassCodeId!,
                    timeLimit,
                  );
                  if (mounted) {
                    navigator.pop();
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChapterDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Bab Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Bab',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (titleController.text.isNotEmpty) {
                await _createChapter(
                  titleController.text,
                  descriptionController.text,
                );
                if (mounted) {
                  navigator.pop();
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog() {
    final questionController = TextEditingController();
    final explanationController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    AdminQuestionType selectedType = AdminQuestionType.multipleChoice;
    List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    int correctAnswerIndex = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Soal Baru'),
          content: SingleChildScrollView(
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
                DropdownButtonFormField<AdminQuestionType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Soal',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AdminQuestionType.multipleChoice,
                      child: Text('Pilihan Ganda (ABC)'),
                    ),
                    DropdownMenuItem(
                      value: AdminQuestionType.essay,
                      child: Text('Essay'),
                    ),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                if (selectedType == AdminQuestionType.multipleChoice) ...[
                  const Text('Pilihan Jawaban:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: correctAnswerIndex,
                            onChanged: (value) => setState(() => correctAnswerIndex = value!),
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
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: explanationController,
                  decoration: const InputDecoration(
                    labelText: 'Penjelasan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Poin',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (questionController.text.isNotEmpty) {
                  await _createQuestion(
                    questionController.text,
                    selectedType,
                    selectedType == AdminQuestionType.multipleChoice
                        ? optionControllers.map((c) => c.text).toList()
                        : [],
                    selectedType == AdminQuestionType.multipleChoice
                        ? correctAnswerIndex
                        : null,
                    explanationController.text.isNotEmpty
                        ? explanationController.text
                        : null,
                    int.tryParse(pointsController.text) ?? 10,
                  );
                  if (mounted) {
                    navigator.pop();
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createQuiz(
    String title,
    String description,
    String subjectId,
    String classCodeId,
    int? timeLimit,
  ) async {
    try {
      final quiz = AdminQuiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        subjectId: subjectId,
        classCodeId: classCodeId,
        createdBy: 'current_admin_id', // TODO: Get from auth
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timeLimit: timeLimit,
      );

      await _adminService.createAdminQuiz(quiz);
      await _loadData();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Quiz berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Error creating quiz: $e')),
        );
      }
    }
  }

  Future<void> _createChapter(String title, String description) async {
    if (_selectedQuiz == null) return;
    
    try {
      final chapter = QuizChapter(
        id: '',
        title: title,
        description: description,
        quizId: _selectedQuiz!.id,
        orderIndex: _chapters.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _adminService.createQuizChapter(chapter);
      await _loadChapters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chapter: $e')),
        );
      }
    }
  }

  Future<void> _createQuestion(
    String question,
    AdminQuestionType type,
    List<String> options,
    int? correctAnswerIndex,
    String? explanation,
    int points,
  ) async {
    if (_selectedChapter == null) return;

    try {
      final adminQuestion = AdminQuestion(
        id: '',
        questionText: question,
        type: type,
        chapterId: _selectedChapter!.id,
        options: options,
        correctAnswerIndex: correctAnswerIndex,
        explanation: explanation,
        points: points,
        orderIndex: _questions.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _adminService.createAdminQuestion(adminQuestion);
      await _loadQuestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soal berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating question: $e')),
        );
      }
    }
  }

  void _handleChapterAction(String action, QuizChapter chapter) async {
    switch (action) {
      case 'edit':
        // TODO: Implement edit chapter
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit chapter functionality coming soon')),
        );
        break;
      case 'delete':
        await _adminService.deleteQuizChapter(chapter.id);
        await _loadChapters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bab berhasil dihapus')),
          );
        }
        break;
    }
  }

  void _handleQuestionAction(String action, AdminQuestion question) async {
    switch (action) {
      case 'edit':
        // TODO: Implement edit question
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit question functionality coming soon')),
        );
        break;
      case 'delete':
        await _adminService.deleteAdminQuestion(question.id);
        await _loadQuestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Soal berhasil dihapus')),
          );
        }
        break;
    }
  }

  void _handleQuizAction(String action, AdminQuiz quiz) async {
    switch (action) {
      case 'edit':
        // TODO: Implement edit quiz
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit quiz functionality coming soon')),
        );
        break;
      case 'publish':
        try {
          final updatedQuiz = AdminQuiz(
            id: quiz.id,
            title: quiz.title,
            description: quiz.description,
            subjectId: quiz.subjectId,
            classCodeId: quiz.classCodeId,
            createdBy: quiz.createdBy,
            createdAt: quiz.createdAt,
            updatedAt: DateTime.now(),
            timeLimit: quiz.timeLimit,
            isPublished: !quiz.isPublished,
            chapterIds: quiz.chapterIds,
          );
          await _adminService.updateAdminQuiz(updatedQuiz);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(quiz.isPublished ? 'Quiz unpublished' : 'Quiz published')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating quiz: $e')),
            );
          }
        }
        break;
      case 'delete':
        try {
          await _adminService.deleteAdminQuiz(quiz.id);
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quiz berhasil dihapus')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting quiz: $e')),
            );
          }
        }
        break;
    }
  }

  void _showQuizDetails(AdminQuiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailScreen(quiz: quiz),
      ),
    );
  }
}

class QuizDetailScreen extends StatefulWidget {
  final AdminQuiz quiz;

  const QuizDetailScreen({super.key, required this.quiz});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  
  List<QuizChapter> _chapters = [];
  List<AdminQuestion> _questions = [];
  QuizChapter? _selectedChapter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChapters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoading = true);
    try {
      final chapters = await _adminService.getQuizChapters(widget.quiz.id);
      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chapters: $e')),
        );
      }
    }
  }

  Future<void> _loadQuestions(String chapterId) async {
    try {
      final questions = await _adminService.getChapterQuestions(chapterId);
      setState(() {
        _questions = questions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bab', icon: Icon(Icons.book)),
            Tab(text: 'Soal', icon: Icon(Icons.question_answer)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChaptersTab(),
                _buildQuestionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChaptersTab() {
    return RefreshIndicator(
      onRefresh: _loadChapters,
      child: _chapters.isEmpty
          ? const Center(child: Text('Belum ada bab. Tambah bab baru.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final chapter = _chapters[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      'Bab ${chapter.orderIndex + 1}: ${chapter.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chapter.description),
                        const SizedBox(height: 4),
                        Text(
                          '${chapter.questionIds.length} soal',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) => _handleChapterAction(value, chapter),
                    ),
                    onTap: () {
                      setState(() => _selectedChapter = chapter);
                      _loadQuestions(chapter.id);
                      _tabController.animateTo(1);
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildQuestionsTab() {
    if (_selectedChapter == null) {
      return const Center(
        child: Text('Pilih bab dari tab sebelumnya untuk melihat soal'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadQuestions(_selectedChapter!.id),
      child: _questions.isEmpty
          ? const Center(child: Text('Belum ada soal. Tambah soal baru.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      'Soal ${question.orderIndex + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: question.type == AdminQuestionType.multipleChoice
                                    ? Colors.blue
                                    : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                question.type == AdminQuestionType.multipleChoice
                                    ? 'Pilihan Ganda'
                                    : 'Essay',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${question.points} poin',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) => _handleQuestionAction(value, question),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddDialog() {
    switch (_tabController.index) {
      case 0:
        _showAddChapterDialog();
        break;
      case 1:
        _showAddQuestionDialog();
        break;
    }
  }

  void _showAddChapterDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Bab Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Bab',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (titleController.text.isNotEmpty) {
                await _createChapter(
                  titleController.text,
                  descriptionController.text,
                );
                if (mounted) {
                  navigator.pop();
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog() {
    if (_selectedChapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bab terlebih dahulu')),
      );
      return;
    }

    final questionController = TextEditingController();
    final explanationController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    AdminQuestionType selectedType = AdminQuestionType.multipleChoice;
    List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    int correctAnswerIndex = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Soal Baru'),
          content: SingleChildScrollView(
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
                DropdownButtonFormField<AdminQuestionType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Soal',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AdminQuestionType.multipleChoice,
                      child: Text('Pilihan Ganda (ABC)'),
                    ),
                    DropdownMenuItem(
                      value: AdminQuestionType.essay,
                      child: Text('Essay'),
                    ),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                if (selectedType == AdminQuestionType.multipleChoice) ...[
                  const Text('Pilihan Jawaban:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: correctAnswerIndex,
                            onChanged: (value) => setState(() => correctAnswerIndex = value!),
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
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: explanationController,
                  decoration: const InputDecoration(
                    labelText: 'Penjelasan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Poin',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (questionController.text.isNotEmpty) {
                  await _createQuestion(
                    questionController.text,
                    selectedType,
                    selectedType == AdminQuestionType.multipleChoice
                        ? optionControllers.map((c) => c.text).toList()
                        : [],
                    selectedType == AdminQuestionType.multipleChoice
                        ? correctAnswerIndex
                        : null,
                    explanationController.text.isNotEmpty
                        ? explanationController.text
                        : null,
                    int.tryParse(pointsController.text) ?? 10,
                  );
                  if (mounted) {
                    navigator.pop();
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createChapter(String title, String description) async {
    try {
      final chapter = QuizChapter(
        id: '',
        title: title,
        description: description,
        quizId: widget.quiz.id,
        orderIndex: _chapters.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _adminService.createQuizChapter(chapter);
      await _loadChapters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bab berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chapter: $e')),
        );
      }
    }
  }

  Future<void> _createQuestion(
    String question,
    AdminQuestionType type,
    List<String> options,
    int? correctAnswerIndex,
    String? explanation,
    int points,
  ) async {
    if (_selectedChapter == null) return;

    try {
      final adminQuestion = AdminQuestion(
        id: '',
        questionText: question,
        type: type,
        chapterId: _selectedChapter!.id,
        options: options,
        correctAnswerIndex: correctAnswerIndex,
        explanation: explanation,
        points: points,
        orderIndex: _questions.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _adminService.createAdminQuestion(adminQuestion);
      await _loadQuestions(_selectedChapter!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Soal berhasil dibuat')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating question: $e')),
        );
      }
    }
  }

  void _handleChapterAction(String action, QuizChapter chapter) async {
    switch (action) {
      case 'edit':
        // TODO: Implement edit chapter
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit chapter functionality coming soon')),
        );
        break;
      case 'delete':
        try {
          await _adminService.deleteQuizChapter(chapter.id);
          await _loadChapters();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bab berhasil dihapus')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting chapter: $e')),
            );
          }
        }
        break;
    }
  }

  void _handleQuestionAction(String action, AdminQuestion question) async {
    switch (action) {
      case 'edit':
        // TODO: Implement edit question
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit question functionality coming soon')),
        );
        break;
      case 'delete':
        try {
          await _adminService.deleteAdminQuestion(question.id);
          await _loadQuestions(_selectedChapter!.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Soal berhasil dihapus')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting question: $e')),
            );
          }
        }
        break;
    }
  }
}