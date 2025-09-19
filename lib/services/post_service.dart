import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/post.dart';

class PostService {
  static const String baseUrl = 'http://localhost:3000/api';
  late Dio _dio;
  
  PostService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptor for authentication
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }
  
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Get all posts with optional filters
  Future<List<Post>> getPosts({
    PostType? type,
    PostStatus? status,
    int? classId,
    int? authorId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (type != null) {
        queryParams['type'] = type.name;
      }
      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (classId != null) {
        queryParams['class_id'] = classId.toString();
      }
      if (authorId != null) {
        queryParams['author_id'] = authorId.toString();
      }
      
      final response = await _dio.get('/posts', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> postsJson = data['posts'] ?? [];
          return postsJson.map((json) => Post.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch posts');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to fetch posts: $e');
    }
  }
  
  // Get post by ID
  Future<Post> getPostById(int id) async {
    try {
      final response = await _dio.get('/posts/$id');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return Post.fromJson(data['post']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch post');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to fetch post: $e');
    }
  }
  
  // Create new post
  Future<Post> createPost({
    required String title,
    required String description,
    required PostType type,
    int? classId,
    String? subject,
    List<String>? tags,
    List<String>? filePaths,
  }) async {
    try {
      FormData formData = FormData();
      
      // Add text fields
      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('type', type.name),
      ]);
      
      if (classId != null) {
        formData.fields.add(MapEntry('class_id', classId.toString()));
      }
      
      if (subject != null) {
        formData.fields.add(MapEntry('subject', subject));
      }
      
      if (tags != null && tags.isNotEmpty) {
        formData.fields.add(MapEntry('tags', jsonEncode(tags)));
      }
      
      // Add files
      if (filePaths != null && filePaths.isNotEmpty) {
        for (String filePath in filePaths) {
          final file = File(filePath);
          if (await file.exists()) {
            formData.files.add(MapEntry(
              'files',
              await MultipartFile.fromFile(
                filePath,
                filename: file.path.split('/').last,
              ),
            ));
          }
        }
      }
      
      final response = await _dio.post('/posts', data: formData);
      
      if (response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          return Post.fromJson(data['post']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create post');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to create post: $e');
    }
  }
  
  // Update post
  Future<Post> updatePost({
    required int id,
    required String title,
    required String description,
    required PostType type,
    int? classId,
    String? subject,
    List<String>? tags,
    List<String>? filePaths,
  }) async {
    try {
      FormData formData = FormData();
      
      // Add text fields
      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('description', description),
        MapEntry('type', type.name),
      ]);
      
      if (classId != null) {
        formData.fields.add(MapEntry('class_id', classId.toString()));
      }
      
      if (subject != null) {
        formData.fields.add(MapEntry('subject', subject));
      }
      
      if (tags != null && tags.isNotEmpty) {
        formData.fields.add(MapEntry('tags', jsonEncode(tags)));
      }
      
      // Add files
      if (filePaths != null && filePaths.isNotEmpty) {
        for (String filePath in filePaths) {
          final file = File(filePath);
          if (await file.exists()) {
            formData.files.add(MapEntry(
              'files',
              await MultipartFile.fromFile(
                filePath,
                filename: file.path.split('/').last,
              ),
            ));
          }
        }
      }
      
      final response = await _dio.put('/posts/$id', data: formData);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return Post.fromJson(data['post']);
        } else {
          throw Exception(data['message'] ?? 'Failed to update post');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to update post: $e');
    }
  }
  
  // Delete post
  Future<void> deletePost(int id) async {
    try {
      final response = await _dio.delete('/posts/$id');
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
      
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete post');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to delete post: $e');
    }
  }
  
  // Approve post (for teachers/admins)
  Future<void> approvePost(int id) async {
    try {
      final response = await _dio.post('/posts/$id/approve');
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
      
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to approve post');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to approve post: $e');
    }
  }
  
  // Reject post (for teachers/admins)
  Future<void> rejectPost(int id, String reason) async {
    try {
      final response = await _dio.post('/posts/$id/reject', data: {
        'rejection_reason': reason,
      });
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
      
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to reject post');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to reject post: $e');
    }
  }
  
  // Toggle like on post
  Future<void> toggleLike(int postId) async {
    try {
      final response = await _dio.post('/posts/$postId/like');
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
      
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to toggle like');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to toggle like: $e');
    }
  }
  
  // Get comments for a post
  Future<List<Comment>> getComments(int postId) async {
    try {
      final response = await _dio.get('/posts/$postId/comments');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> commentsJson = data['comments'] ?? [];
          return commentsJson.map((json) => Comment.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch comments');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to fetch comments: $e');
    }
  }
  
  // Add comment to post
  Future<Comment> addComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final requestData = {
        'content': content,
      };
      
      if (parentCommentId != null) {
        requestData['parent_comment_id'] = parentCommentId.toString();
      }
      
      final response = await _dio.post('/posts/$postId/comments', data: requestData);
      
      if (response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          return Comment.fromJson(data['comment']);
        } else {
          throw Exception(data['message'] ?? 'Failed to add comment');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to add comment: $e');
    }
  }
  
  // Delete comment
  Future<void> deleteComment(int commentId) async {
    try {
      final response = await _dio.delete('/comments/$commentId');
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
      
      final data = response.data;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete comment');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('Failed to delete comment: $e');
    }
  }
}