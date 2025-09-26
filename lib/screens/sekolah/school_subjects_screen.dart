import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/admin_service.dart';

class SchoolSubjectsScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const SchoolSubjectsScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<SchoolSubjectsScreen> createState() => _SchoolSubjectsScreenState();
}

class _SchoolSubjectsScreenState extends State<SchoolSubjectsScreen> {
  final AdminService _adminService = AdminService();
  List<Subject> _subjects = [];
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
    final subjects = await _adminService.getSubjectsBySchool(widget.schoolId);
    final classCodes = await _adminService.getClassCodesBySchool(widget.schoolId);
    setState(() {
      _subjects = subjects;
      _classCodes = classCodes.where((cc) => cc.isActive).toList();
      _isLoading = false;
    });
  }

  List<Subject> get _filteredSubjects {
    if (_selectedClassCodeId == null) return _subjects;
    return _subjects.where((s) => s.classCodeIds.contains(_selectedClassCodeId)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Mata Pelajaran - ${widget.schoolName}'),
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
        onPressed: () => _showSubjectDialog(),
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
                  child: _filteredSubjects.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada mata pelajaran',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap tombol + untuk menambah mata pelajaran baru',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredSubjects.length,
                            itemBuilder: (context, index) {
                              final subject = _filteredSubjects[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: subject.isActive 
                                        ? Colors.green[100] 
                                        : Colors.grey[300],
                                    child: Text(
                                      subject.code.isNotEmpty 
                                          ? subject.code.substring(0, 2).toUpperCase()
                                          : 'MP',
                                      style: TextStyle(
                                        color: subject.isActive 
                                            ? Colors.green[600] 
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    subject.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Kode: ${subject.code}'),
                                      if (subject.description.isNotEmpty)
                                        Text('Deskripsi: ${subject.description}'),
                                      Text('Kelas: ${_getClassNames(subject.classCodeIds)}'),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            subject.isActive 
                                                ? Icons.check_circle 
                                                : Icons.cancel,
                                            size: 16,
                                            color: subject.isActive 
                                                ? Colors.green 
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            subject.isActive ? 'Aktif' : 'Nonaktif',
                                            style: TextStyle(
                                              color: subject.isActive 
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
                                          _showSubjectDialog(subject: subject);
                                          break;
                                        case 'delete':
                                          _confirmDelete(subject);
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

  String _getClassNames(List<String> classCodeIds) {
    if (classCodeIds.isEmpty) return 'Tidak ada kelas';
    
    final classNames = classCodeIds.map((id) {
      final classCode = _classCodes.firstWhere(
        (cc) => cc.id == id,
        orElse: () => ClassCode(
          id: '',
          code: '',
          name: 'Kelas Tidak Ditemukan',
          description: '',
          teacherId: '',
          schoolId: widget.schoolId,
          createdAt: DateTime.now(),
          isActive: true,
        ),
      );
      return classCode.name;
    }).toList();
    
    return classNames.join(', ');
  }

  void _showSubjectDialog({Subject? subject}) {
    final isEdit = subject != null;
    final nameController = TextEditingController(text: subject?.name ?? '');
    final descriptionController = TextEditingController(text: subject?.description ?? '');
    final codeController = TextEditingController(text: subject?.code ?? '');
    List<String> selectedClassCodeIds = List.from(subject?.classCodeIds ?? []);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran'),
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
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode Mata Pelajaran',
                    border: OutlineInputBorder(),
                    hintText: 'Contoh: MTK, IPA, IPS',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Kelas:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_classCodes.isEmpty)
                        const Text(
                          'Tidak ada kelas tersedia',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _classCodes.map((classCode) {
                            final isSelected = selectedClassCodeIds.contains(classCode.id);
                            return FilterChip(
                              label: Text(classCode.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setDialogState(() {
                                  if (selected) {
                                    selectedClassCodeIds.add(classCode.id);
                                  } else {
                                    selectedClassCodeIds.remove(classCode.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
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
              onPressed: () => _saveSubject(
                isEdit,
                subject?.id,
                nameController.text,
                descriptionController.text,
                codeController.text,
                selectedClassCodeIds,
              ),
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSubject(
    bool isEdit,
    String? id,
    String name,
    String description,
    String code,
    List<String> classCodeIds,
  ) async {
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan kode mata pelajaran harus diisi')),
      );
      return;
    }

    Navigator.pop(context);

    final newSubject = Subject(
      id: id ?? '',
      name: name,
      description: description,
      code: code.toUpperCase(),
      schoolId: widget.schoolId,
      classCodeIds: classCodeIds,
      createdAt: isEdit ? (await _adminService.getSubjectById(id!))?.createdAt ?? DateTime.now() : DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    bool success;
    if (isEdit && id != null) {
      success = await _adminService.updateSubject(id, newSubject);
    } else {
      final result = await _adminService.createSubject(newSubject);
      success = result != null;
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Mata pelajaran berhasil diupdate' : 'Mata pelajaran berhasil ditambahkan'),
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data mata pelajaran')),
        );
      }
    }
  }

  void _confirmDelete(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus mata pelajaran "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteSubject(subject.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubject(String id) async {
    Navigator.pop(context);
    
    final success = await _adminService.deleteSubject(id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mata pelajaran berhasil dihapus')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus mata pelajaran')),
        );
      }
    }
  }
}