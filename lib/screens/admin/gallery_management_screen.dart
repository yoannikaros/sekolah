import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/gallery_models.dart';
import '../../services/gallery_service.dart';

class GalleryManagementScreen extends StatefulWidget {
  const GalleryManagementScreen({super.key});

  @override
  State<GalleryManagementScreen> createState() => _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends State<GalleryManagementScreen>
    with SingleTickerProviderStateMixin {
  final GalleryService _galleryService = GalleryService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<GalleryAlbum> _albums = [];
  List<GalleryPhoto> _photos = [];
  bool _isLoading = true;
  late TabController _tabController;
  String? _selectedAlbumId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final albums = await _galleryService.getGalleryAlbums();
      final photos = await _galleryService.getGalleryPhotos();
      
      if (kDebugMode) {
        print('Loaded ${albums.length} albums');
        print('Loaded ${photos.length} photos');
      }
      
      setState(() {
        _albums = albums;
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading gallery data: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _showAlbumDialog({GalleryAlbum? album}) async {
    final nameController = TextEditingController(text: album?.name ?? '');
    final descriptionController = TextEditingController(text: album?.description ?? '');
    final classCodeController = TextEditingController(text: album?.classCode ?? '');
    final schoolIdController = TextEditingController(text: album?.schoolId ?? 'default_school');
    final tagsController = TextEditingController(text: album?.tags.join(', ') ?? '');
    final coverImageController = TextEditingController(text: album?.coverImageUrl ?? '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(album == null ? 'Tambah Album' : 'Edit Album'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Album',
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
                  TextField(
                    controller: classCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Kode Kelas',
                      border: OutlineInputBorder(),
                      hintText: 'Contoh: 12A, 11B, 10C',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: schoolIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID Sekolah',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: coverImageController,
                    decoration: const InputDecoration(
                      labelText: 'URL Gambar Cover',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/image.jpg',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (pisahkan dengan koma)',
                      border: OutlineInputBorder(),
                      hintText: 'kegiatan, olahraga, akademik',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                if (nameController.text.trim().isEmpty ||
                    classCodeController.text.trim().isEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Nama album dan kode kelas harus diisi')),
                  );
                  return;
                }

                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                final newAlbum = GalleryAlbum(
                  id: album?.id ?? '',
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  schoolId: schoolIdController.text.trim(),
                  classCode: classCodeController.text.trim(),
                  coverImageUrl: coverImageController.text.trim().isEmpty 
                      ? 'https://via.placeholder.com/300x200?text=Album+Cover'
                      : coverImageController.text.trim(),
                  createdBy: 'admin',
                  creatorName: 'Administrator',
                  createdAt: album?.createdAt ?? DateTime.now(),
                  photoCount: album?.photoCount ?? 0,
                  tags: tags,
                );

                bool success;
                if (album == null) {
                  final albumId = await _galleryService.createGalleryAlbum(newAlbum);
                  success = albumId != null;
                } else {
                  success = await _galleryService.updateGalleryAlbum(album.id, newAlbum);
                }

                if (success) {
                  navigator.pop();
                  _loadData();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(album == null 
                          ? 'Album berhasil ditambahkan' 
                          : 'Album berhasil diperbarui'),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Gagal menyimpan album')),
                  );
                }
              },
              child: Text(album == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPhotoDialog({GalleryPhoto? photo}) async {
    final titleController = TextEditingController(text: photo?.title ?? '');
    final descriptionController = TextEditingController(text: photo?.description ?? '');
    final tagsController = TextEditingController(text: photo?.tags.join(', ') ?? '');
    
    String? selectedAlbumId = photo?.albumId ?? _selectedAlbumId;
    File? selectedImage;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(photo == null ? 'Tambah Foto' : 'Edit Foto'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (photo == null) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            final XFile? image = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1080,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              setDialogState(() {
                                selectedImage = File(image.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pilih Foto'),
                        ),
                        if (selectedImage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                      DropdownButtonFormField<String>(
                        value: selectedAlbumId,
                        decoration: const InputDecoration(
                          labelText: 'Album',
                          border: OutlineInputBorder(),
                        ),
                        items: _albums.map((album) {
                          return DropdownMenuItem(
                            value: album.id,
                            child: Text('${album.name} (${album.classCode})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedAlbumId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pilih album';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Foto',
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
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (pisahkan dengan koma)',
                          border: OutlineInputBorder(),
                          hintText: 'kegiatan, olahraga, akademik',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    
                    if (titleController.text.trim().isEmpty || selectedAlbumId == null) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Judul foto dan album harus diisi')),
                      );
                      return;
                    }

                    if (photo == null && selectedImage == null) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Pilih foto terlebih dahulu')),
                      );
                      return;
                    }

                    final selectedAlbum = _albums.firstWhere((album) => album.id == selectedAlbumId);
                    final tags = tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();

                    bool success = false;

                    if (photo == null) {
                      // Upload new photo
                      final uploadResult = await _galleryService.uploadPhotoWithWatermark(
                        imageFile: selectedImage!,
                        classCode: selectedAlbum.classCode,
                        schoolId: selectedAlbum.schoolId,
                        albumId: selectedAlbumId!,
                      );

                      if (uploadResult != null) {
                        final newPhoto = GalleryPhoto(
                          id: '',
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          originalImageUrl: uploadResult['originalUrl']!,
                          watermarkedImageUrl: uploadResult['watermarkedUrl']!,
                          thumbnailUrl: uploadResult['thumbnailUrl']!,
                          schoolId: selectedAlbum.schoolId,
                          classCode: selectedAlbum.classCode,
                          albumId: selectedAlbumId!,
                          uploadedBy: 'admin',
                          uploaderName: 'Administrator',
                          createdAt: DateTime.now(),
                          tags: tags,
                        );

                        final photoId = await _galleryService.createGalleryPhoto(newPhoto);
                        success = photoId != null;
                      }
                    } else {
                      // Update existing photo
                      final updatedPhoto = photo.copyWith(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        albumId: selectedAlbumId!,
                        tags: tags,
                        updatedAt: DateTime.now(),
                      );

                      success = await _galleryService.updateGalleryPhoto(photo.id, updatedPhoto);
                    }

                    if (success) {
                      navigator.pop();
                      _loadData();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(photo == null 
                              ? 'Foto berhasil ditambahkan' 
                              : 'Foto berhasil diperbarui'),
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Gagal menyimpan foto')),
                      );
                    }
                  },
                  child: Text(photo == null ? 'Tambah' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAlbum(GalleryAlbum album) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Album'),
        content: Text('Apakah Anda yakin ingin menghapus album "${album.name}"? '
            'Semua foto dalam album ini juga akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _galleryService.deleteGalleryAlbum(album.id);
      if (success) {
        _loadData();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Album berhasil dihapus')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Gagal menghapus album')),
        );
      }
    }
  }

  Future<void> _deletePhoto(GalleryPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: Text('Apakah Anda yakin ingin menghapus foto "${photo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _galleryService.deleteGalleryPhoto(photo.id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto berhasil dihapus')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus foto')),
          );
        }
      }
    }
  }

  Widget _buildAlbumsTab() {
    final filteredAlbums = _albums.where((album) {
      return album.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             album.classCode.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari album...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showAlbumDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Album'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredAlbums.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada album',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredAlbums.length,
                      itemBuilder: (context, index) {
                        final album = filteredAlbums[index];
                        return Card(
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(album.coverImageUrl),
                                      fit: BoxFit.cover,
                                      onError: (error, stackTrace) {},
                                    ),
                                  ),
                                  child: album.coverImageUrl.contains('placeholder')
                                      ? const Icon(
                                          Icons.photo_album,
                                          size: 48,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        album.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Kelas: ${album.classCode}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${album.photoCount} foto',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            onPressed: () => _showAlbumDialog(album: album),
                                            icon: const Icon(Icons.edit, size: 16),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            onPressed: () => _deleteAlbum(album),
                                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab() {
    final filteredPhotos = _photos.where((photo) {
      final matchesSearch = photo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           photo.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesAlbum = _selectedAlbumId == null || photo.albumId == _selectedAlbumId;
      return matchesSearch && matchesAlbum;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari foto...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _albums.isNotEmpty ? () => _showPhotoDialog() : null,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Tambah Foto'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedAlbumId,
                decoration: const InputDecoration(
                  labelText: 'Filter berdasarkan Album',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Album'),
                  ),
                  ..._albums.map((album) {
                    return DropdownMenuItem(
                      value: album.id,
                      child: Text('${album.name} (${album.classCode})'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAlbumId = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredPhotos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _albums.isEmpty 
                                ? 'Buat album terlebih dahulu'
                                : 'Belum ada foto',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredPhotos.length,
                      itemBuilder: (context, index) {
                        final photo = filteredPhotos[index];
                        final album = _albums.firstWhere(
                          (a) => a.id == photo.albumId,
                          orElse: () => GalleryAlbum(
                            id: '',
                            name: 'Unknown',
                            description: '',
                            schoolId: '',
                            classCode: '',
                            coverImageUrl: '',
                            createdBy: '',
                            creatorName: '',
                            createdAt: DateTime.now(),
                          ),
                        );

                        return Card(
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(photo.thumbnailUrl),
                                      fit: BoxFit.cover,
                                      onError: (error, stackTrace) {},
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (photo.watermarkedImageUrl != photo.originalImageUrl)
                                        const Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        photo.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        album.name,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Kelas: ${photo.classCode}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            onPressed: () => _showPhotoDialog(photo: photo),
                                            icon: const Icon(Icons.edit, size: 14),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            onPressed: () => _deletePhoto(photo),
                                            icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Galeri Foto'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Album', icon: Icon(Icons.photo_album)),
            Tab(text: 'Foto', icon: Icon(Icons.photo_library)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlbumsTab(),
          _buildPhotosTab(),
        ],
      ),
    );
  }
}