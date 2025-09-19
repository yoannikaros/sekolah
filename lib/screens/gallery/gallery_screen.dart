import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gallery_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/album.dart';
import '../../utils/app_colors.dart';
import '../../widgets/gallery/album_card.dart';
import 'create_album_screen.dart';
import 'album_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlbums();
    });
  }

  void _loadAlbums() {
    final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
    galleryProvider.fetchAlbums();
  }

  void _showCreateAlbumDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateAlbumScreen(),
      ),
    ).then((_) => _loadAlbums());
  }

  void _onAlbumTap(Album album) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlbumDetailScreen(album: album),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Galeri Foto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              if (user != null && 
                  (user.role == 'teacher' || 
                   user.role == 'school_admin' || 
                   user.role == 'owner')) {
                return IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showCreateAlbumDialog,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, galleryProvider, child) {
          if (galleryProvider.isLoadingAlbums) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (galleryProvider.albumsError != null) {
            return Center(
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
                    'Terjadi kesalahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    galleryProvider.albumsError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAlbums,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (galleryProvider.albums.isEmpty) {
            return Center(
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
                    'Belum ada album',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Album foto akan muncul di sini',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.user;
                      if (user != null && 
                          (user.role == 'teacher' || 
                           user.role == 'school_admin' || 
                           user.role == 'owner')) {
                        return ElevatedButton.icon(
                          onPressed: _showCreateAlbumDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Album'),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadAlbums(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: galleryProvider.albums.length,
                itemBuilder: (context, index) {
                  final album = galleryProvider.albums[index];
                  return AlbumCard(
                    album: album,
                    onTap: () => _onAlbumTap(album),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}