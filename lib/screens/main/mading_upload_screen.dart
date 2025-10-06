import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/mading_models.dart';
import '../../services/mading_service.dart';

class MadingUploadScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole;
  final String schoolId;
  final List<Subject> subjects;

  const MadingUploadScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
    required this.schoolId,
    required this.subjects,
  });

  @override
  State<MadingUploadScreen> createState() => _MadingUploadScreenState();
}

class _MadingUploadScreenState extends State<MadingUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _studentClassController = TextEditingController();
  final MadingService _madingService = MadingService();

  File? _selectedImage;
  String? _selectedSubjectId;
  bool _isUploading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _studentNameController.dispose();
    _studentClassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Upload Karya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadPost,
            child: Text(
              'Posting',
              style: TextStyle(
                color: _isUploading ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isUploading
          ? _buildUploadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    _buildStudentInfoSection(),
                    const SizedBox(height: 24),
                    _buildSubjectSection(),
                    const SizedBox(height: 24),
                    _buildDescriptionSection(),
                    const SizedBox(height: 32),
                    _buildUploadButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadingWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mengupload karya...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.photo_camera, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                const Text(
                  'Pilih Gambar Karya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedImage != null)
            Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap untuk memilih gambar',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[50],
                      foregroundColor: Colors.indigo[700],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[50],
                      foregroundColor: Colors.indigo[700],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.indigo[600]),
              const SizedBox(width: 8),
              const Text(
                'Informasi Siswa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _studentNameController,
            decoration: InputDecoration(
              labelText: 'Nama Siswa',
              hintText: 'Masukkan nama siswa',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama siswa harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _studentClassController,
            decoration: InputDecoration(
              labelText: 'Kelas',
              hintText: 'Contoh: XII IPA 1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.class_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kelas harus diisi';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book, color: Colors.indigo[600]),
              const SizedBox(width: 8),
              const Text(
                'Mata Pelajaran (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSubjectId,
            decoration: InputDecoration(
              labelText: 'Pilih Mata Pelajaran',
              hintText: 'Pilih mata pelajaran terkait',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.subject),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tidak ada mata pelajaran'),
              ),
              ...widget.subjects.map((subject) => DropdownMenuItem<String>(
                value: subject.id,
                child: Text(subject.name),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSubjectId = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.indigo[600]),
              const SizedBox(width: 8),
              const Text(
                'Deskripsi Karya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Deskripsi',
              hintText: 'Ceritakan tentang karya Anda...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Deskripsi karya harus diisi';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedImage != null && !_isUploading ? _uploadPost : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(Icons.publish),
            const SizedBox(width: 8),
            Text(
              _isUploading ? 'Mengupload...' : 'Upload Karya',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final File? image = await _madingService.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPost() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _madingService.createMadingPost(
        imageFile: _selectedImage!,
        schoolId: widget.schoolId,
        subjectId: _selectedSubjectId,
        studentId: widget.currentUserId,
        studentName: _studentNameController.text.trim(),
        studentClass: _studentClassController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Karya berhasil diupload! Menunggu persetujuan guru.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload karya: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}