import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/album.dart';
import '../../models/photo.dart';
import '../../providers/gallery_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class PhotoDetailScreen extends StatefulWidget {
  final Photo photo;
  final List<Photo> photos;
  final Album album;

  const PhotoDetailScreen({
    super.key,
    required this.photo,
    required this.photos,
    required this.album,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.photos.indexWhere((p) => p.id == widget.photo.id);
    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  bool _isPhotoLiked(Photo photo) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null || photo.likes == null) return false;
    return photo.likes!.contains(currentUser.id);
  }

  bool _canEditPhoto(Photo photo) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return false;
    return photo.uploadedBy == currentUser.id;
  }

  Future<void> _toggleLike(Photo photo) async {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    await galleryProvider.likePhoto(photo.albumId, photo.id);
  }

  void _sharePhoto(Photo photo) {
    Share.share(
      photo.fullImageUrl,
      subject: photo.originalName.isNotEmpty ? photo.originalName : 'Foto dari ${widget.album.title}',
    );
  }

  void _showDeleteDialog(Photo photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text('Apakah Anda yakin ingin menghapus foto ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop();
              
              final success = await Provider.of<GalleryProvider>(
                context,
                listen: false,
              ).deletePhoto(photo.albumId, photo.id);
              
              if (success && mounted) {
                // Remove photo from list and update current index
                final updatedPhotos = List<Photo>.from(widget.photos);
                updatedPhotos.removeWhere((p) => p.id == photo.id);
                
                if (updatedPhotos.isEmpty) {
                  navigator.pop();
                } else {
                  if (_currentIndex >= updatedPhotos.length) {
                    _currentIndex = updatedPhotos.length - 1;
                  }
                  _pageController.animateToPage(
                    _currentIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
                
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Foto berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                '${_currentIndex + 1} dari ${widget.photos.length}',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                Consumer<GalleryProvider>(
                  builder: (context, galleryProvider, child) {
                    final currentPhoto = widget.photos[_currentIndex];
                    return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: Colors.white,
                      onSelected: (value) {
                        switch (value) {
                          case 'share':
                            _sharePhoto(currentPhoto);
                            break;
                          case 'delete':
                            if (_canEditPhoto(currentPhoto)) {
                              _showDeleteDialog(currentPhoto);
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Bagikan'),
                            ],
                          ),
                        ),
                        if (_canEditPhoto(widget.photos[_currentIndex]))
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Hapus'),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            )
          : null,
      body: Consumer<GalleryProvider>(
        builder: (context, galleryProvider, child) {
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.photos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  return GestureDetector(
                    onTap: _toggleAppBar,
                    child: Hero(
                      tag: 'photo_${photo.id}',
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: Center(
                          child: Image.network(
                            Provider.of<GalleryProvider>(context, listen: false).galleryService.getImageUrl(photo.path),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Gagal memuat foto',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_showAppBar)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.photos[_currentIndex].originalName.isNotEmpty) ...[
                          Text(
                            widget.photos[_currentIndex].originalName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (widget.photos[_currentIndex].caption != null) ...[
                          Text(
                            widget.photos[_currentIndex].caption!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleLike(widget.photos[_currentIndex]),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isPhotoLiked(widget.photos[_currentIndex])
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _isPhotoLiked(widget.photos[_currentIndex])
                                          ? Colors.red
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.photos[_currentIndex].likes?.length ?? 0}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.visibility,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.photos[_currentIndex].views}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (widget.album.allowDownload)
                              IconButton(
                                onPressed: () => _sharePhoto(widget.photos[_currentIndex]),
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        if (widget.photos[_currentIndex].tags != null &&
                            widget.photos[_currentIndex].tags!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: widget.photos[_currentIndex].tags!.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}