import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/material_models.dart' as material_models;
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/material_service.dart';
import '../../services/admin_service.dart';
import 'material_form_screen.dart';

class MaterialManagementScreen extends StatefulWidget {
  const MaterialManagementScreen({super.key});

  @override
  State<MaterialManagementScreen> createState() => _MaterialManagementScreenState();
}

class _MaterialManagementScreenState extends State<MaterialManagementScreen> {
  final MaterialService _materialService = MaterialService();
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<material_models.Material> _materials = [];
  List<material_models.Material> _filteredMaterials = [];
  List<Subject> _subjects = [];
  List<ClassCode> _classCodes = [];
  List<Teacher> _teachers = [];

  bool _isLoading = true;
  String? _selectedSubjectId;
  String? _selectedClassCodeId;
  String? _selectedTeacherId;
  bool? _selectedPublishedStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterMaterials);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final materials = await _materialService.getAllMaterials();
      final subjects = await _adminService.getAllSubjects();
      final classCodes = await _adminService.getAllClassCodes();
      final teachers = await _adminService.getAllTeachers();

      if (mounted) {
        setState(() {
          _materials = materials;
          _filteredMaterials = materials;
          _subjects = subjects;
          _classCodes = classCodes;
          _teachers = teachers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading materials: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading materials: $e')),
        );
      }
    }
  }

  void _filterMaterials() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMaterials = _materials.where((material) {
        final matchesSearch = query.isEmpty ||
            material.title.toLowerCase().contains(query) ||
            material.content.toLowerCase().contains(query) ||
            material.tags.any((tag) => tag.toLowerCase().contains(query));

        final matchesSubject = _selectedSubjectId == null || 
            material.subjectId == _selectedSubjectId;

        final matchesClassCode = _selectedClassCodeId == null || 
            material.classCodeId == _selectedClassCodeId;

        final matchesTeacher = _selectedTeacherId == null || 
            material.teacherId == _selectedTeacherId;

        final matchesPublished = _selectedPublishedStatus == null || 
            material.isPublished == _selectedPublishedStatus;

        return matchesSearch && matchesSubject && matchesClassCode && 
               matchesTeacher && matchesPublished;
      }).toList();
    });
  }

  String _getSubjectName(String subjectId) {
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
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
    return subject.name;
  }

  String _getClassCodeName(String classCodeId) {
    final classCode = _classCodes.firstWhere(
      (cc) => cc.id == classCodeId,
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
    return '${classCode.name} (${classCode.code})';
  }

  String _getTeacherName(String teacherId) {
    final teacher = _teachers.firstWhere(
      (t) => t.id == teacherId,
      orElse: () => Teacher(
        id: '',
        name: 'Unknown Teacher',
        email: '',
        schoolId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return teacher.name;
  }

  Future<void> _addMaterial() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MaterialFormScreen(),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _editMaterial(material_models.Material material) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialFormScreen(material: material),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteMaterial(material_models.Material material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Materi'),
        content: Text('Apakah Anda yakin ingin menghapus materi "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _materialService.deleteMaterial(material.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Materi berhasil dihapus')),
            );
            _loadData();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gagal menghapus materi')),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting material: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _togglePublishStatus(material_models.Material material) async {
    try {
      final updatedMaterial = material.copyWith(
        isPublished: !material.isPublished,
        publishedAt: !material.isPublished ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

      final success = await _materialService.updateMaterial(material.id, updatedMaterial);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updatedMaterial.isPublished 
                  ? 'Materi berhasil dipublikasikan' 
                  : 'Materi berhasil di-unpublish'),
            ),
          );
          _loadData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengubah status publikasi')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling publish status: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Materi'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua Mata Pelajaran'),
                    ),
                    ..._subjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject.id,
                        child: Text(subject.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedSubjectId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedClassCodeId,
                  decoration: const InputDecoration(
                    labelText: 'Kode Kelas',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua Kelas'),
                    ),
                    ..._classCodes.map((classCode) {
                      return DropdownMenuItem<String>(
                        value: classCode.id,
                        child: Text('${classCode.name} (${classCode.code})'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedClassCodeId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTeacherId,
                  decoration: const InputDecoration(
                    labelText: 'Guru',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Semua Guru'),
                    ),
                    ..._teachers.map((teacher) {
                      return DropdownMenuItem<String>(
                        value: teacher.id,
                        child: Text(teacher.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedTeacherId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<bool>(
                  value: _selectedPublishedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status Publikasi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem<bool>(
                      value: null,
                      child: Text('Semua Status'),
                    ),
                    DropdownMenuItem<bool>(
                      value: true,
                      child: Text('Dipublikasikan'),
                    ),
                    DropdownMenuItem<bool>(
                      value: false,
                      child: Text('Draft'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedPublishedStatus = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSubjectId = null;
                _selectedClassCodeId = null;
                _selectedTeacherId = null;
                _selectedPublishedStatus = null;
              });
              _filterMaterials();
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              _filterMaterials();
              Navigator.of(context).pop();
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Materi'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari materi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Materials List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMaterials.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada materi ditemukan',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: _filteredMaterials.length,
                          itemBuilder: (context, index) {
                            final material = _filteredMaterials[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: material.isPublished
                                      ? Colors.green
                                      : Colors.orange,
                                  child: Icon(
                                    material.isPublished
                                        ? Icons.public
                                        : Icons.edit_note,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  material.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_getSubjectName(material.subjectId)} • ${_getClassCodeName(material.classCodeId)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Guru: ${_getTeacherName(material.teacherId)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (material.tags.isNotEmpty)
                                      Wrap(
                                        spacing: 4,
                                        children: material.tags.take(3).map((tag) {
                                          return Chip(
                                            label: Text(
                                              tag,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editMaterial(material);
                                        break;
                                      case 'toggle_publish':
                                        _togglePublishStatus(material);
                                        break;
                                      case 'delete':
                                        _deleteMaterial(material);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text('Edit'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle_publish',
                                      child: ListTile(
                                        leading: Icon(material.isPublished
                                            ? Icons.unpublished
                                            : Icons.publish),
                                        title: Text(material.isPublished
                                            ? 'Unpublish'
                                            : 'Publish'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
                                        title: Text('Hapus', style: TextStyle(color: Colors.red)),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _editMaterial(material),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMaterial,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}