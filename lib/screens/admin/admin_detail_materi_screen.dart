import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/materi_models.dart';
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/materi_service.dart';
import '../../services/admin_service.dart';

class AdminDetailMateriScreen extends StatefulWidget {
  final Materi materi;

  const AdminDetailMateriScreen({
    super.key,
    required this.materi,
  });

  @override
  State<AdminDetailMateriScreen> createState() => _AdminDetailMateriScreenState();
}

class _AdminDetailMateriScreenState extends State<AdminDetailMateriScreen> {
  final MateriService _materiService = MateriService();
  final AdminService _adminService = AdminService();
  List<DetailMateri> _detailMateriList = [];
  List<School> _schools = [];
  List<ClassCode> _classCodes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadDetailMateri(),
      _loadSchools(),
      _loadClassCodes(),
    ]);
  }

  Future<void> _loadSchools() async {
    try {
      final schools = await _adminService.getAllSchools();
      setState(() {
        _schools = schools;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading schools: $e');
      }
    }
  }

  Future<void> _loadClassCodes() async {
    try {
      final classCodes = await _adminService.getAllClassCodes();
      setState(() {
        _classCodes = classCodes;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading class codes: $e');
      }
    }
  }

  Future<void> _loadDetailMateri() async {
    setState(() => _isLoading = true);
    try {
      if (kDebugMode) {
        print('Loading detail materi for materi ID: ${widget.materi.id}');
      }
      
      final detailMateriList = await _materiService.getDetailMateriByMateriId(widget.materi.id);
      
      if (kDebugMode) {
        print('Loaded ${detailMateriList.length} detail materi');
      }
      
      setState(() {
        _detailMateriList = detailMateriList;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading detail materi: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading detail materi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<DetailMateri> get _filteredDetailMateri {
    if (_searchQuery.isEmpty) {
      return _detailMateriList;
    }
    return _detailMateriList.where((detail) =>
        detail.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        detail.paragrafMateri.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _showDetailMateriDialog({DetailMateri? detailMateri}) async {
    final judulController = TextEditingController(text: detailMateri?.judul ?? '');
    final paragrafController = TextEditingController(text: detailMateri?.paragrafMateri ?? '');
    final embedYoutubeController = TextEditingController(text: detailMateri?.embedYoutube ?? '');
    final sortOrderController = TextEditingController(text: detailMateri?.sortOrder?.toString() ?? '');
    
    // Ensure selectedSchoolId exists in the available schools list
    String? initialSchoolId = detailMateri?.schoolId ?? widget.materi.schoolId;
    String? selectedSchoolId = _schools.any((school) => school.id == initialSchoolId) 
        ? initialSchoolId 
        : (_schools.isNotEmpty ? _schools.first.id : null);
    
    // Ensure selectedClassCodeId exists in the available class codes for the selected school
    String? initialClassCodeId = detailMateri?.classCodeId;
    String? selectedClassCodeId = (initialClassCodeId != null && 
        _classCodes.any((classCode) => classCode.id == initialClassCodeId && classCode.schoolId == selectedSchoolId))
        ? initialClassCodeId 
        : null;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(detailMateri == null ? 'Tambah Detail Materi' : 'Edit Detail Materi'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: judulController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Detail Materi *',
                        hintText: 'Contoh: Pengenalan Aljabar',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSchoolId,
                      decoration: const InputDecoration(
                        labelText: 'Sekolah *',
                        border: OutlineInputBorder(),
                      ),
                      items: _schools.isEmpty ? [] : _schools.map((school) {
                        return DropdownMenuItem<String>(
                          value: school.id,
                          child: Text(school.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSchoolId = value;
                          selectedClassCodeId = null; // Reset class code when school changes
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
                    DropdownButtonFormField<String>(
                      value: selectedClassCodeId,
                      decoration: const InputDecoration(
                        labelText: 'Kode Kelas *',
                        border: OutlineInputBorder(),
                      ),
                      items: _classCodes
                          .where((classCode) => classCode.schoolId == selectedSchoolId)
                          .map((classCode) {
                        return DropdownMenuItem<String>(
                          value: classCode.id,
                          child: Text('${classCode.name} (${classCode.code})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedClassCodeId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pilih kode kelas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  TextField(
                    controller: paragrafController,
                    decoration: const InputDecoration(
                      labelText: 'Paragraf Materi *',
                      hintText: 'Masukkan konten materi...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                    minLines: 4,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: embedYoutubeController,
                    decoration: const InputDecoration(
                      labelText: 'Embed YouTube (Opsional)',
                      hintText: 'https://www.youtube.com/embed/VIDEO_ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sortOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Urutan (Opsional)',
                      hintText: 'Angka untuk mengurutkan detail materi',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tips untuk Embed YouTube:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Gunakan format: https://www.youtube.com/embed/VIDEO_ID',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Contoh: https://www.youtube.com/embed/dQw4w9WgXcQ',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Kosongkan jika tidak ada video',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
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
                if (selectedSchoolId == null || selectedClassCodeId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Harap pilih sekolah dan kode kelas')),
                  );
                  return;
                }
                _saveDetailMateri(
                  detailMateri?.id,
                  judulController.text,
                  paragrafController.text,
                  embedYoutubeController.text,
                  int.tryParse(sortOrderController.text),
                  selectedSchoolId!,
                  selectedClassCodeId!,
                );
              },
              child: Text(detailMateri == null ? 'Tambah' : 'Update'),
            ),
          ],
        );
      }
        );
      },
    );
  }

  Future<void> _saveDetailMateri(
    String? id,
    String judul,
    String paragrafMateri,
    String embedYoutube,
    int? sortOrder,
    String schoolId,
    String classCodeId,
  ) async {
    if (judul.isEmpty || paragrafMateri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi judul dan paragraf materi')),
      );
      return;
    }

    Navigator.pop(context);

    final now = DateTime.now();
    final newDetailMateri = DetailMateri(
      id: id ?? '',
      materiId: widget.materi.id,
      schoolId: schoolId,
      classCodeId: classCodeId,
      judul: judul,
      paragrafMateri: paragrafMateri,
      embedYoutube: embedYoutube.isEmpty ? null : embedYoutube,
      createdAt: id == null ? now : DateTime.now(), // Keep original if editing
      updatedAt: now,
      isActive: true,
      sortOrder: sortOrder,
    );

    bool success;
    if (id != null) {
      success = await _materiService.updateDetailMateri(id, newDetailMateri);
    } else {
      final result = await _materiService.createDetailMateri(newDetailMateri);
      success = result != null;
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id == null ? 'Detail materi berhasil ditambahkan' : 'Detail materi berhasil diupdate'),
          ),
        );
        _loadDetailMateri();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan detail materi')),
        );
      }
    }
  }

  Future<void> _deleteDetailMateri(DetailMateri detailMateri) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus detail materi "${detailMateri.judul}"?'),
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
      final success = await _materiService.deleteDetailMateri(detailMateri.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Detail materi berhasil dihapus')),
          );
          _loadDetailMateri();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus detail materi')),
          );
        }
      }
    }
  }

  void _showDetailMateriPreview(DetailMateri detailMateri) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(detailMateri.judul),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                detailMateri.paragrafMateri,
                style: const TextStyle(fontSize: 14),
              ),
              if (detailMateri.embedYoutube != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Video YouTube:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    detailMateri.embedYoutube!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail Materi'),
            Text(
              widget.materi.judul,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDetailMateriDialog(),
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
                hintText: 'Cari detail materi...',
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
                : _filteredDetailMateri.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'Belum ada detail materi' : 'Tidak ada detail materi yang ditemukan',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'Tap tombol + untuk menambah detail materi baru'
                                  : 'Coba kata kunci lain',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDetailMateri,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDetailMateri.length,
                          itemBuilder: (context, index) {
                            final detailMateri = _filteredDetailMateri[index];
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
                                    color: detailMateri.embedYoutube != null 
                                        ? Colors.red[100] 
                                        : Colors.green[100],
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    detailMateri.embedYoutube != null 
                                        ? Icons.play_circle_filled 
                                        : Icons.article,
                                    color: detailMateri.embedYoutube != null 
                                        ? Colors.red[600] 
                                        : Colors.green[600],
                                  ),
                                ),
                                title: Text(
                                  detailMateri.judul,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      detailMateri.paragrafMateri,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (detailMateri.embedYoutube != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.video_library,
                                            size: 16,
                                            color: Colors.red[600],
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Dengan video YouTube',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (detailMateri.sortOrder != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Urutan: ${detailMateri.sortOrder}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'preview':
                                        _showDetailMateriPreview(detailMateri);
                                        break;
                                      case 'edit':
                                        _showDetailMateriDialog(detailMateri: detailMateri);
                                        break;
                                      case 'delete':
                                        _deleteDetailMateri(detailMateri);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'preview',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility, size: 20),
                                          SizedBox(width: 8),
                                          Text('Preview'),
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
                                onTap: () => _showDetailMateriPreview(detailMateri),
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