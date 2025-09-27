import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/materi_models.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/materi_service.dart';
import '../../services/admin_service.dart';
import 'admin_detail_materi_screen.dart';

class AdminMateriScreen extends StatefulWidget {
  const AdminMateriScreen({super.key});

  @override
  State<AdminMateriScreen> createState() => _AdminMateriScreenState();
}

class _AdminMateriScreenState extends State<AdminMateriScreen> {
  final MateriService _materiService = MateriService();
  final AdminService _adminService = AdminService();
  List<Materi> _materiList = [];
  List<Teacher> _teachers = [];
  List<Subject> _subjects = [];
  List<ClassCode> _classCodes = [];
  List<School> _schools = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('Loading materi and related data...');
      }
      
      // Load data in parallel for better performance
      final results = await Future.wait([
        _materiService.getAllMateri(),
        _adminService.getAllTeachers(),
        _adminService.getAllSubjects(),
        _adminService.getAllClassCodes(),
        _adminService.getAllSchools(),
      ]);
      
      final materiList = results[0] as List<Materi>;
      final teachers = results[1] as List<Teacher>;
      final subjects = results[2] as List<Subject>;
      final classCodes = results[3] as List<ClassCode>;
      final schools = results[4] as List<School>;
      
      if (kDebugMode) {
        print('Loaded ${materiList.length} materi, ${teachers.length} teachers, ${subjects.length} subjects, ${classCodes.length} class codes, ${schools.length} schools');
      }
      
      setState(() {
        _materiList = materiList;
        _teachers = teachers;
        _subjects = subjects;
        _classCodes = classCodes;
        _schools = schools;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Materi> get _filteredMateri {
    if (_searchQuery.isEmpty) {
      return _materiList;
    }
    return _materiList.where((materi) =>
        materi.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (materi.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        _getTeacherName(materi.teacherId).toLowerCase().contains(_searchQuery.toLowerCase()) ||
        _getSubjectName(materi.subjectId).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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

  Future<void> _showMateriDialog({Materi? materi}) async {
    final judulController = TextEditingController(text: materi?.judul ?? '');
    final descriptionController = TextEditingController(text: materi?.description ?? '');
    final sortOrderController = TextEditingController(text: materi?.sortOrder?.toString() ?? '');
    
    String? selectedTeacherId = materi?.teacherId;
    String? selectedSubjectId = materi?.subjectId;
    String? selectedSchoolId = materi?.schoolId;
    List<String> selectedClassCodeIds = List.from(materi?.classCodeIds ?? []);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(materi == null ? 'Tambah Materi' : 'Edit Materi'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: judulController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Materi *',
                          hintText: 'Contoh: BAB 1 - Aljabar Dasar',
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
                      DropdownButtonFormField<String>(
                        value: selectedTeacherId,
                        decoration: const InputDecoration(
                          labelText: 'Guru *',
                          border: OutlineInputBorder(),
                        ),
                        items: _teachers.map((teacher) => DropdownMenuItem(
                          value: teacher.id,
                          child: Text(teacher.name),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedTeacherId = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Mata Pelajaran *',
                          border: OutlineInputBorder(),
                        ),
                        items: _subjects.map((subject) => DropdownMenuItem(
                          value: subject.id,
                          child: Text(subject.name),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedSubjectId = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedSchoolId,
                        decoration: const InputDecoration(
                          labelText: 'Sekolah *',
                          border: OutlineInputBorder(),
                        ),
                        items: _schools.map((school) => DropdownMenuItem(
                          value: school.id,
                          child: Text(school.name),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedSchoolId = value;
                            // Reset class codes when school changes
                            selectedClassCodeIds.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
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
                              'Kode Kelas *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (selectedSchoolId == null)
                              const Text(
                                'Pilih sekolah terlebih dahulu',
                                style: TextStyle(color: Colors.grey),
                              )
                            else if (_classCodes.where((cc) => cc.schoolId == selectedSchoolId).isEmpty)
                              const Text(
                                'Tidak ada kode kelas tersedia untuk sekolah ini',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              ..._classCodes.where((cc) => cc.schoolId == selectedSchoolId).map((classCode) {
                                final isSelected = selectedClassCodeIds.contains(classCode.id);
                                return CheckboxListTile(
                                  title: Text(classCode.name),
                                  subtitle: Text('Kode: ${classCode.code}'),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedClassCodeIds.add(classCode.id);
                                      } else {
                                        selectedClassCodeIds.remove(classCode.id);
                                      }
                                    });
                                  },
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: sortOrderController,
                        decoration: const InputDecoration(
                          labelText: 'Urutan (Opsional)',
                          hintText: 'Angka untuk mengurutkan materi',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedSchoolId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Harap pilih sekolah')),
                      );
                      return;
                    }
                    _saveMateri(
                      materi?.id,
                      judulController.text,
                      descriptionController.text,
                      selectedTeacherId,
                      selectedSubjectId,
                      selectedSchoolId!,
                      selectedClassCodeIds,
                      int.tryParse(sortOrderController.text),
                    );
                  },
                  child: Text(materi == null ? 'Tambah' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveMateri(
    String? id,
    String judul,
    String description,
    String? teacherId,
    String? subjectId,
    String schoolId,
    List<String> classCodeIds,
    int? sortOrder,
  ) async {
    if (judul.isEmpty || teacherId == null || subjectId == null || schoolId.isEmpty || classCodeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field yang wajib')),
      );
      return;
    }

    Navigator.pop(context);

    final now = DateTime.now();
    final newMateri = Materi(
      id: id ?? '',
      judul: judul,
      teacherId: teacherId,
      subjectId: subjectId,
      schoolId: schoolId,
      classCodeIds: classCodeIds,
      description: description.isEmpty ? null : description,
      createdAt: id == null ? now : DateTime.now(), // Keep original if editing
      updatedAt: now,
      isActive: true,
      sortOrder: sortOrder,
    );

    bool success;
    if (id != null) {
      success = await _materiService.updateMateri(id, newMateri);
    } else {
      final result = await _materiService.createMateri(newMateri);
      success = result != null;
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id == null ? 'Materi berhasil ditambahkan' : 'Materi berhasil diupdate'),
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan materi')),
        );
      }
    }
  }

  Future<void> _deleteMateri(Materi materi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus materi "${materi.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _materiService.deleteMateri(materi.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Materi berhasil dihapus')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus materi')),
          );
        }
      }
    }
  }

  void _navigateToDetailMateri(Materi materi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDetailMateriScreen(materi: materi),
      ),
    ).then((_) => _loadData()); // Refresh when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Materi'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMateriDialog(),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari materi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMateri.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'Belum ada materi' : 'Tidak ada materi yang ditemukan',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'Tap tombol + untuk menambah materi baru'
                                  : 'Coba kata kunci lain',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMateri.length,
                          itemBuilder: (context, index) {
                            final materi = _filteredMateri[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    Icons.book,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                title: Text(
                                  materi.judul,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Guru: ${_getTeacherName(materi.teacherId)}'),
                                    Text('Mata Pelajaran: ${_getSubjectName(materi.subjectId)}'),
                                    Text('Kelas: ${_getClassCodeNames(materi.classCodeIds)}'),
                                    if (materi.description != null)
                                      Text(
                                        materi.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'detail':
                                        _navigateToDetailMateri(materi);
                                        break;
                                      case 'edit':
                                        _showMateriDialog(materi: materi);
                                        break;
                                      case 'delete':
                                        _deleteMateri(materi);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'detail',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility, size: 20),
                                          SizedBox(width: 8),
                                          Text('Lihat Detail'),
                                        ],
                                      ),
                                    ),
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
                                onTap: () => _navigateToDetailMateri(materi),
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
}