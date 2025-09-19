import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/album.dart';
import '../../models/photo.dart';
import '../../providers/gallery_provider.dart';
import '../../utils/app_colors.dart';
import 'photo_detail_screen.dart';
import 'upload_photo_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GalleryProvider>(context, listen: false)
          .fetchPhotosInAlbum(widget.album.id);
    });
  }

  Future<void> _refreshPhotos() async {
    await Provider.of<GalleryProvider>(context, listen: false)
        .fetchPhotosInAlbum(widget.album.id);
  }

  void _navigateToUploadPhoto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UploadPhotoScreen(album: widget.album),
      ),
    );
  }

  void _navigateToPhotoDetail(Photo photo, List<Photo> photos) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoDetailScreen(
          photo: photo,
          photos: photos,
          album: widget.album,
        ),
      ),
    );
  }

  void _showDeleteAlbumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Album'),
        content: Text(
          'Apakah Anda yakin ingin menghapus album "${widget.album.title}"? '
          'Semua foto dalam album ini akan ikut terhapus.',
        ),
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
              ).deleteAlbum(widget.album.id);
              
              if (success && mounted) {
                if (mounted) {
                  navigator.pop();
                }
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Album berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
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
      body: Consumer<GalleryProvider>(
        builder: (context, galleryProvider, child) {
          final photos = galleryProvider.photosByAlbum[widget.album.id] ?? [];
          final isLoading = galleryProvider.isLoadingPhotos;
          final error = galleryProvider.photosError;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  if (widget.album.canEdit)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        switch (value) {
                          case 'delete':
                            _showDeleteAlbumDialog();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus Album'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.album.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: photos.isNotEmpty
                        ? Image.network(
                            photos.first.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                child: const Icon(
                                  Icons.photo_album,
                                  size: 64,
                                  color: Colors.white54,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.photo_album,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.album.description != null) ...[
                        Text(
                          widget.album.description!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.photo,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${photos.length} foto',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            widget.album.isPublic ? Icons.public : Icons.lock,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.album.isPublic ? 'Publik' : 'Privat',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (widget.album.tags != null && widget.album.tags!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.album.tags!.map((tag) {
                            return Chip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshPhotos,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (photos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada foto dalam album ini',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (widget.album.canEdit) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _navigateToUploadPhoto,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Upload Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final photo = photos[index];
                        return GestureDetector(
                          onTap: () => _navigateToPhotoDetail(photo, photos),
                          child: Hero(
                            tag: 'photo_${photo.id}',
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      photo.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                    if (photo.likes != null && photo.likes!.isNotEmpty)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.favorite,
                                                color: Colors.red,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${photo.likes!.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: photos.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: widget.album.canEdit
          ? FloatingActionButton(
              onPressed: _navigateToUploadPhoto,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_photo_alternate, color: Colors.white),
            )
          : null,
    );
  }
}