import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../models/materi_models.dart';
import '../../services/materi_service.dart';
import 'material_detail_screen.dart';

class MaterialListScreen extends StatefulWidget {
  final Subject subject;
  final String classCodeId;

  const MaterialListScreen({
    super.key,
    required this.subject,
    required this.classCodeId,
  });

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> 
    with TickerProviderStateMixin {
  final MateriService _materiService = MateriService();
  List<Materi> _materials = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));
    
    _loadMaterials();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Color _getSubjectColor(String code) {
    switch (code.toUpperCase()) {
      case 'MTK':
      case 'MATH':
        return const Color(0xFF9C27B0); // Purple
      case 'IPA':
      case 'SCIENCE':
        return const Color(0xFF4CAF50); // Green
      case 'IPS':
      case 'SOCIAL':
        return const Color(0xFF2196F3); // Blue
      case 'BHS':
      case 'BAHASA':
        return const Color(0xFFFF9800); // Orange
      case 'ENG':
      case 'ENGLISH':
        return const Color(0xFFE91E63); // Pink
      case 'SENI':
      case 'ART':
        return const Color(0xFF9E9E9E); // Grey
      case 'OR':
      case 'OLAHRAGA':
        return const Color(0xFF795548); // Brown
      case 'AGAMA':
      case 'REL':
        return const Color(0xFF607D8B); // Blue Grey
      default:
        return const Color(0xFF6B73FF); // Default blue
    }
  }

  Future<void> _loadMaterials() async {
    try {
      setState(() => _isLoading = true);
      
      if (kDebugMode) {
        print('=== MaterialListScreen Debug ===');
        print('Loading materials for subject: ${widget.subject.id} (${widget.subject.name})');
        print('Class code ID: ${widget.classCodeId}');
      }

      // Get materials by class code first, then filter by subject
      List<Materi> materialsByClass = await _materiService.getMateriByClassCode(widget.classCodeId);
      
      if (kDebugMode) {
        print('Found ${materialsByClass.length} materials by class code');
        for (var material in materialsByClass) {
          print('Material: ${material.judul} - Subject: ${material.subjectId} - ClassCodes: ${material.classCodeIds} - Active: ${material.isActive}');
        }
      }
      
      // If no materials found by classCode, try to get materials by subject only as fallback
      if (materialsByClass.isEmpty) {
        if (kDebugMode) {
          print('No materials found by classCode, trying fallback: get by subject only');
        }
        materialsByClass = await _materiService.getMateriBySubject(widget.subject.id);
        if (kDebugMode) {
          print('Fallback found ${materialsByClass.length} materials by subject');
        }
      }
      
      // Filter materials by subject ID
      final filteredMaterials = materialsByClass.where((material) => 
        material.subjectId == widget.subject.id && material.isActive
      ).toList();

      if (kDebugMode) {
        print('After filtering by subject ${widget.subject.id}: ${filteredMaterials.length} materials');
        for (var material in filteredMaterials) {
          print('Filtered Material: ${material.judul} - Subject: ${material.subjectId}');
        }
      }

      // Sort by sortOrder and createdAt
      filteredMaterials.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        } else if (a.sortOrder != null) {
          return -1;
        } else if (b.sortOrder != null) {
          return 1;
        } else {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      setState(() {
        _materials = filteredMaterials;
      });

      // Start animations after loading
      _fadeController.forward();
      _slideController.forward();

      if (kDebugMode) {
        print('Final loaded materials: ${_materials.length}');
        print('=== End MaterialListScreen Debug ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading materials: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Materi> get _filteredMaterials {
    if (_searchQuery.isEmpty) return _materials;
    return _materials.where((material) =>
      material.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (material.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  void _navigateToMaterialDetail(Materi material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialDetailScreen(material: material),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = _getSubjectColor(widget.subject.code);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              subjectColor.withValues(alpha: 0.1),
              Colors.white,
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
                            color: subjectColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back, color: subjectColor),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text(
                              '📚 ${widget.subject.name}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: subjectColor,
                              ),
                            ),
                            const Text(
                              'Materi Pembelajaran',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [subjectColor.withValues(alpha: 0.8), subjectColor],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            _getSubjectIcon(widget.subject.code),
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
                            color: subjectColor.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '🔍 Cari materi yang menarik...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.search,
                              color: subjectColor,
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
                                gradient: LinearGradient(
                                  colors: [subjectColor.withValues(alpha: 0.8), subjectColor],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '📖 Sedang memuat materi...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredMaterials.isEmpty
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                                      Icons.library_books_outlined,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchQuery.isEmpty 
                                        ? '📚 Belum ada materi'
                                        : '🔍 Materi tidak ditemukan',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Materi untuk mata pelajaran ini belum tersedia'
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
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: RefreshIndicator(
                                onRefresh: _loadMaterials,
                                color: subjectColor,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: _filteredMaterials.length,
                                  itemBuilder: (context, index) {
                                    final material = _filteredMaterials[index];
                                    
                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 300 + (index * 100)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white,
                                                  subjectColor.withValues(alpha: 0.05),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: subjectColor.withValues(alpha: 0.2),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () => _navigateToMaterialDetail(material),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20),
                                                  child: Row(
                                                    children: [
                                                      // Material Thumbnail with fun design
                                                      Container(
                                                        width: 70,
                                                        height: 70,
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              subjectColor.withValues(alpha: 0.8),
                                                              subjectColor,
                                                            ],
                                                          ),
                                                          borderRadius: BorderRadius.circular(15),
                                                          image: material.thumbnailUrl != null
                                                              ? DecorationImage(
                                                                  image: NetworkImage(material.thumbnailUrl!),
                                                                  fit: BoxFit.cover,
                                                                )
                                                              : null,
                                                        ),
                                                        child: material.thumbnailUrl == null
                                                            ? TweenAnimationBuilder<double>(
                                                                duration: const Duration(milliseconds: 1500),
                                                                tween: Tween(begin: 0.0, end: 1.0),
                                                                builder: (context, bounceValue, child) {
                                                                  return Transform.scale(
                                                                    scale: 0.8 + (bounceValue * 0.2),
                                                                    child: const Icon(
                                                                      Icons.library_books_rounded,
                                                                      color: Colors.white,
                                                                      size: 32,
                                                                    ),
                                                                  );
                                                                },
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 16),
                                                      
                                                      // Material Info
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              material.judul,
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.black87,
                                                              ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 6),
                                                            if (material.description != null && material.description!.isNotEmpty) ...[
                                                              Text(
                                                                material.description!,
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors.grey[700],
                                                                ),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              const SizedBox(height: 8),
                                                            ],
                                                            Row(
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(
                                                                    horizontal: 8,
                                                                    vertical: 4,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color: subjectColor.withValues(alpha: 0.1),
                                                                    borderRadius: BorderRadius.circular(12),
                                                                  ),
                                                                  child: Row(
                                                                    mainAxisSize: MainAxisSize.min,
                                                                    children: [
                                                                      Icon(
                                                                        Icons.access_time,
                                                                        size: 12,
                                                                        color: subjectColor,
                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                        _formatDate(material.createdAt),
                                                                        style: TextStyle(
                                                                          fontSize: 11,
                                                                          color: subjectColor,
                                                                          fontWeight: FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                if (material.sortOrder != null) ...[
                                                                  const SizedBox(width: 8),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal: 8,
                                                                      vertical: 4,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      gradient: LinearGradient(
                                                                        colors: [Colors.orange[300]!, Colors.orange[500]!],
                                                                      ),
                                                                      borderRadius: BorderRadius.circular(12),
                                                                    ),
                                                                    child: Text(
                                                                      '📋 ${material.sortOrder}',
                                                                      style: const TextStyle(
                                                                        fontSize: 11,
                                                                        color: Colors.white,
                                                                        fontWeight: FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
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
                                                            child: Container(
                                                              padding: const EdgeInsets.all(8),
                                                              decoration: BoxDecoration(
                                                                color: subjectColor.withValues(alpha: 0.1),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: Icon(
                                                                Icons.arrow_forward_rounded,
                                                                color: subjectColor,
                                                                size: 20,
                                                              ),
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
        return Icons.calculate;
      case 'IPA':
      case 'SCIENCE':
        return Icons.science;
      case 'IPS':
      case 'SOCIAL':
        return Icons.public;
      case 'BHS':
      case 'BAHASA':
        return Icons.translate;
      case 'ENG':
      case 'ENGLISH':
        return Icons.language;
      case 'SENI':
      case 'ART':
        return Icons.palette;
      case 'OR':
      case 'OLAHRAGA':
        return Icons.sports;
      case 'AGAMA':
      case 'REL':
        return Icons.mosque;
      default:
        return Icons.book;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                     'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}