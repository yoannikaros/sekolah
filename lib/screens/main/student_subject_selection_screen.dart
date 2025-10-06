import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'student_task_submission_screen.dart';

class StudentSubjectSelectionScreen extends StatefulWidget {
  const StudentSubjectSelectionScreen({super.key});

  @override
  State<StudentSubjectSelectionScreen> createState() => _StudentSubjectSelectionScreenState();
}

class _StudentSubjectSelectionScreenState extends State<StudentSubjectSelectionScreen> 
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  List<Subject> _subjects = [];
  Student? _currentStudent;
  String? _currentSchoolId;
  String? _currentClassCode;
  bool _isLoading = true;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadStudentData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    if (kDebugMode) {
      print('=== StudentSubjectSelectionScreen: Starting _loadStudentData ===');
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('StudentSubjectSelectionScreen: No current user found');
        }
        setState(() {
          _errorMessage = 'User tidak ditemukan. Silakan login kembali.';
          _isLoading = false;
        });
        return;
      }

      if (kDebugMode) {
        print('StudentSubjectSelectionScreen: Current user ID: ${user.uid}');
      }

      // Get student data
      Student? student = await _adminService.getStudentByUserId(user.uid);
      
      // If student not found, try to create a basic student profile
      if (student == null) {
        if (kDebugMode) {
          print('StudentSubjectSelectionScreen: Student data not found for user ${user.uid}');
          print('StudentSubjectSelectionScreen: Attempting to create basic student profile');
        }
        
        // Try to get or create student profile using AuthService
        final studentData = await _authService.getOrCreateStudentProfile(
          name: user.displayName ?? user.email?.split('@')[0] ?? 'Student',
          email: user.email ?? '',
        );
        
        if (studentData != null) {
          student = Student.fromJson(studentData);
          if (kDebugMode) {
            print('StudentSubjectSelectionScreen: Created/retrieved student profile: ${student.name}');
          }
        }
      }
      
      if (student == null) {
        if (kDebugMode) {
          print('StudentSubjectSelectionScreen: Failed to create or retrieve student data');
        }
        setState(() {
          _errorMessage = 'Data siswa tidak ditemukan dan tidak dapat dibuat otomatis.\n'
                         'Silakan hubungi admin sekolah untuk mendaftarkan akun Anda.\n\n'
                         'User ID: ${user.uid}\n'
                         'Email: ${user.email ?? 'Tidak tersedia'}';
          _isLoading = false;
        });
        return;
      }

      if (kDebugMode) {
        print('StudentSubjectSelectionScreen: Student found - Name: ${student.name}, School ID: ${student.schoolId}, Class Code ID: ${student.classCodeId}');
      }

      // Check if student has valid school and class code
      if (student.schoolId.isEmpty || student.classCodeId.isEmpty) {
        if (kDebugMode) {
          print('StudentSubjectSelectionScreen: Student has incomplete data - School ID: ${student.schoolId}, Class Code ID: ${student.classCodeId}');
        }
        setState(() {
          _errorMessage = 'Data siswa tidak lengkap.\n'
                         'Sekolah atau kelas belum diatur.\n\n'
                         'Silakan hubungi admin sekolah untuk melengkapi data Anda.\n\n'
                         'Nama: ${student?.name ?? 'Tidak diketahui'}\n'
                         'Email: ${student?.email ?? 'Tidak diketahui'}';
          _isLoading = false;
        });
        return;
      }

      // Get class code data
      final classCode = await _adminService.getClassCodeById(student.classCodeId);
      if (classCode == null) {
        if (kDebugMode) {
          print('StudentSubjectSelectionScreen: Class code not found for ID: ${student.classCodeId}');
        }
        setState(() {
          _errorMessage = 'Kode kelas tidak ditemukan.\n'
                         'Kelas dengan ID ${student!.classCodeId} tidak ada.\n\n'
                         'Hubungi admin sekolah untuk memperbaiki data kelas Anda.';
          _isLoading = false;
        });
        return;
      }

      if (kDebugMode) {
        print('StudentSubjectSelectionScreen: Class code found - Code: ${classCode.code}, Name: ${classCode.name}');
      }

      // Get subjects for this school and class code (use class code document ID, not the code)
      final subjects = await _adminService.getSubjectsBySchoolAndClassCode(student.schoolId, classCode.id);
      
      if (kDebugMode) {
        print('StudentSubjectSelectionScreen: Found ${subjects.length} subjects for school ${student.schoolId} and class ${classCode.id}');
        for (var subject in subjects) {
          print('  - Subject: ${subject.name} (${subject.code}) - Class Codes: ${subject.classCodeIds}');
        }
      }

      setState(() {
        _currentStudent = student;
        _currentSchoolId = student!.schoolId;
        _currentClassCode = classCode.code;
        _subjects = subjects;
        _isLoading = false;
      });
      
      // Start animation after data is loaded
      _animationController.forward();

      if (kDebugMode) {
        print('StudentSubjectSelectionScreen: Data loaded successfully');
        print('  - Student: ${_currentStudent?.name}');
        print('  - School ID: $_currentSchoolId');
        print('  - Class Code: $_currentClassCode');
        print('  - Subjects count: ${_subjects.length}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('StudentSubjectSelectionScreen: Error loading student data: $e');
      }
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memuat data:\n$e\n\n'
                       'Silakan coba lagi atau hubungi admin jika masalah berlanjut.';
        _isLoading = false;
      });
    }
  }

  List<Subject> get _filteredSubjects {
    if (_searchQuery.isEmpty) {
      return _subjects;
    }
    return _subjects.where((subject) {
      return subject.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             subject.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             subject.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('matematika') || name.contains('math')) {
      return Icons.calculate;
    } else if (name.contains('bahasa') || name.contains('language')) {
      return Icons.translate;
    } else if (name.contains('fisika') || name.contains('physics')) {
      return Icons.science;
    } else if (name.contains('kimia') || name.contains('chemistry')) {
      return Icons.biotech;
    } else if (name.contains('biologi') || name.contains('biology')) {
      return Icons.eco;
    } else if (name.contains('sejarah') || name.contains('history')) {
      return Icons.history_edu;
    } else if (name.contains('geografi') || name.contains('geography')) {
      return Icons.public;
    } else if (name.contains('seni') || name.contains('art')) {
      return Icons.palette;
    } else if (name.contains('olahraga') || name.contains('sport')) {
      return Icons.sports;
    } else if (name.contains('komputer') || name.contains('computer') || name.contains('tik')) {
      return Icons.computer;
    } else {
      return Icons.book;
    }
  }

  MaterialColor _getSubjectColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  void _navigateToTaskSubmission(Subject subject) {
    if (kDebugMode) {
      print('StudentSubjectSelectionScreen: Navigating to task submission for subject: ${subject.name}');
      print('  - Subject ID: ${subject.id}');
      print('  - School ID: $_currentSchoolId');
      print('  - Class Code ID: ${_currentStudent?.classCodeId}');
    }

    if (_currentStudent == null || _currentSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data siswa tidak lengkap')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentTaskSubmissionScreen(
          subject: subject,
          student: _currentStudent!,
          schoolId: _currentSchoolId!,
          classCode: _currentClassCode!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[400]!,
                      Colors.cyan[300]!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat datang!',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _currentStudent?.name ?? 'Siswa',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Kelas: ${_currentClassCode ?? '-'}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
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
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearchVisible ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    if (!_isSearchVisible) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
            ],
          ),
          
          // Search Bar
          if (_isSearchVisible)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari mata pelajaran...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          
          // Content
          SliverToBoxAdapter(
            child: _isLoading
                ? SizedBox(
                    height: 400,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Memuat data mata pelajaran...'),
                        ],
                      ),
                    ),
                  )
                : _errorMessage != null
                    ? SizedBox(
                        height: 400,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadStudentData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredSubjects.isEmpty
                        ? SizedBox(
                            height: 400,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty ? Icons.search_off : Icons.book_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty 
                                        ? 'Tidak ada mata pelajaran yang ditemukan'
                                        : 'Belum ada mata pelajaran',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Coba kata kunci lain'
                                        : 'Mata pelajaran untuk kelas ${_currentClassCode ?? '-'}\nbelum tersedia',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mata Pelajaran (${_filteredSubjects.length})',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...List.generate(_filteredSubjects.length, (index) {
                                      final subject = _filteredSubjects[index];
                                      final color = _getSubjectColor(index);
                                      return TweenAnimationBuilder<double>(
                                        duration: Duration(milliseconds: 300 + (index * 100)),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Transform.translate(
                                            offset: Offset(0, 20 * (1 - value)),
                                            child: Opacity(
                                              opacity: value,
                                              child: Container(
                                                margin: const EdgeInsets.only(bottom: 16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: color.withValues(alpha: 0.1),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () => _navigateToTaskSubmission(subject),
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(20),
                                                      child: Row(
                                                        children: [
                                                          Hero(
                                                            tag: 'subject_${subject.id}',
                                                            child: Container(
                                                              width: 60,
                                                              height: 60,
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                  colors: [
                                                                    color.shade400,
                                                                    color.shade600,
                                                                  ],
                                                                ),
                                                                borderRadius: BorderRadius.circular(16),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: color.withValues(alpha: 0.3),
                                                                    blurRadius: 8,
                                                                    offset: const Offset(0, 4),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Icon(
                                                                _getSubjectIcon(subject.name),
                                                                color: Colors.white,
                                                                size: 28,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  subject.name,
                                                                  style: const TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.black87,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(
                                                                    horizontal: 8,
                                                                    vertical: 2,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color: color.withValues(alpha: 0.1),
                                                                    borderRadius: BorderRadius.circular(12),
                                                                  ),
                                                                  child: Text(
                                                                    subject.code,
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      color: color.shade700,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (subject.description.isNotEmpty) ...[
                                                                  const SizedBox(height: 8),
                                                                  Text(
                                                                    subject.description,
                                                                    style: TextStyle(
                                                                      fontSize: 13,
                                                                      color: Colors.grey[600],
                                                                      height: 1.3,
                                                                    ),
                                                                    maxLines: 2,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey[100],
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Icon(
                                                              Icons.arrow_forward_ios,
                                                              color: Colors.grey[600],
                                                              size: 16,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: !_isLoading && _errorMessage == null
          ? FloatingActionButton(
              onPressed: () {
                _animationController.reset();
                _loadStudentData();
              },
              backgroundColor: Colors.blue[600],
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }
}