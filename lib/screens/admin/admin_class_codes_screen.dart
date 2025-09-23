import 'package:flutter/material.dart';
import '../../models/quiz_models.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminClassCodesScreen extends StatefulWidget {
  const AdminClassCodesScreen({super.key});

  @override
  State<AdminClassCodesScreen> createState() => _AdminClassCodesScreenState();
}

class _AdminClassCodesScreenState extends State<AdminClassCodesScreen> {
  final AdminService _adminService = AdminService();
  List<ClassCode> _classCodes = [];
  List<School> _schools = [];
  Map<String, String> _schoolNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadSchools();
    await _loadClassCodes();
    setState(() => _isLoading = false);
  }

  Future<void> _loadSchools() async {
    final schools = await _adminService.getAllSchools();
    setState(() {
      _schools = schools;
      _schoolNames = {for (var school in schools) school.id: school.name};
    });
  }

  Future<void> _loadClassCodes() async {
    final classCodes = await _adminService.getAllClassCodes();
    setState(() {
      _classCodes = classCodes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kode Kelas'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClassCodeDialog(),
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classCodes.isEmpty
              ? const Center(
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
                        'Tap tombol + untuk menambah kode kelas baru',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classCodes.length,
                    itemBuilder: (context, index) {
                      final classCode = _classCodes[index];
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
                              color: classCode.isActive 
                                  ? Colors.blue[100] 
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.class_,
                              color: classCode.isActive 
                                  ? Colors.blue[600] 
                                  : Colors.grey[600],
                            ),
                          ),
                          title: Text(
                            classCode.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Kode: ${classCode.code}'),
                              Text('Sekolah: ${_schoolNames[classCode.schoolId] ?? 'Tidak diketahui'}'),
                              Text(classCode.description),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    classCode.isActive 
                                        ? Icons.check_circle 
                                        : Icons.cancel,
                                    size: 16,
                                    color: classCode.isActive 
                                        ? Colors.green 
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    classCode.isActive ? 'Aktif' : 'Nonaktif',
                                    style: TextStyle(
                                      color: classCode.isActive 
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
                                  _showClassCodeDialog(classCode: classCode);
                                  break;
                                case 'delete':
                                  _confirmDelete(classCode);
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
    );
  }

  void _showClassCodeDialog({ClassCode? classCode}) {
    final isEdit = classCode != null;
    final nameController = TextEditingController(text: classCode?.name ?? '');
    final descriptionController = TextEditingController(text: classCode?.description ?? '');
    final codeController = TextEditingController(text: classCode?.code ?? '');
    String? selectedSchoolId = classCode?.schoolId;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Kode Kelas' : 'Tambah Kode Kelas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kelas',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSchoolId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Sekolah',
                    border: OutlineInputBorder(),
                  ),
                  items: _schools.map((school) {
                    return DropdownMenuItem<String>(
                      value: school.id,
                      child: Text(school.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSchoolId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih sekolah terlebih dahulu';
                    }
                    return null;
                  },
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
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Kode Kelas',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final newCode = await _adminService.generateUniqueClassCode();
                      codeController.text = newCode;
                    },
                  ),
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
            onPressed: () => _saveClassCode(
              isEdit,
              classCode?.id,
              nameController.text,
              descriptionController.text,
              codeController.text,
              selectedSchoolId,
            ),
            child: Text(isEdit ? 'Update' : 'Simpan'),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _saveClassCode(
    bool isEdit,
    String? id,
    String name,
    String description,
    String code,
    String? schoolId,
  ) async {
    if (name.isEmpty || description.isEmpty || code.isEmpty || schoolId == null || schoolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi termasuk sekolah')),
      );
      return;
    }

    Navigator.pop(context);

    final newClassCode = ClassCode(
      id: id ?? '',
      code: code,
      name: name,
      description: description,
      teacherId: 'admin', // TODO: Get from auth
      schoolId: schoolId,
      createdAt: DateTime.now(),
      isActive: true,
    );

    bool success;
    if (isEdit && id != null) {
      success = await _adminService.updateClassCode(id, newClassCode);
    } else {
      final result = await _adminService.createClassCode(newClassCode);
      success = result != null;
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Kode kelas berhasil diupdate' : 'Kode kelas berhasil ditambahkan'),
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan kode kelas')),
        );
      }
    }
  }

  void _confirmDelete(ClassCode classCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus kode kelas "${classCode.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteClassCode(classCode.id),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClassCode(String id) async {
    Navigator.pop(context);
    
    final success = await _adminService.deleteClassCode(id);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode kelas berhasil dihapus')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus kode kelas')),
        );
      }
    }
  }
}