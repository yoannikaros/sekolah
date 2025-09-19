import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';

class PostProvider with ChangeNotifier {
  final PostService _postService = PostService();
  
  List<Post> _posts = [];
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;
  Post? _selectedPost;
  
  // Getters
  List<Post> get posts => _posts;
  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Post? get selectedPost => _selectedPost;
  
  // Filter getters
  List<Post> get approvedPosts => _posts.where((post) => post.status == PostStatus.approved).toList();
  List<Post> get pendingPosts => _posts.where((post) => post.status == PostStatus.pending).toList();
  List<Post> get myPosts => _posts.where((post) => post.authorId == _getCurrentUserId()).toList();
  
  int? _getCurrentUserId() {
    // This should be implemented to get current user ID from AuthProvider
    return null;
  }
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Fetch all posts
  Future<void> fetchPosts({
    PostType? type,
    PostStatus? status,
    int? classId,
    int? authorId,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _posts = await _postService.getPosts(
        type: type,
        status: status,
        classId: classId,
        authorId: authorId,
      );
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat postingan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Fetch post by ID
  Future<void> fetchPostById(int id) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _selectedPost = await _postService.getPostById(id);
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat detail postingan: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Create new post
  Future<bool> createPost({
    required String title,
    required String description,
    required PostType type,
    int? classId,
    String? subject,
    List<String>? tags,
    List<String>? filePaths,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final newPost = await _postService.createPost(
        title: title,
        description: description,
        type: type,
        classId: classId,
        subject: subject,
        tags: tags,
        filePaths: filePaths,
      );
      
      _posts.insert(0, newPost);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal membuat postingan: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update post
  Future<bool> updatePost({
    required int id,
    required String title,
    required String description,
    required PostType type,
    int? classId,
    String? subject,
    List<String>? tags,
    List<String>? filePaths,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final updatedPost = await _postService.updatePost(
        id: id,
        title: title,
        description: description,
        type: type,
        classId: classId,
        subject: subject,
        tags: tags,
        filePaths: filePaths,
      );
      
      final index = _posts.indexWhere((post) => post.id == id);
      if (index != -1) {
        _posts[index] = updatedPost;
        notifyListeners();
      }
      
      if (_selectedPost?.id == id) {
        _selectedPost = updatedPost;
      }
      
      return true;
    } catch (e) {
      _setError('Gagal mengupdate postingan: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete post
  Future<bool> deletePost(int id) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _postService.deletePost(id);
      _posts.removeWhere((post) => post.id == id);
      
      if (_selectedPost?.id == id) {
        _selectedPost = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal menghapus postingan: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Approve post (for teachers/admins)
  Future<bool> approvePost(int id) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _postService.approvePost(id);
      
      final index = _posts.indexWhere((post) => post.id == id);
      if (index != -1) {
        // Update post status locally
        final updatedPost = Post(
          id: _posts[index].id,
          title: _posts[index].title,
          description: _posts[index].description,
          type: _posts[index].type,
          mediaFiles: _posts[index].mediaFiles,
          authorId: _posts[index].authorId,
          author: _posts[index].author,
          classId: _posts[index].classId,
          subject: _posts[index].subject,
          tags: _posts[index].tags,
          status: PostStatus.approved,
          approvedBy: _getCurrentUserId(),
          approvedAt: DateTime.now(),
          likes: _posts[index].likes,
          views: _posts[index].views,
          createdAt: _posts[index].createdAt,
          updatedAt: DateTime.now(),
          likesCount: _posts[index].likesCount,
          commentsCount: _posts[index].commentsCount,
        );
        _posts[index] = updatedPost;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Gagal menyetujui postingan: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Reject post (for teachers/admins)
  Future<bool> rejectPost(int id, String reason) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _postService.rejectPost(id, reason);
      
      final index = _posts.indexWhere((post) => post.id == id);
      if (index != -1) {
        // Update post status locally
        final updatedPost = Post(
          id: _posts[index].id,
          title: _posts[index].title,
          description: _posts[index].description,
          type: _posts[index].type,
          mediaFiles: _posts[index].mediaFiles,
          authorId: _posts[index].authorId,
          author: _posts[index].author,
          classId: _posts[index].classId,
          subject: _posts[index].subject,
          tags: _posts[index].tags,
          status: PostStatus.rejected,
          approvedBy: _getCurrentUserId(),
          approvedAt: DateTime.now(),
          likes: _posts[index].likes,
          views: _posts[index].views,
          createdAt: _posts[index].createdAt,
          updatedAt: DateTime.now(),
          likesCount: _posts[index].likesCount,
          commentsCount: _posts[index].commentsCount,
        );
        _posts[index] = updatedPost;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Gagal menolak postingan: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Like/Unlike post
  Future<bool> toggleLike(int postId) async {
    try {
      await _postService.toggleLike(postId);
      
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final currentUserId = _getCurrentUserId();
        if (currentUserId != null) {
          final currentLikes = List<int>.from(_posts[index].likes ?? []);
          
          if (currentLikes.contains(currentUserId)) {
            currentLikes.remove(currentUserId);
          } else {
            currentLikes.add(currentUserId);
          }
          
          // Update post with new likes
          final updatedPost = Post(
            id: _posts[index].id,
            title: _posts[index].title,
            description: _posts[index].description,
            type: _posts[index].type,
            mediaFiles: _posts[index].mediaFiles,
            authorId: _posts[index].authorId,
            author: _posts[index].author,
            classId: _posts[index].classId,
            subject: _posts[index].subject,
            tags: _posts[index].tags,
            status: _posts[index].status,
            approvedBy: _posts[index].approvedBy,
            approvedAt: _posts[index].approvedAt,
            likes: currentLikes,
            views: _posts[index].views,
            createdAt: _posts[index].createdAt,
            updatedAt: _posts[index].updatedAt,
            likesCount: currentLikes.length,
            commentsCount: _posts[index].commentsCount,
          );
          _posts[index] = updatedPost;
          notifyListeners();
        }
      }
      
      return true;
    } catch (e) {
      _setError('Gagal mengubah like: ${e.toString()}');
      return false;
    }
  }
  
  // Get comments for a specific post
  List<Comment> getCommentsForPost(int postId) {
    return _comments.where((comment) => comment.postId == postId).toList();
  }

  // Fetch comments for a post
  Future<void> fetchComments(int postId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _comments = await _postService.getComments(postId);
      notifyListeners();
    } catch (e) {
      _setError('Gagal memuat komentar: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Add comment
  Future<bool> addComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final newComment = await _postService.addComment(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
      );
      
      if (parentCommentId == null) {
        _comments.insert(0, newComment);
      } else {
        // Add as reply to parent comment
        final parentIndex = _comments.indexWhere((c) => c.id == parentCommentId);
        if (parentIndex != -1) {
          final parentComment = _comments[parentIndex];
          final updatedReplies = List<Comment>.from(parentComment.replies ?? []);
          updatedReplies.add(newComment);
          
          // Update parent comment with new reply
          // Note: This is a simplified approach, you might need to create a new Comment object
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal menambah komentar: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete comment
  Future<bool> deleteComment(int commentId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      await _postService.deleteComment(commentId);
      _comments.removeWhere((comment) => comment.id == commentId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Gagal menghapus komentar: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Clear selected post
  void clearSelectedPost() {
    _selectedPost = null;
    notifyListeners();
  }
  
  // Clear comments
  void clearComments() {
    _comments.clear();
    notifyListeners();
  }
  
  // Refresh posts
  Future<void> refreshPosts() async {
    await fetchPosts();
  }
}