import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/chapter_models.dart';
import '../../services/chapter_service.dart';

class EditQuestionScreen extends StatefulWidget {
  final Question question;

  const EditQuestionScreen({
    super.key,
    required this.question,
  });

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterService = ChapterService();
  
  // Form controllers
  late TextEditingController _questionTextController;
  late TextEditingController _pointsController;
  late TextEditingController _essayKeyAnswerController;
  
  // Question data
  late QuestionType _questionType;
  List<MultipleChoiceOption> _options = [];
  List<TextEditingController> _optionControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFromQuestion();
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

  void _initializeFromQuestion() {
    if (kDebugMode) {
      print('EditQuestionScreen: Initializing from question...');
      print('Question ID: ${widget.question.id}');
      print('Question type: ${widget.question.questionType}');
      print('Question text: ${widget.question.questionText}');
      print('Multiple choice options: ${widget.question.multipleChoiceOptions}');
      if (widget.question.multipleChoiceOptions != null) {
        print('Options count: ${widget.question.multipleChoiceOptions!.length}');
        for (int i = 0; i < widget.question.multipleChoiceOptions!.length; i++) {
          final option = widget.question.multipleChoiceOptions![i];
          print('Option ${option.optionLabel}: "${option.optionText}" (correct: ${option.isCorrect})');
        }
      }
    }

    // Initialize controllers
    _questionTextController = TextEditingController(text: widget.question.questionText);
    _pointsController = TextEditingController(text: widget.question.points.toString());
    _essayKeyAnswerController = TextEditingController(text: widget.question.essayKeyAnswer ?? '');
    
    // Initialize question type
    _questionType = widget.question.questionType;

    // Initialize options for multiple choice
    if (_questionType == QuestionType.multipleChoice) {
      // Always create 4 options (A, B, C, D)
      final labels = ['A', 'B', 'C', 'D'];
      
      if (widget.question.multipleChoiceOptions != null && widget.question.multipleChoiceOptions!.isNotEmpty) {
        // Map existing options by label for easy lookup
        final existingOptions = <String, MultipleChoiceOption>{};
        for (var option in widget.question.multipleChoiceOptions!) {
          existingOptions[option.optionLabel] = option;
        }
        
        // Create complete set of options, using existing data where available
        _options = labels.map((label) {
          final existingOption = existingOptions[label];
          if (existingOption != null) {
            if (kDebugMode) {
              print('EditQuestionScreen: Using existing option $label: "${existingOption.optionText}"');
            }
            return existingOption;
          } else {
            if (kDebugMode) {
              print('EditQuestionScreen: Creating new empty option $label');
            }
            return MultipleChoiceOption(
              id: '',
              optionText: '',
              optionLabel: label,
              isCorrect: false,
            );
          }
        }).toList();
      } else {
        if (kDebugMode) {
          print('EditQuestionScreen: No existing options found, creating default empty options');
        }
        // Create default empty options
        _options = labels.map((label) => MultipleChoiceOption(
          id: '',
          optionText: '',
          optionLabel: label,
          isCorrect: false,
        )).toList();
      }

      // Initialize controllers for each option with the correct text
      _optionControllers = _options.map((option) {
        final controller = TextEditingController(text: option.optionText);
        if (kDebugMode) {
          print('EditQuestionScreen: Created controller for option ${option.optionLabel} with text: "${option.optionText}"');
        }
        return controller;
      }).toList();
    }

    if (kDebugMode) {
      print('EditQuestionScreen: Initialization complete');
      print('Total options: ${_options.length}');
      print('Total controllers: ${_optionControllers.length}');
      for (int i = 0; i < _options.length; i++) {
        print('Final option ${_options[i].optionLabel}: "${_options[i].optionText}" (controller: "${_optionControllers[i].text}")');
      }
    }
  }

  void _onQuestionTypeChanged(QuestionType? type) {
    if (type != null && type != _questionType) {
      setState(() {
        _questionType = type;
        
        // If switching to multiple choice, initialize options
        if (type == QuestionType.multipleChoice && _options.isEmpty) {
          _options = [
            MultipleChoiceOption(id: '', optionText: '', optionLabel: 'A', isCorrect: false),
            MultipleChoiceOption(id: '', optionText: '', optionLabel: 'B', isCorrect: false),
            MultipleChoiceOption(id: '', optionText: '', optionLabel: 'C', isCorrect: false),
            MultipleChoiceOption(id: '', optionText: '', optionLabel: 'D', isCorrect: false),
          ];
          _optionControllers = _options.map((option) => TextEditingController(text: option.optionText)).toList();
        }
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

  Future<void> _updateQuestion() async {
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
      // Create updated question
      final updatedQuestion = widget.question.copyWith(
        questionText: _questionTextController.text.trim(),
        questionType: _questionType,
        multipleChoiceOptions: _questionType == QuestionType.multipleChoice ? _options : null,
        essayKeyAnswer: _questionType == QuestionType.essay ? _essayKeyAnswerController.text.trim() : null,
        points: int.tryParse(_pointsController.text) ?? 1,
        updatedAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('EditQuestionScreen: Updating question...');
        print('Question ID: ${updatedQuestion.id}');
        print('Question type: ${updatedQuestion.questionType}');
        print('Question text: ${updatedQuestion.questionText}');
        if (updatedQuestion.multipleChoiceOptions != null) {
          print('Options count: ${updatedQuestion.multipleChoiceOptions!.length}');
          for (int i = 0; i < updatedQuestion.multipleChoiceOptions!.length; i++) {
            final option = updatedQuestion.multipleChoiceOptions![i];
            print('Option ${option.optionLabel}: "${option.optionText}" (correct: ${option.isCorrect})');
          }
        }
      }

      await _chapterService.updateQuestion(widget.question.id, updatedQuestion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soal berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (kDebugMode) {
        print('EditQuestionScreen: Error updating question: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memperbarui soal: $e'),
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

  Future<void> _confirmDeleteQuestion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus soal ini?'),
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
      await _deleteQuestion();
    }
  }

  Future<void> _deleteQuestion() async {
    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('EditQuestionScreen: Deleting question ${widget.question.id}...');
      }

      await _chapterService.deleteQuestion(widget.question.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soal berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, 'deleted'); // Return 'deleted' to indicate deletion
      }
    } catch (e) {
      if (kDebugMode) {
        print('EditQuestionScreen: Error deleting question: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menghapus soal: $e'),
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
        title: const Text('Edit Soal'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _confirmDeleteQuestion,
            icon: const Icon(Icons.delete),
            tooltip: 'Hapus Soal',
          ),
        ],
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
                    // Question info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID Soal: ${widget.question.id}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dibuat: ${widget.question.createdAt.toString().substring(0, 16)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                            onPressed: _isLoading ? null : _updateQuestion,
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
                                : const Text('Perbarui Soal'),
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