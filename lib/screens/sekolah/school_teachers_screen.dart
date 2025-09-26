import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class SchoolTeachersScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const SchoolTeachersScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<SchoolTeachersScreen> createState() => _SchoolTeachersScreenState();
}

class _SchoolTeachersScreenState extends State<SchoolTeachersScreen> {
  final AdminService _adminService = AdminService();
  List<Teacher> _teachers = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('Loading teachers for school: ${widget.schoolId}');
      }
      final teachers = await _adminService.getTeachersBySchool(widget.schoolId);
      final subjects = await _adminService.getSubjectsBySchool(widget.schoolId);
      
      if (kDebugMode) {
        print('Loaded ${teachers.length} teachers for school ${widget.schoolId}');
        for (var teacher in teachers) {
          print('Teacher: ${teacher.name} (ID: ${teacher.id})');
        }
      }
      setState(() {
        _teachers = teachers;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading teachers: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teachers: $e')),
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
    final confirmPasswordController = TextEditingController();
    
    List<String> selectedSubjectIds = List.from(teacher?.subjectIds ?? []);
    
    bool showPasswordFields = teacher == null; // Only show for new teachers

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(teacher == null ? 'Tambah Guru' : 'Edit Guru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Guru *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telepon',
                        border: OutlineInputBorder(),
                      ),
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
                    
                    // Show password fields only for new teachers
                    if (showPasswordFields) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Kredensial Login Guru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF673AB7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi Password *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Mata Pelajaran yang Diajar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF673AB7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Subject selection
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _subjects.isEmpty
                          ? const Center(
                              child: Text('Belum ada mata pelajaran'),
                            )
                          : ListView.builder(
                              itemCount: _subjects.length,
                              itemBuilder: (context, index) {
                                final subject = _subjects[index];
                                final isSelected = selectedSubjectIds.contains(subject.id);
                                
                                return CheckboxListTile(
                                  title: Text(subject.name),
                                  subtitle: Text(subject.description),
                                  value: isSelected,
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
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(teacher == null ? 'Tambah' : 'Update'),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama guru harus diisi')),
                      );
                      return;
                    }

                    if (emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email harus diisi')),
                      );
                      return;
                    }

                    // Validate password for new teachers
                    if (teacher == null) {
                      if (passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password harus diisi')),
                        );
                        return;
                      }
                      
                      if (passwordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password dan konfirmasi password tidak sama')),
                        );
                        return;
                      }
                      
                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password minimal 6 karakter')),
                        );
                        return;
                      }
                    }

                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      if (teacher == null) {
                        // Create new teacher
                        final result = await _adminService.createTeacher(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                          schoolId: widget.schoolId,
                          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                          employeeId: employeeIdController.text.trim().isEmpty ? null : employeeIdController.text.trim(),
                          subjectIds: selectedSubjectIds,
                        );
                        
                        if (result == null) {
                          throw Exception('Gagal menambahkan guru ke database');
                        }
                        
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Guru berhasil ditambahkan'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        // Update existing teacher
                        final updatedTeacher = teacher.copyWith(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                          employeeId: employeeIdController.text.trim().isEmpty ? null : employeeIdController.text.trim(),
                          subjectIds: selectedSubjectIds,
                          updatedAt: DateTime.now(),
                        );
                        
                        final result = await _adminService.updateTeacher(updatedTeacher.id, updatedTeacher);
                        if (!result) {
                          throw Exception('Gagal mengupdate guru di database');
                        }
                        
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Guru berhasil diupdate'),
                            ),
                          );
                        }
                      }

                      if (mounted) {
                        navigator.pop();
                        _loadTeachers();
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

  Future<void> _deleteTeacher(Teacher teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus guru "${teacher.name}"?'),
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
        await _adminService.deleteTeacher(teacher.id);
        _loadTeachers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guru berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting teacher: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Guru - ${widget.schoolName}'),
        backgroundColor: const Color(0xFFE91E63),
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
                        'Total Guru: ${_teachers.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showTeacherDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Guru'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _teachers.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada guru',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _teachers.length,
                          itemBuilder: (context, index) {
                            final teacher = _teachers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE91E63),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  teacher.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email: ${teacher.email}'),
                                    if (teacher.phone?.isNotEmpty ?? false)
                                      Text('Telepon: ${teacher.phone}'),
                                    if (teacher.employeeId?.isNotEmpty ?? false)
                                      Text('NIP: ${teacher.employeeId}'),
                                    if (teacher.subjectIds.isNotEmpty)
                                      Text('Mata Pelajaran: ${teacher.subjectIds.length} mapel'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showTeacherDialog(teacher: teacher);
                                    } else if (value == 'delete') {
                                      _deleteTeacher(teacher);
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