import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import 'material_list_screen.dart';

class StudentMateriScreen extends StatefulWidget {
  const StudentMateriScreen({super.key});

  @override
  State<StudentMateriScreen> createState() => _StudentMateriScreenState();
}

class _StudentMateriScreenState extends State<StudentMateriScreen> 
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Student? _currentStudent;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadStudentAndSubjects();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentAndSubjects() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current student data
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silakan login terlebih dahulu'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get student profile
      final studentData = await _adminService.getStudentById(user.uid);
      if (studentData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data siswa tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      _currentStudent = studentData;

      // Get subjects by school ID
      if (_currentStudent!.schoolId.isNotEmpty) {
        final subjects = await _adminService.getSubjectsBySchool(_currentStudent!.schoolId);
        setState(() {
          _subjects = subjects;
        });
        _animationController.forward();
      } else {
        if (kDebugMode) {
          print('Student school ID is empty');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading student and subjects: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  List<Subject> get _filteredSubjects {
    if (_searchQuery.isEmpty) return _subjects;
    return _subjects.where((subject) =>
      subject.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      subject.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      subject.description.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _navigateToMaterialList(Subject subject) {
    if (_currentStudent == null) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MaterialListScreen(
          subject: subject,
          classCodeId: _currentStudent!.classCodeId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Color _getSubjectColor(String code) {
    switch (code.toUpperCase()) {
      case 'MTK':
      case 'MATH':
        return Colors.purple;
      case 'IPA':
      case 'SCIENCE':
        return Colors.green;
      case 'IPS':
      case 'SOCIAL':
        return Colors.orange;
      case 'BHS':
      case 'BAHASA':
        return Colors.blue;
      case 'ENG':
      case 'ENGLISH':
        return Colors.indigo;
      case 'SENI':
      case 'ART':
        return Colors.pink;
      case 'OR':
      case 'OLAHRAGA':
        return Colors.red;
      case 'AGAMA':
      case 'REL':
        return Colors.teal;
      default:
        return Colors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B73FF),
              Color(0xFF9DD5FF),
              Color(0xFFFFE4E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with fun design
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '📚 Pilih Pelajaran',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Fun Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '🔍 Cari pelajaran favoritmu...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6B73FF),
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '🎯 Sedang memuat pelajaran...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredSubjects.isEmpty
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                 color: Colors.white.withValues(alpha: 0.9),
                                 borderRadius: BorderRadius.circular(20),
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withValues(alpha: 0.1),
                                     blurRadius: 10,
                                     offset: const Offset(0, 5),
                                   ),
                                 ],
                               ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.orange[300]!, Colors.orange[500]!],
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Icon(
                                      Icons.search_off,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchQuery.isEmpty 
                                        ? '📚 Belum ada pelajaran'
                                        : '🔍 Pelajaran tidak ditemukan',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Hubungi guru untuk menambahkan pelajaran'
                                        : 'Coba kata kunci lain ya!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: RefreshIndicator(
                              onRefresh: _loadStudentAndSubjects,
                              color: const Color(0xFF6B73FF),
                              child: GridView.builder(
                                padding: const EdgeInsets.all(20),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
                                ),
                                itemCount: _filteredSubjects.length,
                                itemBuilder: (context, index) {
                                  final subject = _filteredSubjects[index];
                                  final color = _getSubjectColor(subject.code);
                                  
                                  return TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 300 + (index * 100)),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                               begin: Alignment.topLeft,
                                               end: Alignment.bottomRight,
                                               colors: [
                                                 color.withValues(alpha: 0.8),
                                                 color,
                                               ],
                                             ),
                                             borderRadius: BorderRadius.circular(20),
                                             boxShadow: [
                                               BoxShadow(
                                                 color: color.withValues(alpha: 0.3),
                                                 blurRadius: 15,
                                                 offset: const Offset(0, 8),
                                               ),
                                             ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () => _navigateToMaterialList(subject),
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Subject Icon with bounce animation
                                                    TweenAnimationBuilder<double>(
                                                      duration: const Duration(milliseconds: 1000),
                                                      tween: Tween(begin: 0.0, end: 1.0),
                                                      builder: (context, bounceValue, child) {
                                                        return Transform.scale(
                                                          scale: 0.8 + (bounceValue * 0.2),
                                                          child: Container(
                                                            width: 50,
                                                            height: 50,
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withValues(alpha: 0.2),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Icon(
                                                              _getSubjectIcon(subject.code),
                                                              color: Colors.white,
                                                              size: 26,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    
                                                    // Subject Name - Flexible to prevent overflow
                                                    Flexible(
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            subject.name,
                                                            style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 6),
                                                          
                                                          // Subject Code with fun styling
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration: BoxDecoration(
                                                               color: Colors.white.withValues(alpha: 0.2),
                                                               borderRadius: BorderRadius.circular(12),
                                                             ),
                                                            child: Text(
                                                              subject.code,
                                                              style: const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    
                                                    // Fun arrow with animation
                                                    TweenAnimationBuilder<double>(
                                                      duration: const Duration(seconds: 2),
                                                      tween: Tween(begin: 0.0, end: 1.0),
                                                      builder: (context, arrowValue, child) {
                                                        return Transform.translate(
                                                          offset: Offset(
                                                            (arrowValue * 8) - 4,
                                                            0,
                                                          ),
                                                          child: const Icon(
                                                            Icons.arrow_forward_rounded,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String code) {
    switch (code.toUpperCase()) {
      case 'MTK':
      case 'MATH':
        return Icons.calculate_rounded;
      case 'IPA':
      case 'SCIENCE':
        return Icons.science_rounded;
      case 'IPS':
      case 'SOCIAL':
        return Icons.public_rounded;
      case 'BHS':
      case 'BAHASA':
        return Icons.translate_rounded;
      case 'ENG':
      case 'ENGLISH':
        return Icons.language_rounded;
      case 'SENI':
      case 'ART':
        return Icons.palette_rounded;
      case 'OR':
      case 'OLAHRAGA':
        return Icons.sports_soccer_rounded;
      case 'AGAMA':
      case 'REL':
        return Icons.mosque_rounded;
      default:
        return Icons.book_rounded;
    }
  }
}