import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gallery_provider.dart';
import '../../utils/app_colors.dart';

class CreateAlbumScreen extends StatefulWidget {
  const CreateAlbumScreen({Key? key}) : super(key: key);

  @override
  State<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends State<CreateAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  bool _isPublic = true;
  bool _allowDownload = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _createAlbum() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    
    // Parse tags from comma-separated string
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final success = await galleryProvider.createAlbum(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      isPublic: _isPublic,
      allowDownload: _allowDownload,
      tags: tags.isEmpty ? null : tags,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Album berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(galleryProvider.albumsError ?? 'Gagal membuat album'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buat Album Baru',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Album',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Album *',
                          hintText: 'Masukkan judul album',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul album harus diisi';
                          }
                          if (value.trim().length < 3) {
                            return 'Judul album minimal 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          hintText: 'Masukkan deskripsi album (opsional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'Pisahkan dengan koma (contoh: sekolah, olahraga)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Album',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Album Publik'),
                        subtitle: const Text('Album dapat dilihat oleh semua pengguna'),
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      SwitchListTile(
                        title: const Text('Izinkan Download'),
                        subtitle: const Text('Pengguna dapat mengunduh foto'),
                        value: _allowDownload,
                        onChanged: (value) {
                          setState(() {
                            _allowDownload = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createAlbum,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Buat Album',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}