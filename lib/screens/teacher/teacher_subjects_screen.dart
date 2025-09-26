import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

class TeacherSubjectsScreen extends StatefulWidget {
  const TeacherSubjectsScreen({super.key});

  @override
  State<TeacherSubjectsScreen> createState() => _TeacherSubjectsScreenState();
}

class _TeacherSubjectsScreenState extends State<TeacherSubjectsScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  List<Subject> _subjects = [];
  List<School> _schools = [];
  List<ClassCode> _classCodes = [];
  Teacher? _currentTeacher;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      if (kDebugMode) {
        print('Loading teacher data and subjects...');
      }
      
      // Get current teacher
      final teacher = await _authService.getCurrentTeacher();
      if (teacher == null) {
        throw Exception('Teacher not found');
      }
      
      // Load all data
      final subjects = await _adminService.getAllSubjects();
      final schools = await _adminService.getAllSchools();
      final classCodes = await _adminService.getAllClassCodes();
      
      // Filter subjects for this teacher's school only
      final teacherSubjects = subjects.where((subject) => 
        subject.schoolId == teacher.schoolId
      ).toList();
      
      if (kDebugMode) {
        print('Loaded ${teacherSubjects.length} subjects for teacher school, ${schools.length} schools, and ${classCodes.length} class codes');
        for (var subject in teacherSubjects) {
          print('Subject: ${subject.name} (ID: ${subject.id}, School: ${subject.schoolId}, ClassCodes: ${subject.classCodeIds})');
        }
      }
      
      if (mounted) {
        setState(() {
          _currentTeacher = teacher;
          _subjects = teacherSubjects;
          _schools = schools;
          _classCodes = classCodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _showSubjectDialog({Subject? subject}) async {
    if (_currentTeacher == null) return;
    
    final nameController = TextEditingController(text: subject?.name ?? '');
    final descriptionController = TextEditingController(text: subject?.description ?? '');
    String selectedSchoolId = _currentTeacher!.schoolId; // Fixed to teacher's school
    List<String> selectedClassCodeIds = List.from(subject?.classCodeIds ?? []);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter class codes by teacher's school
            final availableClassCodes = _classCodes
                .where((cc) => cc.schoolId == selectedSchoolId)
                .toList();

            return AlertDialog(
              title: Text(subject == null ? 'Tambah Mata Pelajaran' : 'Edit Mata Pelajaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Mata Pelajaran',
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
                    // Display school name (read-only for teacher)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[100],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sekolah',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _getSchoolName(selectedSchoolId),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Multiple Class Code Selection
                    if (availableClassCodes.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pilih Kode Kelas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...availableClassCodes.map((classCode) {
                              final isSelected = selectedClassCodeIds.contains(classCode.id);
                              return CheckboxListTile(
                                title: Text(classCode.name),
                                subtitle: Text('Kode: ${classCode.code}'),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedClassCodeIds.add(classCode.id);
                                    } else {
                                      selectedClassCodeIds.remove(classCode.id);
                                    }
                                  });
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              );
                            }),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Belum ada kode kelas untuk sekolah ini.\nHubungi admin untuk menambahkan kode kelas.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(subject == null ? 'Tambah' : 'Update'),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama mata pelajaran harus diisi')),
                      );
                      return;
                    }

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      if (subject == null) {
                        // Create new subject
                        final newSubject = Subject(
                          id: '',
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim(),
                          code: nameController.text.trim().substring(0, 3).toUpperCase(), // Generate code from name
                          schoolId: selectedSchoolId,
                          classCodeIds: selectedClassCodeIds,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          isActive: true, // Explicitly set isActive
                        );
                        if (kDebugMode) {
                          print('Creating new subject: ${newSubject.name}');
                          print('Subject data: ${newSubject.toJson()}');
                        }
                        await _adminService.createSubject(newSubject);
                        if (kDebugMode) {
                          print('Subject created successfully');
                        }
                      } else {
                        // Update existing subject
                        final updatedSubject = subject.copyWith(
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim(),
                          code: nameController.text.trim().substring(0, 3).toUpperCase(),
                          schoolId: selectedSchoolId,
                          classCodeIds: selectedClassCodeIds,
                          updatedAt: DateTime.now(),
                        );
                        await _adminService.updateSubject(updatedSubject.id, updatedSubject);
                      }

                      if (mounted) {
                        navigator.pop();
                        _loadData();
                        
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(subject == null 
                              ? 'Mata pelajaran berhasil ditambahkan' 
                              : 'Mata pelajaran berhasil diupdate'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus mata pelajaran "${subject.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteSubject(subject.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mata pelajaran berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting subject: $e')),
          );
        }
      }
    }
  }

  String _getSchoolName(String schoolId) {
    final school = _schools.firstWhere(
      (s) => s.id == schoolId,
      orElse: () => School(
        id: '',
        name: 'Unknown School',
        address: '',
        phone: '',
        email: '',
        website: '',
        createdAt: DateTime.now(),
      ),
    );
    return school.name;
  }

  String _getClassCodeNames(List<String> classCodeIds) {
    final names = classCodeIds.map((id) {
      final classCode = _classCodes.firstWhere(
        (cc) => cc.id == id,
        orElse: () => ClassCode(
          id: '',
          code: 'Unknown',
          name: 'Unknown',
          description: '',
          teacherId: '',
          schoolId: '',
          createdAt: DateTime.now(),
          isActive: true,
        ),
      );
      return classCode.name;
    }).toList();
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Mata Pelajaran'),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Mata Pelajaran: ${_subjects.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _classCodes.where((cc) => cc.schoolId == _currentTeacher?.schoolId).isEmpty 
                          ? null 
                          : () => _showSubjectDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Mata Pelajaran'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_classCodes.where((cc) => cc.schoolId == _currentTeacher?.schoolId).isEmpty)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.class_, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada kode kelas',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Hubungi admin untuk menambahkan\nkode kelas terlebih dahulu',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: _subjects.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada mata pelajaran',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _subjects.length,
                            itemBuilder: (context, index) {
                              final subject = _subjects[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF009688),
                                    child: Icon(Icons.book, color: Colors.white),
                                  ),
                                  title: Text(
                                    subject.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Sekolah: ${_getSchoolName(subject.schoolId)}'),
                                      if (subject.description.isNotEmpty)
                                        Text('Deskripsi: ${subject.description}'),
                                      if (subject.classCodeIds.isNotEmpty)
                                        Text('Class Codes: ${_getClassCodeNames(subject.classCodeIds)}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showSubjectDialog(subject: subject);
                                      } else if (value == 'delete') {
                                        _deleteSubject(subject);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Hapus', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
              ],
            ),
    );
  }
}