import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/gallery_models.dart';

class GalleryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Gallery Photo CRUD Operations
  Future<String?> createGalleryPhoto(GalleryPhoto photo) async {
    try {
      final photoData = {
        'title': photo.title,
        'description': photo.description,
        'originalImageUrl': photo.originalImageUrl,
        'watermarkedImageUrl': photo.watermarkedImageUrl,
        'thumbnailUrl': photo.thumbnailUrl,
        'schoolId': photo.schoolId,
        'classCode': photo.classCode,
        'albumId': photo.albumId,
        'uploadedBy': photo.uploadedBy,
        'uploaderName': photo.uploaderName,
        'createdAt': photo.createdAt.toIso8601String(),
        'updatedAt': photo.updatedAt?.toIso8601String(),
        'isActive': photo.isActive,
        'metadata': photo.metadata,
        'tags': photo.tags,
      };
      
      final docRef = await _firestore.collection('gallery_photos').add(photoData);
      
      // Update album photo count
      await _updateAlbumPhotoCount(photo.albumId, 1);
      
      if (kDebugMode) {
        print('Gallery photo created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating gallery photo: $e');
      }
      return null;
    }
  }

  Future<bool> updateGalleryPhoto(String id, GalleryPhoto photo) async {
    try {
      final photoData = {
        'title': photo.title,
        'description': photo.description,
        'originalImageUrl': photo.originalImageUrl,
        'watermarkedImageUrl': photo.watermarkedImageUrl,
        'thumbnailUrl': photo.thumbnailUrl,
        'schoolId': photo.schoolId,
        'classCode': photo.classCode,
        'albumId': photo.albumId,
        'uploadedBy': photo.uploadedBy,
        'uploaderName': photo.uploaderName,
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': photo.isActive,
        'metadata': photo.metadata,
        'tags': photo.tags,
      };
      
      await _firestore.collection('gallery_photos').doc(id).update(photoData);
      if (kDebugMode) {
        print('Gallery photo updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating gallery photo: $e');
      }
      return false;
    }
  }

  Future<bool> deleteGalleryPhoto(String id) async {
    try {
      // Get photo data first to update album count
      final photoDoc = await _firestore.collection('gallery_photos').doc(id).get();
      if (photoDoc.exists) {
        final photoData = photoDoc.data()!;
        final albumId = photoData['albumId'] as String;
        
        // Delete the photo document
        await _firestore.collection('gallery_photos').doc(id).delete();
        
        // Update album photo count
        await _updateAlbumPhotoCount(albumId, -1);
        
        // Optionally delete files from storage
        // await _deletePhotoFiles(photoData);
      }
      
      if (kDebugMode) {
        print('Gallery photo deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting gallery photo: $e');
      }
      return false;
    }
  }

  Future<GalleryPhoto?> getGalleryPhoto(String id) async {
    try {
      final doc = await _firestore.collection('gallery_photos').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return _mapToGalleryPhoto(doc.id, data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting gallery photo: $e');
      }
      return null;
    }
  }

  Future<List<GalleryPhoto>> getGalleryPhotos({
    String? schoolId,
    String? classCode,
    String? albumId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('gallery_photos');
      
      // Apply filters one by one to avoid complex index requirements while building
      if (schoolId != null) {
        query = query.where('schoolId', isEqualTo: schoolId);
      }
      if (classCode != null) {
        query = query.where('classCode', isEqualTo: classCode);
      }
      if (albumId != null) {
        query = query.where('albumId', isEqualTo: albumId);
      }
      
      query = query.where('isActive', isEqualTo: true);
      
      // Try with orderBy first, if it fails, fallback to simple query
      try {
        query = query.orderBy('createdAt', descending: true).limit(limit);
        final querySnapshot = await query.get();
        
        return querySnapshot.docs.map((doc) {
          return _mapToGalleryPhoto(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      } catch (indexError) {
        if (kDebugMode) {
          print('Index still building, using fallback query without orderBy: $indexError');
        }
        
        // Fallback: Query without orderBy and sort in memory
        Query fallbackQuery = _firestore.collection('gallery_photos');
        
        if (schoolId != null) {
          fallbackQuery = fallbackQuery.where('schoolId', isEqualTo: schoolId);
        }
        if (classCode != null) {
          fallbackQuery = fallbackQuery.where('classCode', isEqualTo: classCode);
        }
        if (albumId != null) {
          fallbackQuery = fallbackQuery.where('albumId', isEqualTo: albumId);
        }
        
        fallbackQuery = fallbackQuery.where('isActive', isEqualTo: true).limit(limit);
        
        final querySnapshot = await fallbackQuery.get();
        
        List<GalleryPhoto> photos = querySnapshot.docs.map((doc) {
          return _mapToGalleryPhoto(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
        
        // Sort in memory by createdAt descending
        photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return photos.take(limit).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting gallery photos: $e');
      }
      return [];
    }
  }

  // Gallery Album CRUD Operations
  Future<String?> createGalleryAlbum(GalleryAlbum album) async {
    try {
      final albumData = {
        'name': album.name,
        'description': album.description,
        'schoolId': album.schoolId,
        'classCode': album.classCode,
        'coverImageUrl': album.coverImageUrl,
        'createdBy': album.createdBy,
        'creatorName': album.creatorName,
        'createdAt': album.createdAt.toIso8601String(),
        'updatedAt': album.updatedAt?.toIso8601String(),
        'isActive': album.isActive,
        'photoCount': album.photoCount,
        'tags': album.tags,
      };
      
      final docRef = await _firestore.collection('gallery_albums').add(albumData);
      if (kDebugMode) {
        print('Gallery album created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating gallery album: $e');
      }
      return null;
    }
  }

  Future<bool> updateGalleryAlbum(String id, GalleryAlbum album) async {
    try {
      final albumData = {
        'name': album.name,
        'description': album.description,
        'schoolId': album.schoolId,
        'classCode': album.classCode,
        'coverImageUrl': album.coverImageUrl,
        'createdBy': album.createdBy,
        'creatorName': album.creatorName,
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': album.isActive,
        'photoCount': album.photoCount,
        'tags': album.tags,
      };
      
      await _firestore.collection('gallery_albums').doc(id).update(albumData);
      if (kDebugMode) {
        print('Gallery album updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating gallery album: $e');
      }
      return false;
    }
  }

  Future<bool> deleteGalleryAlbum(String id) async {
    try {
      // First, delete all photos in the album
      final photosQuery = await _firestore
          .collection('gallery_photos')
          .where('albumId', isEqualTo: id)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in photosQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the album
      batch.delete(_firestore.collection('gallery_albums').doc(id));
      
      await batch.commit();
      
      if (kDebugMode) {
        print('Gallery album and its photos deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting gallery album: $e');
      }
      return false;
    }
  }

  Future<GalleryAlbum?> getGalleryAlbum(String id) async {
    try {
      final doc = await _firestore.collection('gallery_albums').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return _mapToGalleryAlbum(doc.id, data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting gallery album: $e');
      }
      return null;
    }
  }

  Future<List<GalleryAlbum>> getGalleryAlbums({
    String? schoolId,
    String? classCode,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('gallery_albums');
      
      if (schoolId != null) {
        query = query.where('schoolId', isEqualTo: schoolId);
      }
      if (classCode != null) {
        query = query.where('classCode', isEqualTo: classCode);
      }
      
      query = query.where('isActive', isEqualTo: true)
                  .orderBy('createdAt', descending: true)
                  .limit(limit);
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        return _mapToGalleryAlbum(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting gallery albums: $e');
      }
      return [];
    }
  }

  // File Upload and Watermark Operations
  Future<Map<String, String>?> uploadPhotoWithWatermark({
    required File imageFile,
    required String classCode,
    required String schoolId,
    required String albumId,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$classCode';
      
      // Upload original image
      final originalRef = _storage.ref().child('gallery/original/$fileName.jpg');
      final originalUpload = await originalRef.putFile(imageFile);
      final originalUrl = await originalUpload.ref.getDownloadURL();
      
      // Create watermarked version (placeholder - implement actual watermarking)
      final watermarkedRef = _storage.ref().child('gallery/watermarked/$fileName.jpg');
      final watermarkedUpload = await watermarkedRef.putFile(imageFile);
      final watermarkedUrl = await watermarkedUpload.ref.getDownloadURL();
      
      // Create thumbnail (placeholder - implement actual thumbnail generation)
      final thumbnailRef = _storage.ref().child('gallery/thumbnails/$fileName.jpg');
      final thumbnailUpload = await thumbnailRef.putFile(imageFile);
      final thumbnailUrl = await thumbnailUpload.ref.getDownloadURL();
      
      return {
        'originalUrl': originalUrl,
        'watermarkedUrl': watermarkedUrl,
        'thumbnailUrl': thumbnailUrl,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading photo with watermark: $e');
      }
      return null;
    }
  }

  // Helper Methods
  Future<void> _updateAlbumPhotoCount(String albumId, int increment) async {
    try {
      final albumRef = _firestore.collection('gallery_albums').doc(albumId);
      await _firestore.runTransaction((transaction) async {
        final albumDoc = await transaction.get(albumRef);
        if (albumDoc.exists) {
          final currentCount = albumDoc.data()?['photoCount'] ?? 0;
          final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
          transaction.update(albumRef, {'photoCount': newCount});
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating album photo count: $e');
      }
    }
  }

  GalleryPhoto _mapToGalleryPhoto(String id, Map<String, dynamic> data) {
    return GalleryPhoto(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      originalImageUrl: data['originalImageUrl'] ?? '',
      watermarkedImageUrl: data['watermarkedImageUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      schoolId: data['schoolId'] ?? '',
      classCode: data['classCode'] ?? '',
      albumId: data['albumId'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploaderName: data['uploaderName'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
      isActive: data['isActive'] ?? true,
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  GalleryAlbum _mapToGalleryAlbum(String id, Map<String, dynamic> data) {
    return GalleryAlbum(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      schoolId: data['schoolId'] ?? '',
      classCode: data['classCode'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
      isActive: data['isActive'] ?? true,
      photoCount: data['photoCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Search functionality
  Future<List<GalleryPhoto>> searchPhotos({
    required String query,
    String? schoolId,
    String? classCode,
    String? albumId,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('gallery_photos');
      
      if (schoolId != null) {
        firestoreQuery = firestoreQuery.where('schoolId', isEqualTo: schoolId);
      }
      if (classCode != null) {
        firestoreQuery = firestoreQuery.where('classCode', isEqualTo: classCode);
      }
      if (albumId != null) {
        firestoreQuery = firestoreQuery.where('albumId', isEqualTo: albumId);
      }
      
      firestoreQuery = firestoreQuery.where('isActive', isEqualTo: true);
      
      final querySnapshot = await firestoreQuery.get();
      
      // Filter by title or tags containing the search query
      final results = querySnapshot.docs
          .map((doc) => _mapToGalleryPhoto(doc.id, doc.data() as Map<String, dynamic>))
          .where((photo) =>
              photo.title.toLowerCase().contains(query.toLowerCase()) ||
              photo.description.toLowerCase().contains(query.toLowerCase()) ||
              photo.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching photos: $e');
      }
      return [];
    }
  }

  Future<List<GalleryAlbum>> searchAlbums({
    required String query,
    String? schoolId,
    String? classCode,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('gallery_albums');
      
      if (schoolId != null) {
        firestoreQuery = firestoreQuery.where('schoolId', isEqualTo: schoolId);
      }
      if (classCode != null) {
        firestoreQuery = firestoreQuery.where('classCode', isEqualTo: classCode);
      }
      
      firestoreQuery = firestoreQuery.where('isActive', isEqualTo: true);
      
      final querySnapshot = await firestoreQuery.get();
      
      // Filter by name or tags containing the search query
      final results = querySnapshot.docs
          .map((doc) => _mapToGalleryAlbum(doc.id, doc.data() as Map<String, dynamic>))
          .where((album) =>
              album.name.toLowerCase().contains(query.toLowerCase()) ||
              album.description.toLowerCase().contains(query.toLowerCase()) ||
              album.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching albums: $e');
      }
      return [];
    }
  }

  // Like Operations
  Future<String?> likePhoto({
    required String photoId,
    required String studentId,
    required String studentName,
    required String schoolId,
  }) async {
    try {
      // Check if already liked
      final existingLike = await _firestore
          .collection('gallery_likes')
          .where('photoId', isEqualTo: photoId)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (existingLike.docs.isNotEmpty) {
        if (kDebugMode) {
          print('Photo already liked by this student');
        }
        return existingLike.docs.first.id;
      }

      final likeData = {
        'photoId': photoId,
        'studentId': studentId,
        'studentName': studentName,
        'schoolId': schoolId,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final docRef = await _firestore.collection('gallery_likes').add(likeData);
      
      if (kDebugMode) {
        print('Photo liked successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error liking photo: $e');
      }
      return null;
    }
  }

  Future<bool> unlikePhoto({
    required String photoId,
    required String studentId,
  }) async {
    try {
      final likeQuery = await _firestore
          .collection('gallery_likes')
          .where('photoId', isEqualTo: photoId)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (likeQuery.docs.isEmpty) {
        if (kDebugMode) {
          print('Like not found');
        }
        return false;
      }

      await _firestore.collection('gallery_likes').doc(likeQuery.docs.first.id).delete();
      
      if (kDebugMode) {
        print('Photo unliked successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unliking photo: $e');
      }
      return false;
    }
  }

  Future<List<GalleryLike>> getPhotoLikes(String photoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gallery_likes')
          .where('photoId', isEqualTo: photoId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return _mapToGalleryLike(doc.id, doc.data());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting photo likes: $e');
      }
      return [];
    }
  }

  Future<int> getPhotoLikeCount(String photoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gallery_likes')
          .where('photoId', isEqualTo: photoId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting photo like count: $e');
      }
      return 0;
    }
  }

  Future<bool> isPhotoLikedByStudent({
    required String photoId,
    required String studentId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('gallery_likes')
          .where('photoId', isEqualTo: photoId)
          .where('studentId', isEqualTo: studentId)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if photo is liked: $e');
      }
      return false;
    }
  }

  // Comment Operations
  Future<String?> addComment({
    required String photoId,
    required String studentId,
    required String studentName,
    required String schoolId,
    required String comment,
  }) async {
    try {
      final commentData = {
        'photoId': photoId,
        'studentId': studentId,
        'studentName': studentName,
        'schoolId': schoolId,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': null,
        'isActive': true,
      };

      final docRef = await _firestore.collection('gallery_comments').add(commentData);
      
      if (kDebugMode) {
        print('Comment added successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding comment: $e');
      }
      return null;
    }
  }

  Future<bool> updateComment({
    required String commentId,
    required String comment,
  }) async {
    try {
      await _firestore.collection('gallery_comments').doc(commentId).update({
        'comment': comment,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      if (kDebugMode) {
        print('Comment updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating comment: $e');
      }
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      await _firestore.collection('gallery_comments').doc(commentId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      if (kDebugMode) {
        print('Comment deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting comment: $e');
      }
      return false;
    }
  }

  Future<List<GalleryComment>> getPhotoComments(String photoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gallery_comments')
          .where('photoId', isEqualTo: photoId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        return _mapToGalleryComment(doc.id, doc.data());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting photo comments: $e');
      }
      return [];
    }
  }

  Future<int> getPhotoCommentCount(String photoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gallery_comments')
          .where('photoId', isEqualTo: photoId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting photo comment count: $e');
      }
      return 0;
    }
  }

  // Get photo with stats (likes and comments)
  Future<GalleryPhotoWithStats?> getPhotoWithStats({
    required String photoId,
    required String currentStudentId,
  }) async {
    try {
      final photo = await getGalleryPhoto(photoId);
      if (photo == null) return null;

      final likeCount = await getPhotoLikeCount(photoId);
      final commentCount = await getPhotoCommentCount(photoId);
      final isLiked = await isPhotoLikedByStudent(
        photoId: photoId,
        studentId: currentStudentId,
      );
      final likes = await getPhotoLikes(photoId);
      final comments = await getPhotoComments(photoId);

      return GalleryPhotoWithStats(
        photo: photo,
        likeCount: likeCount,
        commentCount: commentCount,
        isLikedByCurrentUser: isLiked,
        likes: likes,
        comments: comments,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting photo with stats: $e');
      }
      return null;
    }
  }

  Future<List<GalleryPhotoWithStats>> getPhotosWithStats({
    String? schoolId,
    String? classCode,
    String? albumId,
    required String currentStudentId,
    int limit = 50,
  }) async {
    try {
      final photos = await getGalleryPhotos(
        schoolId: schoolId,
        classCode: classCode,
        albumId: albumId,
        limit: limit,
      );

      final List<GalleryPhotoWithStats> photosWithStats = [];

      for (final photo in photos) {
        final likeCount = await getPhotoLikeCount(photo.id);
        final commentCount = await getPhotoCommentCount(photo.id);
        final isLiked = await isPhotoLikedByStudent(
          photoId: photo.id,
          studentId: currentStudentId,
        );

        photosWithStats.add(GalleryPhotoWithStats(
          photo: photo,
          likeCount: likeCount,
          commentCount: commentCount,
          isLikedByCurrentUser: isLiked,
          likes: [],
          comments: [],
        ));
      }

      return photosWithStats;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting photos with stats: $e');
      }
      return [];
    }
  }

  // Helper methods for mapping
  GalleryLike _mapToGalleryLike(String id, Map<String, dynamic> data) {
    return GalleryLike(
      id: id,
      photoId: data['photoId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      schoolId: data['schoolId'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  GalleryComment _mapToGalleryComment(String id, Map<String, dynamic> data) {
    return GalleryComment(
      id: id,
      photoId: data['photoId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      schoolId: data['schoolId'] ?? '',
      comment: data['comment'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
      isActive: data['isActive'] ?? true,
    );
  }
}