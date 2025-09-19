import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/album.dart';
import '../models/photo.dart';
import '../services/gallery_service.dart';

class GalleryProvider with ChangeNotifier {
  final GalleryService _galleryService = GalleryService();

  // Albums state
  List<Album> _albums = [];
  Album? _selectedAlbum;
  bool _isLoadingAlbums = false;
  String? _albumsError;

  // Photos state
  List<Photo> _photos = [];
  Map<int, List<Photo>> _photosByAlbum = {};
  Photo? _selectedPhoto;
  bool _isLoadingPhotos = false;
  String? _photosError;

  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;

  // Getters
  List<Album> get albums => _albums;
  Album? get selectedAlbum => _selectedAlbum;
  bool get isLoadingAlbums => _isLoadingAlbums;
  String? get albumsError => _albumsError;

  List<Photo> get photos => _photos;
  Map<int, List<Photo>> get photosByAlbum => _photosByAlbum;
  Photo? get selectedPhoto => _selectedPhoto;
  bool get isLoadingPhotos => _isLoadingPhotos;
  String? get photosError => _photosError;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get uploadError => _uploadError;

  GalleryService get galleryService => _galleryService;

  // Album methods
  Future<void> fetchAlbums({int? classId, bool? isPublic}) async {
    _isLoadingAlbums = true;
    _albumsError = null;
    notifyListeners();

    try {
      _albums = await _galleryService.getAlbums(
        classId: classId,
        isPublic: isPublic,
      );
      _albumsError = null;
    } catch (e) {
      _albumsError = e.toString();
      _albums = [];
    } finally {
      _isLoadingAlbums = false;
      notifyListeners();
    }
  }

  Future<void> fetchAlbumById(int albumId) async {
    _isLoadingAlbums = true;
    _albumsError = null;
    notifyListeners();

    try {
      _selectedAlbum = await _galleryService.getAlbumById(albumId.toString());
      _albumsError = null;
    } catch (e) {
      _albumsError = e.toString();
      _selectedAlbum = null;
    } finally {
      _isLoadingAlbums = false;
      notifyListeners();
    }
  }

  Future<bool> createAlbum({
    required String title,
    String? description,
    int? classId,
    bool isPublic = true,
    bool allowDownload = true,
    List<String>? tags,
  }) async {
    try {
      final newAlbum = await _galleryService.createAlbum(
        title: title,
        description: description ?? '',
        tags: tags ?? [],
        isPublic: isPublic,
        allowDownload: allowDownload,
        classId: classId,
      );
      
      _albums.insert(0, newAlbum);
      notifyListeners();
      return true;
    } catch (e) {
      _albumsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAlbum({
    required int albumId,
    String? title,
    String? description,
    int? classId,
    bool? isPublic,
    bool? allowDownload,
    List<String>? tags,
  }) async {
    try {
      final updatedAlbum = await _galleryService.updateAlbum(
        albumId: albumId.toString(),
        title: title ?? '',
        description: description ?? '',
        tags: tags ?? [],
        isPublic: isPublic ?? true,
        allowDownload: allowDownload ?? true,
      );

      final index = _albums.indexWhere((album) => album.id == albumId);
      if (index != -1) {
        _albums[index] = updatedAlbum;
      }

      if (_selectedAlbum?.id == albumId) {
        _selectedAlbum = updatedAlbum;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _albumsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAlbum(int albumId) async {
    try {
      await _galleryService.deleteAlbum(albumId.toString());
      _albums.removeWhere((album) => album.id == albumId);
      if (_selectedAlbum?.id == albumId) {
        _selectedAlbum = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _albumsError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void selectAlbum(Album album) {
    _selectedAlbum = album;
    notifyListeners();
  }

  void clearSelectedAlbum() {
    _selectedAlbum = null;
    notifyListeners();
  }

  // Photo methods
  Future<void> fetchPhotosInAlbum(int albumId) async {
    _isLoadingPhotos = true;
    _photosError = null;
    notifyListeners();

    try {
      _photos = await _galleryService.getPhotosInAlbum(albumId);
      _photosByAlbum[albumId] = _photos;
      _photosError = null;
    } catch (e) {
      _photosError = e.toString();
      _photos = [];
      _photosByAlbum[albumId] = [];
    } finally {
      _isLoadingPhotos = false;
      notifyListeners();
    }
  }

  Future<Photo?> getPhotoById(int photoId) async {
    _isLoadingPhotos = true;
    _photosError = null;
    notifyListeners();

    try {
      final photo = await _galleryService.getPhotoById(photoId.toString());
      _photosError = null;
      return photo;
    } catch (e) {
      _photosError = e.toString();
      return null;
    } finally {
      _isLoadingPhotos = false;
      notifyListeners();
    }
  }

  Future<Album?> getAlbumById(int albumId) async {
    _isLoadingAlbums = true;
    _albumsError = null;
    notifyListeners();

    try {
      final album = await _galleryService.getAlbumById(albumId.toString());
      _albumsError = null;
      return album;
    } catch (e) {
      _albumsError = e.toString();
      return null;
    } finally {
      _isLoadingAlbums = false;
      notifyListeners();
    }
  }

  List<Photo> get photosInAlbum => _photos;

  Future<void> fetchPhotoById(int albumId, int photoId) async {
    _isLoadingPhotos = true;
    _photosError = null;
    notifyListeners();

    try {
      _selectedPhoto = await _galleryService.getPhotoByIdInAlbum(albumId, photoId);
      _photosError = null;
    } catch (e) {
      _photosError = e.toString();
      _selectedPhoto = null;
    } finally {
      _isLoadingPhotos = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPhotos({
    required int albumId,
    required List<File> photos,
    List<String>? captions,
    List<String>? tags,
  }) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    _uploadError = null;
    notifyListeners();

    try {
      final uploadedPhotos = await _galleryService.uploadPhotos(
        albumId: albumId,
        photos: photos,
        captions: captions,
        tags: tags,
      );

      _photos.addAll(uploadedPhotos);
      
      // Update album photo count
      final albumIndex = _albums.indexWhere((album) => album.id == albumId);
      if (albumIndex != -1) {
        _albums[albumIndex] = _albums[albumIndex].copyWith(
          photoCount: _albums[albumIndex].photoCount + uploadedPhotos.length,
        );
      }

      if (_selectedAlbum?.id == albumId) {
        _selectedAlbum = _selectedAlbum!.copyWith(
          photoCount: _selectedAlbum!.photoCount + uploadedPhotos.length,
        );
      }

      _uploadProgress = 1.0;
      _uploadError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _uploadError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePhoto(int albumId, int photoId) async {
    try {
      final success = await _galleryService.deletePhotoFromAlbum(albumId, photoId);
      if (success) {
        _photos.removeWhere((photo) => photo.id == photoId);
        
        // Update album photo count
        final albumIndex = _albums.indexWhere((album) => album.id == albumId);
        if (albumIndex != -1) {
          _albums[albumIndex] = _albums[albumIndex].copyWith(
            photoCount: _albums[albumIndex].photoCount - 1,
          );
        }

        if (_selectedAlbum?.id == albumId) {
          _selectedAlbum = _selectedAlbum!.copyWith(
            photoCount: _selectedAlbum!.photoCount - 1,
          );
        }

        if (_selectedPhoto?.id == photoId) {
          _selectedPhoto = null;
        }

        notifyListeners();
      }
      return success;
    } catch (e) {
      _photosError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> likePhoto(int albumId, int photoId) async {
    try {
      final success = await _galleryService.likePhotoInAlbum(albumId, photoId);
      if (success) {
        // Update photo likes in local state
        final photoIndex = _photos.indexWhere((photo) => photo.id == photoId);
        if (photoIndex != -1) {
          // This is a simplified implementation - in reality you'd need to track user likes
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _photosError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePhotoCaption(int albumId, int photoId, String caption) async {
    try {
      final updatedPhoto = await _galleryService.updatePhotoCaption(
        albumId,
        photoId,
        caption,
      );

      final photoIndex = _photos.indexWhere((photo) => photo.id == photoId);
      if (photoIndex != -1) {
        _photos[photoIndex] = updatedPhoto;
      }

      if (_selectedPhoto?.id == photoId) {
        _selectedPhoto = updatedPhoto;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _photosError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void selectPhoto(Photo photo) {
    _selectedPhoto = photo;
    notifyListeners();
  }

  void clearSelectedPhoto() {
    _selectedPhoto = null;
    notifyListeners();
  }

  // Utility methods
  void clearErrors() {
    _albumsError = null;
    _photosError = null;
    _uploadError = null;
    notifyListeners();
  }

  void clearAll() {
    _albums = [];
    _selectedAlbum = null;
    _photos = [];
    _selectedPhoto = null;
    _isLoadingAlbums = false;
    _isLoadingPhotos = false;
    _isUploading = false;
    _uploadProgress = 0.0;
    clearErrors();
    notifyListeners();
  }
}