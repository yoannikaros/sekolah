import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminTeachersScreen extends StatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> {
  final AdminService _adminService = AdminService();
  List<Teacher> _teachers = [];
  List<School> _schools = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('Loading teachers, schools, and subjects from AdminService...');
      }
      
      // Load data in parallel for better performance
      final results = await Future.wait([
        _adminService.getAllTeachers(),
        _adminService.getAllSchools(),
        _adminService.getAllSubjects(),
      ]);
      
      final teachers = results[0] as List<Teacher>;
      final schools = results[1] as List<School>;
      final subjects = results[2] as List<Subject>;
      
      if (kDebugMode) {
        print('Loaded ${teachers.length} teachers, ${schools.length} schools, and ${subjects.length} subjects');
        if (teachers.isEmpty) {
          print('WARNING: No teachers found in Firebase. Check your Firebase collection and data.');
        }
      }
      
      setState(() {
        _teachers = teachers;
        _schools = schools;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showTeacherDialog({Teacher? teacher}) async {
    final nameController = TextEditingController(text: teacher?.name ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final phoneController = TextEditingController(text: teacher?.phone ?? '');
    final addressController = TextEditingController(text: teacher?.address ?? '');
    final employeeIdController = TextEditingController(text: teacher?.employeeId ?? '');
    final passwordController = TextEditingController();
    
    String? selectedSchoolId = teacher?.schoolId;
    List<String> selectedSubjectIds = List.from(teacher?.subjectIds ?? []);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(teacher == null ? 'Tambah Guru' : 'Edit Guru'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      if (teacher == null) ...[
                        TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: employeeIdController,
                        decoration: const InputDecoration(
                          labelText: 'NIP/ID Karyawan',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedSchoolId,
                        decoration: const InputDecoration(
                          labelText: 'Sekolah',
                          border: OutlineInputBorder(),
                        ),
                        items: _schools.map((school) {
                          return DropdownMenuItem<String>(
                            value: school.id,
                            child: Text(school.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSchoolId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pilih sekolah';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mata Pelajaran yang Diajar:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (selectedSchoolId != null) ...[
                              ..._subjects
                                  .where((subject) => subject.schoolId == selectedSchoolId)
                                  .map((subject) {
                                return CheckboxListTile(
                                  title: Text(subject.name),
                                  subtitle: Text(subject.description),
                                  value: selectedSubjectIds.contains(subject.id),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedSubjectIds.add(subject.id);
                                      } else {
                                        selectedSubjectIds.remove(subject.id);
                                      }
                                    });
                                  },
                                );
                              }),
                            ] else ...[
                              const Text('Pilih sekolah terlebih dahulu'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        emailController.text.isEmpty ||
                        selectedSchoolId == null ||
                        (teacher == null && passwordController.text.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mohon lengkapi semua field yang wajib')),
                      );
                      return;
                    }

                    // Store context reference before async operations
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    try {
                      if (teacher == null) {
                        // Create new teacher
                        await _adminService.createTeacher(
                          name: nameController.text,
                          email: emailController.text,
                          password: passwordController.text,
                          schoolId: selectedSchoolId!,
                          phone: phoneController.text.isEmpty ? null : phoneController.text,
                          address: addressController.text.isEmpty ? null : addressController.text,
                          employeeId: employeeIdController.text.isEmpty ? null : employeeIdController.text,
                          subjectIds: selectedSubjectIds,
                        );
                        
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Guru berhasil ditambahkan')),
                        );
                      } else {
                        // Update existing teacher
                        final updatedTeacher = teacher.copyWith(
                          name: nameController.text,
                          email: emailController.text,
                          schoolId: selectedSchoolId!,
                          phone: phoneController.text.isEmpty ? null : phoneController.text,
                          address: addressController.text.isEmpty ? null : addressController.text,
                          employeeId: employeeIdController.text.isEmpty ? null : employeeIdController.text,
                          subjectIds: selectedSubjectIds,
                          updatedAt: DateTime.now(),
                        );
                        
                        await _adminService.updateTeacher(teacher.id, updatedTeacher);
                        
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Guru berhasil diperbarui')),
                        );
                      }
                      
                      if (!mounted) return;
                      navigator.pop();
                      _loadData();
                    } catch (e) {
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(teacher == null ? 'Tambah' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus guru ${teacher.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteTeacher(teacher.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guru berhasil dihapus')),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error menghapus guru: $e')),
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
        createdAt: DateTime.now(),
      ),
    );
    return school.name;
  }

  List<String> _getSubjectNames(List<String> subjectIds) {
    return subjectIds.map((id) {
      final subject = _subjects.firstWhere(
        (s) => s.id == id,
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
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Guru'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                        'Total Guru: ${_teachers.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showTeacherDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Guru'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _teachers.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada guru yang terdaftar',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _teachers.length,
                          itemBuilder: (context, index) {
                            final teacher = _teachers[index];
                            final subjectNames = _getSubjectNames(teacher.subjectIds);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: teacher.isActive 
                                      ? Colors.green 
                                      : Colors.grey,
                                  child: Text(
                                    teacher.name.isNotEmpty 
                                        ? teacher.name[0].toUpperCase() 
                                        : 'G',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  teacher.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: teacher.isActive 
                                        ? null 
                                        : Colors.grey,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${teacher.email}'),
                                    Text('Sekolah: ${_getSchoolName(teacher.schoolId)}'),
                                    if (teacher.employeeId != null)
                                      Text('NIP: ${teacher.employeeId}'),
                                    if (subjectNames.isNotEmpty)
                                      Text('Mata Pelajaran: ${subjectNames.join(', ')}'),
                                    if (!teacher.isActive)
                                      const Text(
                                        'Status: Tidak Aktif',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _showTeacherDialog(teacher: teacher);
                                        break;
                                      case 'delete':
                                        _deleteTeacher(teacher);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text('Edit'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
                                        title: Text('Hapus'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeacherDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}