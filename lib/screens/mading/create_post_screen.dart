import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mading/media_preview.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  PostType _selectedType = PostType.artwork;
  List<File> _selectedFiles = [];
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih gambar: $e');
    }
  }
  
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx'],
      );
      
      if (result != null) {
        setState(() {
          _selectedFiles.addAll(
            result.paths.where((path) => path != null).map((path) => File(path!))
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal memilih file: $e');
    }
  }
  
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showErrorSnackBar('Anda harus login terlebih dahulu');
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final postProvider = context.read<PostProvider>();
      
      await postProvider.createPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        filePaths: _selectedFiles.map((file) => file.path).toList(),
      );
      
      if (postProvider.error == null) {
        _showSuccessSnackBar('Postingan berhasil dibuat dan menunggu persetujuan');
        Navigator.pop(context);
      } else {
        _showErrorSnackBar(postProvider.error!);
      }
    } catch (e) {
      _showErrorSnackBar('Gagal membuat postingan: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Buat Postingan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: Text(
              'Kirim',
              style: TextStyle(
                color: _isSubmitting ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jenis Postingan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: PostType.values.map((type) {
                          return ChoiceChip(
                            label: Text(type.displayName),
                            selected: _selectedType == type,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedType = type;
                                });
                              }
                            },
                            selectedColor: Colors.blue[100],
                            labelStyle: TextStyle(
                              color: _selectedType == type 
                                  ? Colors.blue[800] 
                                  : Colors.grey[700],
                              fontWeight: _selectedType == type 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Postingan',
                      hintText: 'Masukkan judul yang menarik...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.type),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      if (value.trim().length < 5) {
                        return 'Judul minimal 5 karakter';
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Content Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Konten',
                      hintText: 'Tulis konten postingan Anda...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.fileText),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Konten tidak boleh kosong';
                      }
                      if (value.trim().length < 10) {
                        return 'Konten minimal 10 karakter';
                      }
                      return null;
                    },
                    maxLength: 1000,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (Opsional)',
                      hintText: 'Tambahkan deskripsi tambahan...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.alignLeft),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Media Upload Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Media & File',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Upload Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(LucideIcons.image),
                              label: const Text('Pilih Gambar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(LucideIcons.paperclip),
                              label: const Text('Pilih File'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Selected Files Preview
                      if (_selectedFiles.isNotEmpty) ...[
                        Text(
                          'File Terpilih (${_selectedFiles.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedFiles.length,
                            itemBuilder: (context, index) {
                              final file = _selectedFiles[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: MediaPreview(
                                  file: file,
                                  onRemove: () => _removeFile(index),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
                      // Upload Guidelines
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.info,
                                  size: 16,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Panduan Upload',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Gambar: JPG, PNG, GIF (max 5MB)\n'
                              '• Dokumen: PDF, DOC, DOCX, TXT, PPT, PPTX (max 10MB)\n'
                              '• Maksimal 10 file per postingan',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
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
                            Text('Mengirim...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.send),
                            SizedBox(width: 8),
                            Text(
                              'Kirim Postingan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Postingan Anda akan ditinjau oleh guru/admin sebelum dipublikasikan.',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}