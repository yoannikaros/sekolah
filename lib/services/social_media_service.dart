import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/social_media_models.dart';
import 'content_moderation_service.dart';

class SocialMediaService {
  static final SocialMediaService _instance = SocialMediaService._internal();
  factory SocialMediaService() => _instance;
  SocialMediaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContentModerationService _moderationService = ContentModerationService();

  // Collections
  static const String _postsCollection = 'social_media_posts';
  static const String _commentsCollection = 'post_comments';
  static const String _likesCollection = 'post_likes';
  static const String _userProfilesCollection = 'user_profiles';
  static const String _userFollowsCollection = 'user_follows';

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String get currentUserName => _auth.currentUser?.displayName ?? 'Unknown User';

  // ==================== POST OPERATIONS ====================

  /// Membuat postingan baru
  Future<String> createPost({
    required String content,
    required PostType type,
    String? classCode,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (content.trim().isEmpty) {
        throw Exception('Konten postingan tidak boleh kosong');
      }

      // Moderasi konten
      final moderationResult = _moderationService.moderateContent(content);
      
      final post = SocialMediaPost(
        id: '',
        authorId: currentUserId,
        authorName: currentUserName,
        content: moderationResult.moderatedContent,
        originalContent: content,
        type: type,
        createdAt: DateTime.now(),
        isModerated: moderationResult.isModerated,
        classCode: classCode,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection(_postsCollection)
          .add(post.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Gagal membuat postingan: $e');
    }
  }

  /// Mengambil feed postingan dengan pagination
  Stream<List<SocialMediaPost>> getPostsFeed({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    PostType? filterType,
    String? classCode,
  }) {
    try {
      Query query;
      
      // Simplified query to avoid composite index requirements
      if (classCode != null && classCode.isNotEmpty) {
        // For class-specific posts, use only classCode filter
        // Then sort and filter on client side to avoid composite index
        query = _firestore
            .collection(_postsCollection)
            .where('classCode', isEqualTo: classCode)
            .limit(limit * 3); // Get more docs for client-side sorting
      } else {
        // For general feed, use simple time-based query
        query = _firestore
            .collection(_postsCollection)
            .orderBy('createdAt', descending: true)
            .limit(limit);
      }

      if (lastDocument != null && classCode == null) {
        // Only use pagination for general feed to avoid complex queries
        query = query.startAfterDocument(lastDocument);
      }

      return query.snapshots().map((snapshot) {
        var posts = snapshot.docs
            .map((doc) => SocialMediaPost.fromFirestore(doc))
            .where((post) {
              // Client-side filtering
              if (post.isDeleted) return false;
              
              // Apply type filter if provided
              if (filterType != null) {
                final postTypeString = filterType.toString().split('.').last;
                if (post.type.toString().split('.').last != postTypeString) {
                  return false;
                }
              }
              
              return true;
            })
            .toList();

        // Sort by createdAt on client side for class-specific queries
        if (classCode != null && classCode.isNotEmpty) {
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        return posts.take(limit).toList();
      });
    } catch (e) {
      // Return empty stream instead of throwing to prevent app crashes
      return Stream.value(<SocialMediaPost>[]);
    }
  }

  /// Mengambil postingan berdasarkan ID
  Future<SocialMediaPost?> getPostById(String postId) async {
    try {
      final doc = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .get();

      if (doc.exists) {
        return SocialMediaPost.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil postingan: $e');
    }
  }

  /// Mengambil postingan berdasarkan author
  Stream<List<SocialMediaPost>> getPostsByAuthor(String authorId) {
    try {
      return _firestore
          .collection(_postsCollection)
          .where('authorId', isEqualTo: authorId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => SocialMediaPost.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Gagal mengambil postingan author: $e');
    }
  }

  /// Alias untuk getUserPosts - mendapatkan postingan user
  Future<List<SocialMediaPost>> getUserPosts(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('authorId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SocialMediaPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil postingan: $e');
    }
  }

  /// Update postingan
  Future<void> updatePost({
    required String postId,
    required String newContent,
  }) async {
    try {
      final post = await getPostById(postId);
      if (post == null) {
        throw Exception('Postingan tidak ditemukan');
      }

      if (post.authorId != currentUserId) {
        throw Exception('Anda tidak memiliki izin untuk mengedit postingan ini');
      }

      // Moderasi konten baru
      final moderationResult = _moderationService.moderateContent(newContent);

      await _firestore.collection(_postsCollection).doc(postId).update({
        'content': moderationResult.moderatedContent,
        'originalContent': newContent,
        'updatedAt': DateTime.now(),
        'isEdited': true,
        'isModerated': moderationResult.isModerated,
      });
    } catch (e) {
      throw Exception('Gagal mengupdate postingan: $e');
    }
  }

  /// Hapus postingan (soft delete)
  Future<void> deletePost(String postId) async {
    try {
      final post = await getPostById(postId);
      if (post == null) {
        throw Exception('Postingan tidak ditemukan');
      }

      if (post.authorId != currentUserId) {
        throw Exception('Anda tidak memiliki izin untuk menghapus postingan ini');
      }

      await _firestore.collection(_postsCollection).doc(postId).update({
        'isDeleted': true,
        'updatedAt': DateTime.now(),
      });

      // Hapus semua komentar dan like terkait
      await _deletePostRelatedData(postId);
    } catch (e) {
      throw Exception('Gagal menghapus postingan: $e');
    }
  }

  /// Hapus data terkait postingan (komentar dan like)
  Future<void> _deletePostRelatedData(String postId) async {
    final batch = _firestore.batch();

    // Hapus komentar
    final commentsQuery = await _firestore
        .collection(_commentsCollection)
        .where('postId', isEqualTo: postId)
        .get();

    for (final doc in commentsQuery.docs) {
      batch.update(doc.reference, {'isDeleted': true});
    }

    // Hapus like
    final likesQuery = await _firestore
        .collection(_likesCollection)
        .where('postId', isEqualTo: postId)
        .get();

    for (final doc in likesQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ==================== LIKE OPERATIONS ====================

  /// Toggle like pada postingan
  Future<void> togglePostLike(String postId) async {
    try {
      final likeQuery = await _firestore
          .collection(_likesCollection)
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: currentUserId)
          .where('commentId', isNull: true)
          .get();

      final batch = _firestore.batch();

      if (likeQuery.docs.isNotEmpty) {
        // Unlike - hapus like
        for (final doc in likeQuery.docs) {
          batch.delete(doc.reference);
        }

        // Update counter di post
        final postRef = _firestore.collection(_postsCollection).doc(postId);
        batch.update(postRef, {
          'likesCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Like - tambah like
        final like = PostLike(
          id: '',
          postId: postId,
          userId: currentUserId,
          userName: currentUserName,
          createdAt: DateTime.now(),
        );

        final likeRef = _firestore.collection(_likesCollection).doc();
        batch.set(likeRef, like.toFirestore());

        // Update counter di post
        final postRef = _firestore.collection(_postsCollection).doc(postId);
        batch.update(postRef, {
          'likesCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal toggle like postingan: $e');
    }
  }

  /// Cek apakah user sudah like postingan
  Future<bool> isPostLikedByUser(String postId) async {
    try {
      final likeQuery = await _firestore
          .collection(_likesCollection)
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: currentUserId)
          .where('commentId', isNull: true)
          .get();

      return likeQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== COMMENT OPERATIONS ====================

  /// Tambah komentar pada postingan
  Future<String> addComment({
    required String postId,
    required String content,
    String? replyToCommentId,
  }) async {
    try {
      if (content.trim().isEmpty) {
        throw Exception('Komentar tidak boleh kosong');
      }

      // Moderasi konten komentar
      final moderationResult = _moderationService.moderateContent(content);

      final comment = PostComment(
        id: '',
        postId: postId,
        authorId: currentUserId,
        authorName: currentUserName,
        content: moderationResult.moderatedContent,
        originalContent: content,
        createdAt: DateTime.now(),
        isModerated: moderationResult.isModerated,
        replyToCommentId: replyToCommentId,
      );

      if (kDebugMode) {
        print('DEBUG: Creating comment with authorId: $currentUserId, authorName: $currentUserName');
      }

      final batch = _firestore.batch();

      // Tambah komentar
      final commentRef = _firestore.collection(_commentsCollection).doc();
      batch.set(commentRef, comment.toFirestore());

      // Update counter di post
      final postRef = _firestore.collection(_postsCollection).doc(postId);
      batch.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });

      await batch.commit();
      return commentRef.id;
    } catch (e) {
      throw Exception('Gagal menambah komentar: $e');
    }
  }

  /// Mengambil komentar berdasarkan postingan
  Stream<List<PostComment>> getCommentsByPost(String postId) {
    try {
      return _firestore
          .collection(_commentsCollection)
          .where('postId', isEqualTo: postId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => PostComment.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Gagal mengambil komentar: $e');
    }
  }

  /// Update komentar
  Future<void> updateComment({
    required String commentId,
    required String newContent,
  }) async {
    try {
      final commentDoc = await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        throw Exception('Komentar tidak ditemukan');
      }

      final comment = PostComment.fromFirestore(commentDoc);
      if (comment.authorId != currentUserId) {
        throw Exception('Anda tidak memiliki izin untuk mengedit komentar ini');
      }

      // Moderasi konten baru
      final moderationResult = _moderationService.moderateContent(newContent);

      await _firestore.collection(_commentsCollection).doc(commentId).update({
        'content': moderationResult.moderatedContent,
        'originalContent': newContent,
        'updatedAt': DateTime.now(),
        'isEdited': true,
        'isModerated': moderationResult.isModerated,
      });
    } catch (e) {
      throw Exception('Gagal mengupdate komentar: $e');
    }
  }

  /// Hapus komentar
  Future<void> deleteComment(String commentId) async {
    try {
      final commentDoc = await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        throw Exception('Komentar tidak ditemukan');
      }

      final comment = PostComment.fromFirestore(commentDoc);
      if (comment.authorId != currentUserId) {
        throw Exception('Anda tidak memiliki izin untuk menghapus komentar ini');
      }

      final batch = _firestore.batch();

      // Soft delete komentar
      batch.update(commentDoc.reference, {
        'isDeleted': true,
        'updatedAt': DateTime.now(),
      });

      // Update counter di post
      final postRef = _firestore.collection(_postsCollection).doc(comment.postId);
      batch.update(postRef, {
        'commentsCount': FieldValue.increment(-1),
      });

      // Hapus like komentar
      final likesQuery = await _firestore
          .collection(_likesCollection)
          .where('commentId', isEqualTo: commentId)
          .get();

      for (final doc in likesQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal menghapus komentar: $e');
    }
  }

  /// Toggle like pada komentar
  Future<void> toggleCommentLike(String commentId, String postId) async {
    try {
      final likeQuery = await _firestore
          .collection(_likesCollection)
          .where('commentId', isEqualTo: commentId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      final batch = _firestore.batch();

      if (likeQuery.docs.isNotEmpty) {
        // Unlike - hapus like
        for (final doc in likeQuery.docs) {
          batch.delete(doc.reference);
        }

        // Update counter di comment
        final commentRef = _firestore.collection(_commentsCollection).doc(commentId);
        batch.update(commentRef, {
          'likesCount': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Like - tambah like
        final like = PostLike(
          id: '',
          postId: postId,
          commentId: commentId,
          userId: currentUserId,
          userName: currentUserName,
          createdAt: DateTime.now(),
        );

        final likeRef = _firestore.collection(_likesCollection).doc();
        batch.set(likeRef, like.toFirestore());

        // Update counter di comment
        final commentRef = _firestore.collection(_commentsCollection).doc(commentId);
        batch.update(commentRef, {
          'likesCount': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUserId]),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal toggle like komentar: $e');
    }
  }

  /// Cek apakah user sudah like komentar
  Future<bool> isCommentLikedByUser(String commentId) async {
    try {
      final likeQuery = await _firestore
          .collection(_likesCollection)
          .where('commentId', isEqualTo: commentId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      return likeQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==================== SEARCH & FILTER ====================

  /// Pencarian postingan berdasarkan konten
  Future<List<SocialMediaPost>> searchPosts(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // Firebase tidak mendukung full-text search, jadi kita gunakan array-contains
      // Untuk implementasi yang lebih baik, gunakan Algolia atau ElasticSearch
      final querySnapshot = await _firestore
          .collection(_postsCollection)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final posts = querySnapshot.docs
          .map((doc) => SocialMediaPost.fromFirestore(doc))
          .where((post) => post.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return posts;
    } catch (e) {
      throw Exception('Gagal mencari postingan: $e');
    }
  }

  // ==================== STATISTICS ====================

  /// Mengambil statistik postingan user
  Future<Map<String, int>> getUserPostStats(String userId) async {
    try {
      final postsQuery = await _firestore
          .collection(_postsCollection)
          .where('authorId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      int totalPosts = postsQuery.docs.length;
      int totalLikes = 0;
      int totalComments = 0;

      for (final doc in postsQuery.docs) {
        final post = SocialMediaPost.fromFirestore(doc);
        totalLikes += post.likesCount;
        totalComments += post.commentsCount;
      }

      return {
        'totalPosts': totalPosts,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik: $e');
    }
  }

  /// Mengambil postingan yang dilike oleh user
  Stream<List<SocialMediaPost>> getLikedPostsByUser(String userId) {
    try {
      return _firestore
          .collection(_likesCollection)
          .where('userId', isEqualTo: userId)
          .where('commentId', isNull: true) // Only post likes, not comment likes
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((likesSnapshot) async {
        if (likesSnapshot.docs.isEmpty) {
          return <SocialMediaPost>[];
        }

        // Get post IDs from likes
        final postIds = likesSnapshot.docs
            .map((doc) => doc.data()['postId'] as String)
            .toList();

        if (postIds.isEmpty) {
          return <SocialMediaPost>[];
        }

        // Fetch posts in batches (Firestore 'in' query limit is 10)
        final List<SocialMediaPost> allPosts = [];
        
        for (int i = 0; i < postIds.length; i += 10) {
          final batch = postIds.skip(i).take(10).toList();
          
          final postsQuery = await _firestore
              .collection(_postsCollection)
              .where(FieldPath.documentId, whereIn: batch)
              .where('isDeleted', isEqualTo: false)
              .get();

          final batchPosts = postsQuery.docs
              .map((doc) => SocialMediaPost.fromFirestore(doc))
              .toList();
          
          allPosts.addAll(batchPosts);
        }

        // Sort by the original like order (most recent likes first)
        final likeOrderMap = <String, int>{};
        for (int i = 0; i < postIds.length; i++) {
          likeOrderMap[postIds[i]] = i;
        }

        allPosts.sort((a, b) {
          final aOrder = likeOrderMap[a.id] ?? 999999;
          final bOrder = likeOrderMap[b.id] ?? 999999;
          return aOrder.compareTo(bOrder);
        });

        if (kDebugMode) {
          print('getLikedPostsByUser: Found ${allPosts.length} liked posts for user $userId');
        }

        return allPosts;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error in getLikedPostsByUser: $e');
      }
      return Stream.value(<SocialMediaPost>[]);
    }
  }

  // ==================== USER PROFILE OPERATIONS ====================

  /// Membuat atau mengupdate profil pengguna
  Future<void> createOrUpdateUserProfile({
    required String userId,
    required String displayName,
    String? bio,
    String? profileImageUrl,
    String? classCode,
    String? email,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final profile = UserProfile(
        id: userId,
        name: displayName,
        bio: bio,
        avatar: profileImageUrl,
        classCode: classCode,
        email: email,
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        metadata: additionalData,
      );

      await _firestore
          .collection(_userProfilesCollection)
          .doc(userId)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Gagal membuat/mengupdate profil: $e');
    }
  }

  /// Mengambil profil pengguna berdasarkan ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_userProfilesCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil profil pengguna: $e');
    }
  }

  /// Mengambil profil pengguna saat ini
  Future<UserProfile?> getCurrentUserProfile() async {
    if (currentUserId.isEmpty) return null;
    return getUserProfile(currentUserId);
  }

  /// Update profil pengguna
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? profileImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (currentUserId.isEmpty) {
        throw Exception('User tidak terautentikasi');
      }

      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (additionalData != null) updateData['additionalData'] = additionalData;

      await _firestore
          .collection(_userProfilesCollection)
          .doc(currentUserId)
          .update(updateData);
    } catch (e) {
      throw Exception('Gagal mengupdate profil: $e');
    }
  }

  // ==================== FOLLOW OPERATIONS ====================

  /// Memastikan profil pengguna ada di Firestore
  Future<void> _ensureUserProfileExists(String userId) async {
    try {
      final profileDoc = await _firestore
          .collection(_userProfilesCollection)
          .doc(userId)
          .get();

      if (!profileDoc.exists) {
        // Buat profil default jika tidak ada
        final user = FirebaseAuth.instance.currentUser;
        final defaultProfile = UserProfile(
          id: userId,
          name: user?.displayName ?? 'User',
          email: user?.email ?? '',
          bio: '',
          avatar: user?.photoURL,
          followersCount: 0,
          followingCount: 0,
          postsCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(_userProfilesCollection)
            .doc(userId)
            .set(defaultProfile.toFirestore());
      }
    } catch (e) {
      throw Exception('Gagal memastikan profil pengguna: $e');
    }
  }

  /// Follow pengguna lain
  Future<void> followUser(String targetUserId) async {
    try {
      if (currentUserId.isEmpty) {
        throw Exception('User tidak terautentikasi');
      }

      if (currentUserId == targetUserId) {
        throw Exception('Tidak dapat mengikuti diri sendiri');
      }

      // Cek apakah sudah mengikuti
      final isAlreadyFollowing = await isFollowingUser(targetUserId);
      if (isAlreadyFollowing) {
        throw Exception('Sudah mengikuti pengguna ini');
      }

      // Ensure both user profiles exist before creating follow relationship
      await _ensureUserProfileExists(currentUserId);
      await _ensureUserProfileExists(targetUserId);

      // Ambil nama pengguna untuk record follow
      final currentProfile = await getUserProfile(currentUserId);
      final targetProfile = await getUserProfile(targetUserId);

      final follow = UserFollow(
        id: '',
        followerId: currentUserId,
        followingId: targetUserId,
        followerName: currentProfile?.name ?? 'Unknown',
        followingName: targetProfile?.name ?? 'Unknown',
        createdAt: DateTime.now(),
        isActive: true,
      );

      final batch = _firestore.batch();

      // Tambah record follow
      final followRef = _firestore.collection(_userFollowsCollection).doc();
      batch.set(followRef, follow.toFirestore());

      // Update counter follower (target user)
      final targetProfileRef = _firestore.collection(_userProfilesCollection).doc(targetUserId);
      batch.update(targetProfileRef, {
        'followersCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });

      // Update counter following (current user)
      final currentProfileRef = _firestore.collection(_userProfilesCollection).doc(currentUserId);
      batch.update(currentProfileRef, {
        'followingCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal follow pengguna: $e');
    }
  }

  /// Unfollow pengguna
  Future<void> unfollowUser(String targetUserId) async {
    try {
      if (currentUserId.isEmpty) {
        throw Exception('User tidak terautentikasi');
      }

      // Cari record follow
      final followQuery = await _firestore
          .collection(_userFollowsCollection)
          .where('followerId', isEqualTo: currentUserId)
          .where('followingId', isEqualTo: targetUserId)
          .get();

      if (followQuery.docs.isEmpty) {
        throw Exception('Tidak mengikuti pengguna ini');
      }

      // Ensure both user profiles exist before updating them
      await _ensureUserProfileExists(currentUserId);
      await _ensureUserProfileExists(targetUserId);

      final batch = _firestore.batch();

      // Hapus record follow
      for (final doc in followQuery.docs) {
        batch.delete(doc.reference);
      }

      // Update counter follower (target user)
      final targetProfileRef = _firestore.collection(_userProfilesCollection).doc(targetUserId);
      batch.update(targetProfileRef, {
        'followersCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });

      // Update counter following (current user)
      final currentProfileRef = _firestore.collection(_userProfilesCollection).doc(currentUserId);
      batch.update(currentProfileRef, {
        'followingCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal unfollow pengguna: $e');
    }
  }

  /// Cek apakah user sedang mengikuti pengguna lain
  Future<bool> isFollowingUser(String targetUserId) async {
    try {
      if (currentUserId.isEmpty) return false;

      final followQuery = await _firestore
          .collection(_userFollowsCollection)
          .where('followerId', isEqualTo: currentUserId)
          .where('followingId', isEqualTo: targetUserId)
          .get();

      return followQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Alias untuk isFollowingUser - cek status following
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final followQuery = await _firestore
          .collection(_userFollowsCollection)
          .where('followerId', isEqualTo: followerId)
          .where('followingId', isEqualTo: followingId)
          .get();

      return followQuery.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mengambil daftar followers
  Stream<List<UserFollow>> getFollowers(String userId) {
    try {
      return _firestore
          .collection(_userFollowsCollection)
          .where('followingId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => UserFollow.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.value(<UserFollow>[]);
    }
  }

  /// Mengambil daftar following
  Stream<List<UserFollow>> getFollowing(String userId) {
    try {
      return _firestore
          .collection(_userFollowsCollection)
          .where('followerId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => UserFollow.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.value(<UserFollow>[]);
    }
  }

  /// Mencari pengguna berdasarkan nama
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      // Firebase tidak mendukung full-text search yang baik
      // Untuk implementasi yang lebih baik, gunakan Algolia
      final querySnapshot = await _firestore
          .collection(_userProfilesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .limit(20)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((user) => 
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();

      return users;
    } catch (e) {
      throw Exception('Gagal mencari pengguna: $e');
    }
  }

  /// Update jumlah post pengguna
  Future<void> updateUserPostCount(String userId, int increment) async {
    try {
      await _firestore
          .collection(_userProfilesCollection)
          .doc(userId)
          .update({
        'postsCount': FieldValue.increment(increment),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      // Ignore error untuk menghindari crash
    }
  }

  /// Mengambil komentar berdasarkan user ID
  Stream<List<PostComment>> getCommentsByUser(String userId) {
    try {
      if (kDebugMode) {
        print('DEBUG: Fetching comments for userId: $userId');
      }
      
      return _firestore
          .collection(_commentsCollection)
          .where('authorId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        if (kDebugMode) {
          print('DEBUG: Found ${snapshot.docs.length} comments for user $userId');
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final content = data['content'] ?? '';
            final contentPreview = content.length > 20 ? '${content.substring(0, 20)}...' : content;
            print('DEBUG: Comment - ID: ${doc.id}, authorId: ${data['authorId']}, content: "$contentPreview", isDeleted: ${data['isDeleted']}');
          }
        }
        
        final comments = snapshot.docs
            .map((doc) {
              try {
                return PostComment.fromFirestore(doc);
              } catch (e) {
                if (kDebugMode) {
                  print('DEBUG: Error parsing comment ${doc.id}: $e');
                  print('DEBUG: Comment data: ${doc.data()}');
                }
                return null;
              }
            })
            .where((comment) => comment != null)
            .cast<PostComment>()
            .toList();
            
        if (kDebugMode) {
          print('DEBUG: Successfully parsed ${comments.length} comments');
        }
        
        return comments;
      });
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error fetching comments for user $userId: $e');
      }
      throw Exception('Gagal mengambil komentar pengguna: $e');
    }
  }
}