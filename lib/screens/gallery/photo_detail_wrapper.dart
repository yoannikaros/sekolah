import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/photo.dart';
import '../../models/album.dart';
import '../../providers/gallery_provider.dart';
import 'photo_detail_screen.dart';

class PhotoDetailWrapper extends StatefulWidget {
  final int photoId;

  const PhotoDetailWrapper({
    super.key,
    required this.photoId,
  });

  @override
  State<PhotoDetailWrapper> createState() => _PhotoDetailWrapperState();
}

class _PhotoDetailWrapperState extends State<PhotoDetailWrapper> {
  Photo? photo;
  Album? album;
  List<Photo> albumPhotos = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchPhotoData();
  }

  Future<void> _fetchPhotoData() async {
    try {
      final galleryProvider = Provider.of<GalleryProvider>(context, listen: false);
      
      // Fetch the specific photo
      final fetchedPhoto = await galleryProvider.getPhotoById(widget.photoId);
      
      if (fetchedPhoto != null) {
        // Fetch the album data
        final fetchedAlbum = await galleryProvider.getAlbumById(fetchedPhoto.albumId);
        
        // Fetch all photos in the album for navigation
        await galleryProvider.fetchPhotosInAlbum(fetchedPhoto.albumId);
        final photos = galleryProvider.photosInAlbum;
        
        setState(() {
          photo = fetchedPhoto;
          album = fetchedAlbum;
          albumPhotos = photos;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Photo not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load photo: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (photo == null || album == null) {
      return const Scaffold(
        body: Center(
          child: Text('Photo not found'),
        ),
      );
    }

    return PhotoDetailScreen(
      photo: photo!,
      photos: albumPhotos,
      album: album!,
    );
  }
}