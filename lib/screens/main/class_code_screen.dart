import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../services/quiz_service.dart';
import '../quiz/quiz_dashboard_screen.dart';

class ClassCodeScreen extends StatefulWidget {
  const ClassCodeScreen({super.key});

  @override
  State<ClassCodeScreen> createState() => _ClassCodeScreenState();
}

class _ClassCodeScreenState extends State<ClassCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final QuizService _quizService = QuizService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingClassCode();
  }

  Future<void> _checkExistingClassCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedClassCode = prefs.getString('class_code_id');
    
    if (savedClassCode != null) {
      // Navigate to dashboard if class code already exists
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuizDashboardScreen(classCodeId: savedClassCode),
          ),
        );
      }
    }
  }

  Future<void> _validateAndSaveClassCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Silakan masukkan kode kelas';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print('DEBUG: Validating class code: ${_codeController.text.trim().toUpperCase()}');
      }
      final classCode = await _quizService.validateClassCode(_codeController.text.trim().toUpperCase());
      
      if (classCode != null) {
        if (kDebugMode) {
          print('DEBUG: Class code found: ${classCode.toJson()}');
        }
        // Save class code to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('class_code_id', classCode.id);
        await prefs.setString('class_code', classCode.code);
        await prefs.setString('class_name', classCode.name);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => QuizDashboardScreen(classCodeId: classCode.id),
            ),
          );
        }
      } else {
        if (kDebugMode) {
          print('DEBUG: Class code not found or inactive');
        }
        setState(() {
          _errorMessage = 'Kode kelas tidak valid atau tidak aktif';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error validating class code: $e');
      }
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  size: 60,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Masukkan Kode Kelas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Dapatkan kode kelas dari guru Anda untuk mulai belajar',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Class code input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      letterSpacing: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                  onSubmitted: (_) => _validateAndSaveClassCode(),
                ),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndSaveClassCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
                      : const Text(
                          'Bergabung',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Help text
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Bantuan'),
                      content: const Text(
                        'Kode kelas adalah kombinasi huruf dan angka yang diberikan oleh guru Anda. '
                        'Contoh: ABC123, XYZ789.\n\n'
                        'Jika Anda tidak memiliki kode kelas, silakan hubungi guru Anda.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Mengerti'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Butuh bantuan?',
                  style: TextStyle(color: Colors.blue.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}