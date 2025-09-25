import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/material_models.dart' as material_models;
import '../../models/admin_models.dart';
import '../../models/quiz_models.dart';
import '../../services/material_service.dart';
import '../../services/admin_service.dart';

class MaterialFormScreen extends StatefulWidget {
  final material_models.Material? material;

  const MaterialFormScreen({super.key, this.material});

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();
  final AdminService _adminService = AdminService();

  // Controllers
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _tagsController = TextEditingController();

  // Data
  List<Subject> _subjects = [];
  List<ClassCode> _classCodes = [];
  List<Teacher> _teachers = [];
  // Selected values
  String? _selectedSubjectId;
  String? _selectedClassCodeId;
  String? _selectedTeacherId;
  bool _isPublished = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.material != null) {
      final material = widget.material!;
      _titleController.text = material.title;
      _contentController.text = material.content;
      _youtubeUrlController.text = material.youtubeEmbedUrl ?? '';
      _tagsController.text = material.tags.join(', ');
      _selectedSubjectId = material.subjectId;
      _selectedClassCodeId = material.classCodeId;
      _selectedTeacherId = material.teacherId;
      _isPublished = material.isPublished;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _adminService.getAllSubjects();
      final classCodes = await _adminService.getAllClassCodes();
      final teachers = await _adminService.getAllTeachers();

      if (mounted) {
        setState(() {
          _subjects = subjects;
          _classCodes = classCodes;
          _teachers = teachers;
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

  List<String> _parseTagsFromString(String tagsString) {
    return tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  String _extractYouTubeVideoId(String url) {
    // Extract video ID from various YouTube URL formats
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }

  String _convertToEmbedUrl(String url) {
    if (url.isEmpty) return '';
    
    final videoId = _extractYouTubeVideoId(url);
    if (videoId.isNotEmpty) {
      return 'https://www.youtube.com/embed/$videoId';
    }
    
    // If already an embed URL, return as is
    if (url.contains('youtube.com/embed/')) {
      return url;
    }
    
    return url;
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubjectId == null || _selectedClassCodeId == null || _selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua field yang diperlukan')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final tags = _parseTagsFromString(_tagsController.text);
      final youtubeEmbedUrl = _convertToEmbedUrl(_youtubeUrlController.text.trim());

      final material = material_models.Material(
        id: widget.material?.id ?? '',
        subjectId: _selectedSubjectId!,
        classCodeId: _selectedClassCodeId!,
        teacherId: _selectedTeacherId!,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        youtubeEmbedUrl: youtubeEmbedUrl.isEmpty ? null : youtubeEmbedUrl,
        comments: widget.material?.comments ?? [],
        createdBy: widget.material?.createdBy ?? 'admin', // TODO: Get from auth
        createdAt: widget.material?.createdAt ?? now,
        updatedAt: now,
        isActive: true,
        isPublished: _isPublished,
        publishedAt: _isPublished ? now : null,
        tags: tags,
      );

      bool success;
      if (widget.material == null) {
        // Create new material
        final materialId = await _materialService.createMaterial(material);
        success = materialId != null;
      } else {
        // Update existing material
        success = await _materialService.updateMaterial(widget.material!.id, material);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.material == null 
                  ? 'Materi berhasil ditambahkan' 
                  : 'Materi berhasil diperbarui'),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan materi')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving material: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.material == null ? 'Tambah Materi' : 'Edit Materi'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveMaterial,
              child: const Text(
                'SIMPAN',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject Selection
                    DropdownButtonFormField<String>(
                      value: _selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Mata Pelajaran *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subject),
                      ),
                      items: _subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject.id,
                          child: Text(subject.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubjectId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pilih mata pelajaran';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Class Code Selection
                    DropdownButtonFormField<String>(
                      value: _selectedClassCodeId,
                      decoration: const InputDecoration(
                        labelText: 'Kode Kelas *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: _classCodes.map((classCode) {
                        return DropdownMenuItem<String>(
                          value: classCode.id,
                          child: Text('${classCode.name} (${classCode.code})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassCodeId = value;
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

                    // Teacher Selection
                    DropdownButtonFormField<String>(
                      value: _selectedTeacherId,
                      decoration: const InputDecoration(
                        labelText: 'Guru *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: _teachers.map((teacher) {
                        return DropdownMenuItem<String>(
                          value: teacher.id,
                          child: Text(teacher.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTeacherId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pilih guru';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Materi *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul materi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Content
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Isi Materi *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Isi materi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // YouTube URL
                    TextFormField(
                      controller: _youtubeUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL YouTube (Opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.video_library),
                        hintText: 'https://www.youtube.com/watch?v=...',
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final videoId = _extractYouTubeVideoId(value);
                          if (videoId.isEmpty) {
                            return 'URL YouTube tidak valid';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tag (Opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'matematika, aljabar, dasar (pisahkan dengan koma)',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Publish Status
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status Publikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: const Text('Publikasikan Materi'),
                              subtitle: Text(_isPublished 
                                  ? 'Materi akan terlihat oleh siswa' 
                                  : 'Materi masih dalam draft'),
                              value: _isPublished,
                              onChanged: (value) {
                                setState(() {
                                  _isPublished = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveMaterial,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Menyimpan...'),
                                ],
                              )
                            : Text(
                                widget.material == null ? 'TAMBAH MATERI' : 'PERBARUI MATERI',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _youtubeUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}