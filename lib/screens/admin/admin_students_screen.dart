import 'package:flutter/material.dart';
import '../../models/quiz_models.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final AdminService _adminService = AdminService();
  List<Student> _students = [];
  List<ClassCode> _classCodes = [];
  bool _isLoading = true;
  String? _selectedClassCodeId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final students = await _adminService.getAllStudents();
    final classCodes = await _adminService.getAllClassCodes();
    setState(() {
      _students = students;
      _classCodes = classCodes.where((cc) => cc.isActive).toList();
      _isLoading = false;
    });
  }

  List<Student> get _filteredStudents {
    if (_selectedClassCodeId == null) return _students;
    return _students.where((s) => s.classCodeId == _selectedClassCodeId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Siswa'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedClassCodeId = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Semua Kelas'),
              ),
              ..._classCodes.map((cc) => PopupMenuItem(
                value: cc.id,
                child: Text(cc.name),
              )),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedClassCodeId != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.green[50],
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Filter: ${_classCodes.firstWhere((cc) => cc.id == _selectedClassCodeId).name}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _selectedClassCodeId = null),
                          child: const Text('Hapus Filter'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada siswa',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap tombol + untuk menambah siswa baru',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              final classCode = _classCodes.firstWhere(
                                (cc) => cc.id == student.classCodeId,
                                orElse: () => ClassCode(
                                  id: '',
                                  code: '',
                                  name: 'Kelas Tidak Ditemukan',
                                  description: '',
                                  teacherId: '',
                                  schoolId: '', // Add required schoolId parameter
                                  createdAt: DateTime.now(),
                                ),
                              );
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: student.isActive 
                                        ? Colors.green[100] 
                                        : Colors.grey[300],
                                    child: Text(
                                      student.name.isNotEmpty 
                                          ? student.name[0].toUpperCase() 
                                          : 'S',
                                      style: TextStyle(
                                        color: student.isActive 
                                            ? Colors.green[600] 
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('ID: ${student.studentId}'),
                                      Text('Email: ${student.email}'),
                                      Text('Kelas: ${classCode.name}'),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            student.isActive 
                                                ? Icons.check_circle 
                                                : Icons.cancel,
                                            size: 16,
                                            color: student.isActive 
                                                ? Colors.green 
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            student.isActive ? 'Aktif' : 'Nonaktif',
                                            style: TextStyle(
                                              color: student.isActive 
                                                  ? Colors.green 
                                                  : Colors.red,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          _showStudentDialog(student: student);
                                          break;
                                        case 'delete':
                                          _confirmDelete(student);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
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
                ),
              ],
            ),
    );
  }

  void _showStudentDialog({Student? student}) {
    final isEdit = student != null;
    final nameController = TextEditingController(text: student?.name ?? '');
    final emailController = TextEditingController(text: student?.email ?? '');
    final studentIdController = TextEditingController(text: student?.studentId ?? '');
    String selectedClassCodeId = student?.classCodeId ?? (_classCodes.isNotEmpty ? _classCodes.first.id : '');
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Siswa' : 'Tambah Siswa'),
          content: SingleChildScrollView(
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
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID Siswa',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClassCodeId.isNotEmpty ? selectedClassCodeId : null,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
                    border: OutlineInputBorder(),
                  ),
                  items: _classCodes.map((cc) => DropdownMenuItem(
                    value: cc.id,
                    child: Text('${cc.name} (${cc.code})'),
                  )).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedClassCodeId = value ?? '';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => _saveStudent(
                isEdit,
                student?.id,
                nameController.text,
                emailController.text,
                studentIdController.text,
                selectedClassCodeId,
              ),
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStudent(
    bool isEdit,
    String? id,
    String name,
    String email,
    String studentId,
    String classCodeId,
  ) async {
    if (name.isEmpty || email.isEmpty || studentId.isEmpty || classCodeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    Navigator.pop(context);

    final newStudent = Student(
      id: id ?? '',
      name: name,
      email: email,
      studentId: studentId,
      classCodeId: classCodeId,
      schoolId: '', // Add required schoolId parameter
      enrolledAt: DateTime.now(),
      isActive: true,
    );

    bool success;
    if (isEdit && id != null) {
      success = await _adminService.updateStudent(id, newStudent);
    } else {
      final result = await _adminService.createStudent(newStudent);
      success = result != null;
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Siswa berhasil diupdate' : 'Siswa berhasil ditambahkan'),
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data siswa')),
        );
      }
    }
  }

  void _confirmDelete(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus siswa "${student.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteStudent(student.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(String id) async {
    Navigator.pop(context);
    
    final success = await _adminService.deleteStudent(id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siswa berhasil dihapus')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus siswa')),
        );
      }
    }
  }
}