import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/chapter_models.dart';
import '../../services/chapter_service.dart';

class CreateQuestionScreen extends StatefulWidget {
  final Quiz quiz;

  const CreateQuestionScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterService = ChapterService();
  
  // Form controllers
  final _questionTextController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');
  final _essayKeyAnswerController = TextEditingController();
  
  // Question data
  QuestionType _questionType = QuestionType.multipleChoice;
  List<MultipleChoiceOption> _options = [];
  List<TextEditingController> _optionControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeOptions();
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _pointsController.dispose();
    _essayKeyAnswerController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeOptions() {
    // Initialize with 4 empty options (A, B, C, D)
    _options = [
      MultipleChoiceOption(
        id: '',
        optionText: '',
        optionLabel: 'A',
        isCorrect: false,
      ),
      MultipleChoiceOption(
        id: '',
        optionText: '',
        optionLabel: 'B',
        isCorrect: false,
      ),
      MultipleChoiceOption(
        id: '',
        optionText: '',
        optionLabel: 'C',
        isCorrect: false,
      ),
      MultipleChoiceOption(
        id: '',
        optionText: '',
        optionLabel: 'D',
        isCorrect: false,
      ),
    ];

    // Initialize controllers for each option
    _optionControllers = _options.map((option) => TextEditingController(text: option.optionText)).toList();
  }

  void _onQuestionTypeChanged(QuestionType? type) {
    if (type != null) {
      setState(() {
        _questionType = type;
      });
    }
  }

  void _onOptionTextChanged(int index, String text) {
    if (index < _options.length) {
      _options[index] = _options[index].copyWith(optionText: text);
    }
  }

  void _onOptionCorrectChanged(int index, bool? isCorrect) {
    if (index < _options.length && isCorrect != null) {
      setState(() {
        // For multiple choice, only one option can be correct
        for (int i = 0; i < _options.length; i++) {
          _options[i] = _options[i].copyWith(isCorrect: i == index ? isCorrect : false);
        }
      });
    }
  }

  Future<void> _createQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate multiple choice options
    if (_questionType == QuestionType.multipleChoice) {
      // Check if all options have text
      bool hasEmptyOptions = false;
      for (int i = 0; i < _optionControllers.length; i++) {
        if (_optionControllers[i].text.trim().isEmpty) {
          hasEmptyOptions = true;
          break;
        }
      }

      if (hasEmptyOptions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua opsi pilihan ganda harus diisi'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if at least one option is marked as correct
      bool hasCorrectOption = _options.any((option) => option.isCorrect);
      if (!hasCorrectOption) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih minimal satu jawaban yang benar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update options with current text from controllers
      for (int i = 0; i < _optionControllers.length; i++) {
        _options[i] = _options[i].copyWith(optionText: _optionControllers[i].text.trim());
      }
    }

    setState(() => _isLoading = true);

    try {
      // Create new question
      final newQuestion = Question(
        id: '', // Will be set by Firestore
        quizId: widget.quiz.id,
        questionText: _questionTextController.text.trim(),
        questionType: _questionType,
        multipleChoiceOptions: _questionType == QuestionType.multipleChoice ? _options : null,
        essayKeyAnswer: _questionType == QuestionType.essay ? _essayKeyAnswerController.text.trim() : null,
        points: int.tryParse(_pointsController.text) ?? 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      if (kDebugMode) {
        print('CreateQuestionScreen: Creating question...');
        print('Question type: ${newQuestion.questionType}');
        print('Question text: ${newQuestion.questionText}');
        if (newQuestion.multipleChoiceOptions != null) {
          print('Options count: ${newQuestion.multipleChoiceOptions!.length}');
          for (int i = 0; i < newQuestion.multipleChoiceOptions!.length; i++) {
            final option = newQuestion.multipleChoiceOptions![i];
            print('Option ${option.optionLabel}: "${option.optionText}" (correct: ${option.isCorrect})');
          }
        }
      }

      await _chapterService.createQuestion(newQuestion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soal berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (kDebugMode) {
        print('CreateQuestionScreen: Error creating question: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat soal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Soal Baru'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kuis: ${widget.quiz.title}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question text
                    TextFormField(
                      controller: _questionTextController,
                      decoration: const InputDecoration(
                        labelText: 'Pertanyaan *',
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan pertanyaan...',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pertanyaan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Question type
                    const Text(
                      'Jenis Soal *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<QuestionType>(
                            title: const Text('Pilihan Ganda'),
                            value: QuestionType.multipleChoice,
                            groupValue: _questionType,
                            onChanged: _onQuestionTypeChanged,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<QuestionType>(
                            title: const Text('Essay'),
                            value: QuestionType.essay,
                            groupValue: _questionType,
                            onChanged: _onQuestionTypeChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Multiple choice options
                    if (_questionType == QuestionType.multipleChoice) ...[
                      const Text(
                        'Opsi Pilihan Ganda *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_options.length, (index) {
                        final option = _options[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Correct answer radio
                                Radio<bool>(
                                  value: true,
                                  groupValue: option.isCorrect ? true : null,
                                  onChanged: (value) => _onOptionCorrectChanged(index, value),
                                ),
                                // Option label
                                Text(
                                  '${option.optionLabel}.',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Option text field
                                Expanded(
                                  child: TextFormField(
                                    controller: _optionControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Opsi ${option.optionLabel}',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (value) => _onOptionTextChanged(index, value),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih radio button untuk menandai jawaban yang benar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // Essay key answer
                    if (_questionType == QuestionType.essay) ...[
                      TextFormField(
                        controller: _essayKeyAnswerController,
                        decoration: const InputDecoration(
                          labelText: 'Kunci Jawaban Essay (Opsional)',
                          border: OutlineInputBorder(),
                          hintText: 'Masukkan kunci jawaban untuk essay...',
                        ),
                        maxLines: 3,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Points
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: 'Poin *',
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan poin untuk soal ini',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Poin tidak boleh kosong';
                        }
                        final points = int.tryParse(value);
                        if (points == null || points <= 0) {
                          return 'Poin harus berupa angka positif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Buat Soal'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}