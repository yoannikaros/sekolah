import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/album.dart';
import '../models/photo.dart';
import 'api_service.dart';

class GalleryService {
  static const String baseUrl = 'http://localhost:3000/api';
  final ApiService _apiService = ApiService();

  // Get headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Album endpoints
  Future<List<Album>> getAlbums({
    int? classId,
    bool? isPublic,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (classId != null) queryParams['class_id'] = classId.toString();
      if (isPublic != null) queryParams['is_public'] = isPublic.toString();

      final uri = Uri.parse('$baseUrl/albums').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> albumsJson = data['albums'];
          return albumsJson.map((json) => Album.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch albums');
        }
      } else {
        throw Exception('Failed to fetch albums: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching albums: $e');
    }
  }

  Future<Album> getAlbumById(String albumId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/albums/$albumId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Album.fromJson(data['album']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch album');
        }
      } else {
        throw Exception('Failed to fetch album: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching album: $e');
    }
  }

  Future<Album> createAlbum({
    required String title,
    required String description,
    required List<String> tags,
    required bool isPublic,
    required bool allowDownload,
    int? classId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/albums'),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'description': description,
          'tags': tags,
          'is_public': isPublic,
          'allow_download': allowDownload,
          'class_id': classId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Album.fromJson(data['album']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create album');
        }
      } else {
        throw Exception('Failed to create album: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating album: $e');
    }
  }

  Future<Album> updateAlbum({
    required String albumId,
    required String title,
    required String description,
    required List<String> tags,
    required bool isPublic,
    required bool allowDownload,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/albums/$albumId'),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'description': description,
          'tags': tags,
          'is_public': isPublic,
          'allow_download': allowDownload,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Album.fromJson(data['album']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update album');
        }
      } else {
        throw Exception('Failed to update album: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating album: $e');
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/albums/$albumId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete album');
        }
      } else {
        throw Exception('Failed to delete album: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting album: $e');
    }
  }

  // Photo endpoints
  Future<List<Photo>> getPhotos({
    String? albumId,
    int? classId,
    bool? isPublic,
  }) async {
    // This endpoint doesn't exist in server.js, redirect to getPhotosInAlbum if albumId provided
    if (albumId != null) {
      return getPhotosInAlbum(int.parse(albumId));
    }
    throw Exception('getPhotos without albumId is not supported by the API');
  }

  Future<List<Photo>> getPhotosInAlbum(int albumId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/albums/$albumId/photos'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Server.js returns { photos: [...] } directly, not { success: true, photos: [...] }
        final List<dynamic> photosJson = data['photos'];
        return photosJson.map((json) => Photo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch photos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching photos: $e');
    }
  }

  Future<Photo> getPhotoById(String photoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/photos/$photoId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Photo.fromJson(data['photo']);
      } else if (response.statusCode == 404) {
        throw Exception('Photo not found');
      } else {
        throw Exception('Failed to fetch photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching photo: $e');
    }
  }

  Future<Photo> getPhotoByIdInAlbum(int albumId, int photoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/albums/$albumId/photos/$photoId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Photo.fromJson(data['photo']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch photo');
        }
      } else {
        throw Exception('Failed to fetch photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching photo: $e');
    }
  }

  Future<Photo> uploadPhoto({
    required String albumId,
    required File imageFile,
    required String title,
    required String description,
    required List<String> tags,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/photos'),
      );

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // Add other fields
      request.fields['album_id'] = albumId;
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['tags'] = json.encode(tags);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Photo.fromJson(data['photo']);
        } else {
          throw Exception(data['message'] ?? 'Failed to upload photo');
        }
      } else {
        throw Exception('Failed to upload photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }

  Future<Photo> updatePhoto({
    required String photoId,
    required String title,
    required String description,
    required List<String> tags,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/photos/$photoId'),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'description': description,
          'tags': tags,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Photo.fromJson(data['photo']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update photo');
        }
      } else {
        throw Exception('Failed to update photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating photo: $e');
    }
  }

  Future<List<Photo>> uploadPhotos({
    required int albumId,
    required List<File> photos,
    List<String>? captions,
    List<String>? tags,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/albums/$albumId/photos');
      final request = http.MultipartRequest('POST', uri);

      // Add authentication header
      final token = await _apiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add photos
      for (int i = 0; i < photos.length; i++) {
        final file = photos[i];
        final multipartFile = await http.MultipartFile.fromPath(
          'photos',
          file.path,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      // Add captions if provided
      if (captions != null && captions.isNotEmpty) {
        request.fields['captions'] = json.encode(captions);
      }

      // Add tags if provided
      if (tags != null && tags.isNotEmpty) {
        request.fields['tags'] = json.encode(tags);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> photosJson = data['photos'];
          return photosJson.map((json) => Photo.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to upload photos');
        }
      } else {
        throw Exception('Failed to upload photos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading photos: $e');
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/photos/$photoId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Server.js returns { message: "Photo deleted successfully" }
        if (data['message'] == null) {
          throw Exception('Failed to delete photo');
        }
      } else {
        throw Exception('Failed to delete photo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting photo: $e');
    }
  }

  Future<bool> deletePhotoFromAlbum(int albumId, int photoId) async {
    // Use the same endpoint as deletePhoto since server.js only has DELETE /api/photos/:id
    try {
      await deletePhoto(photoId.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> likePhoto(String photoId) async {
    // This endpoint doesn't exist in server.js
    throw Exception('likePhoto is not supported by the API');
  }

  Future<void> unlikePhoto(String photoId) async {
    // This endpoint doesn't exist in server.js
    throw Exception('unlikePhoto is not supported by the API');
  }

  Future<bool> likePhotoInAlbum(int albumId, int photoId) async {
    // This endpoint doesn't exist in server.js
    throw Exception('likePhotoInAlbum is not supported by the API');
  }

  Future<Photo> updatePhotoCaption(int albumId, int photoId, String caption) async {
    // This endpoint doesn't exist in server.js
    throw Exception('updatePhotoCaption is not supported by the API');
  }

  // Utility methods
  String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    return '$baseUrl/uploads/$imagePath';
  }

  String getThumbnailUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    return '$baseUrl/uploads/thumbnails/$imagePath';
  }
}