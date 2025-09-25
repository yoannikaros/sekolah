import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/mading_models.dart';

class MadingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mading Post CRUD Operations
  Future<String?> createMadingPost(MadingPost post) async {
    try {
      final postData = {
        'title': post.title,
        'description': post.description,
        'imageUrl': post.imageUrl,
        'documentUrl': post.documentUrl,
        'authorId': post.authorId,
        'authorName': post.authorName,
        'schoolId': post.schoolId,
        'classCode': post.classCode,
        'type': post.type.name,
        'status': post.status.name,
        'createdAt': post.createdAt.toIso8601String(),
        'updatedAt': post.updatedAt?.toIso8601String(),
        'dueDate': post.dueDate?.toIso8601String(),
        'comments': post.comments.map((comment) => comment.toJson()).toList(),
        'likesCount': post.likesCount,
        'tags': post.tags,
        'isPublished': post.isPublished,
        'teacherId': post.teacherId,
      };
      
      final docRef = await _firestore.collection('mading_posts').add(postData);
      if (kDebugMode) {
        print('Mading post created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating mading post: $e');
      }
      return null;
    }
  }

  Future<bool> updateMadingPost(String id, MadingPost post) async {
    try {
      final postData = {
        'title': post.title,
        'description': post.description,
        'imageUrl': post.imageUrl,
        'documentUrl': post.documentUrl,
        'authorId': post.authorId,
        'authorName': post.authorName,
        'schoolId': post.schoolId,
        'classCode': post.classCode,
        'type': post.type.name,
        'status': post.status.name,
        'updatedAt': DateTime.now().toIso8601String(),
        'dueDate': post.dueDate?.toIso8601String(),
        'comments': post.comments.map((comment) => comment.toJson()).toList(),
        'likesCount': post.likesCount,
        'tags': post.tags,
        'isPublished': post.isPublished,
        'teacherId': post.teacherId,
      };
      
      await _firestore.collection('mading_posts').doc(id).update(postData);
      if (kDebugMode) {
        print('Mading post updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating mading post: $e');
      }
      return false;
    }
  }

  Future<bool> deleteMadingPost(String id) async {
    try {
      await _firestore.collection('mading_posts').doc(id).delete();
      if (kDebugMode) {
        print('Mading post deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting mading post: $e');
      }
      return false;
    }
  }

  Future<MadingPost?> getMadingPost(String id) async {
    try {
      final doc = await _firestore.collection('mading_posts').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return _mapToMadingPost(doc.id, data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting mading post: $e');
      }
      return null;
    }
  }

  Future<List<MadingPost>> getAllMadingPosts({MadingFilter? filter}) async {
    try {
      Query query = _firestore.collection('mading_posts');
      
      // Apply filters
      if (filter != null) {
        if (filter.schoolId != null) {
          query = query.where('schoolId', isEqualTo: filter.schoolId);
        }
        if (filter.classCode != null) {
          query = query.where('classCode', isEqualTo: filter.classCode);
        }
        if (filter.type != null) {
          query = query.where('type', isEqualTo: filter.type!.name);
        }
        if (filter.status != null) {
          query = query.where('status', isEqualTo: filter.status!.name);
        }
        if (filter.authorId != null) {
          query = query.where('authorId', isEqualTo: filter.authorId);
        }
        if (filter.teacherId != null) {
          query = query.where('teacherId', isEqualTo: filter.teacherId);
        }
        if (filter.isPublished != null) {
          query = query.where('isPublished', isEqualTo: filter.isPublished);
        }
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();
      final posts = <MadingPost>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final post = _mapToMadingPost(doc.id, data);
        if (post != null) {
          // Apply date filters (Firestore doesn't support range queries with other filters easily)
          if (filter?.startDate != null || filter?.endDate != null) {
            final createdAt = post.createdAt;
            if (filter!.startDate != null && createdAt.isBefore(filter.startDate!)) {
              continue;
            }
            if (filter.endDate != null && createdAt.isAfter(filter.endDate!)) {
              continue;
            }
          }
          
          // Apply tags filter
          if (filter?.tags != null && filter!.tags!.isNotEmpty) {
            bool hasMatchingTag = false;
            for (final tag in filter.tags!) {
              if (post.tags.contains(tag)) {
                hasMatchingTag = true;
                break;
              }
            }
            if (!hasMatchingTag) continue;
          }
          
          posts.add(post);
        }
      }
      
      return posts;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting mading posts: $e');
      }
      return [];
    }
  }

  Future<List<MadingPost>> getMadingPostsBySchool(String schoolId) async {
    return getAllMadingPosts(filter: MadingFilter(schoolId: schoolId));
  }

  Future<List<MadingPost>> getMadingPostsByClass(String classCode) async {
    return getAllMadingPosts(filter: MadingFilter(classCode: classCode));
  }

  Future<List<MadingPost>> getAssignmentsByTeacher(String teacherId) async {
    return getAllMadingPosts(
      filter: MadingFilter(
        teacherId: teacherId,
        type: MadingType.assignment,
      ),
    );
  }

  Future<List<MadingPost>> getStudentWorks(String schoolId) async {
    return getAllMadingPosts(
      filter: MadingFilter(
        schoolId: schoolId,
        type: MadingType.studentWork,
      ),
    );
  }

  // Comment CRUD Operations
  Future<String?> addComment(MadingComment comment) async {
    try {
      final commentData = {
        'postId': comment.postId,
        'authorId': comment.authorId,
        'authorName': comment.authorName,
        'content': comment.content,
        'createdAt': comment.createdAt.toIso8601String(),
        'isApproved': comment.isApproved,
        'moderatorId': comment.moderatorId,
        'approvedAt': comment.approvedAt?.toIso8601String(),
      };
      
      final docRef = await _firestore.collection('mading_comments').add(commentData);
      
      // Update the post's comments array
      await _updatePostComments(comment.postId);
      
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

  Future<bool> approveComment(String commentId, String moderatorId) async {
    try {
      await _firestore.collection('mading_comments').doc(commentId).update({
        'isApproved': true,
        'moderatorId': moderatorId,
        'approvedAt': DateTime.now().toIso8601String(),
      });
      
      // Get comment to update post
      final commentDoc = await _firestore.collection('mading_comments').doc(commentId).get();
      if (commentDoc.exists) {
        final commentData = commentDoc.data()!;
        await _updatePostComments(commentData['postId']);
      }
      
      if (kDebugMode) {
        print('Comment approved successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error approving comment: $e');
      }
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      // Get comment to update post later
      final commentDoc = await _firestore.collection('mading_comments').doc(commentId).get();
      String? postId;
      if (commentDoc.exists) {
        postId = commentDoc.data()!['postId'];
      }
      
      await _firestore.collection('mading_comments').doc(commentId).delete();
      
      // Update post comments
      if (postId != null) {
        await _updatePostComments(postId);
      }
      
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

  Future<List<MadingComment>> getCommentsByPost(String postId) async {
    try {
      final querySnapshot = await _firestore
          .collection('mading_comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .get();
      
      final comments = <MadingComment>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final comment = _mapToMadingComment(doc.id, data);
        if (comment != null) {
          comments.add(comment);
        }
      }
      
      return comments;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting comments: $e');
      }
      return [];
    }
  }

  Future<List<MadingComment>> getPendingComments() async {
    try {
      final querySnapshot = await _firestore
          .collection('mading_comments')
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      
      final comments = <MadingComment>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final comment = _mapToMadingComment(doc.id, data);
        if (comment != null) {
          comments.add(comment);
        }
      }
      
      return comments;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting pending comments: $e');
      }
      return [];
    }
  }

  // Utility Methods
  Future<bool> publishPost(String postId) async {
    try {
      await _firestore.collection('mading_posts').doc(postId).update({
        'isPublished': true,
        'status': MadingStatus.published.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error publishing post: $e');
      }
      return false;
    }
  }

  Future<bool> archivePost(String postId) async {
    try {
      await _firestore.collection('mading_posts').doc(postId).update({
        'status': MadingStatus.archived.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error archiving post: $e');
      }
      return false;
    }
  }

  Future<bool> likePost(String postId, String userId) async {
    try {
      // Check if user already liked
      final likeDoc = await _firestore
          .collection('mading_likes')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();
      
      if (likeDoc.docs.isEmpty) {
        // Add like
        await _firestore.collection('mading_likes').add({
          'postId': postId,
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
        });
        
        // Update likes count
        await _updateLikesCount(postId);
        return true;
      }
      return false; // Already liked
    } catch (e) {
      if (kDebugMode) {
        print('Error liking post: $e');
      }
      return false;
    }
  }

  Future<bool> unlikePost(String postId, String userId) async {
    try {
      final likeQuery = await _firestore
          .collection('mading_likes')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in likeQuery.docs) {
        await doc.reference.delete();
      }
      
      // Update likes count
      await _updateLikesCount(postId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unliking post: $e');
      }
      return false;
    }
  }

  // Private helper methods
  Future<void> _updatePostComments(String postId) async {
    try {
      final comments = await getCommentsByPost(postId);
      await _firestore.collection('mading_posts').doc(postId).update({
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating post comments: $e');
      }
    }
  }

  Future<void> _updateLikesCount(String postId) async {
    try {
      final likesQuery = await _firestore
          .collection('mading_likes')
          .where('postId', isEqualTo: postId)
          .get();
      
      await _firestore.collection('mading_posts').doc(postId).update({
        'likesCount': likesQuery.docs.length,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating likes count: $e');
      }
    }
  }

  MadingPost? _mapToMadingPost(String id, Map<String, dynamic> data) {
    try {
      return MadingPost(
        id: id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'],
        documentUrl: data['documentUrl'],
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'] ?? '',
        schoolId: data['schoolId'] ?? '',
        classCode: data['classCode'] ?? '',
        type: MadingType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => MadingType.studentWork,
        ),
        status: MadingStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => MadingStatus.draft,
        ),
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
        dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
        comments: (data['comments'] as List<dynamic>?)
                ?.map((commentData) => MadingComment.fromJson(commentData))
                .toList() ??
            [],
        likesCount: data['likesCount'] ?? 0,
        tags: List<String>.from(data['tags'] ?? []),
        isPublished: data['isPublished'] ?? false,
        teacherId: data['teacherId'],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error mapping mading post: $e');
      }
      return null;
    }
  }

  MadingComment? _mapToMadingComment(String id, Map<String, dynamic> data) {
    try {
      return MadingComment(
        id: id,
        postId: data['postId'] ?? '',
        authorId: data['authorId'] ?? '',
        authorName: data['authorName'] ?? '',
        content: data['content'] ?? '',
        createdAt: DateTime.parse(data['createdAt']),
        isApproved: data['isApproved'] ?? false,
        moderatorId: data['moderatorId'],
        approvedAt: data['approvedAt'] != null ? DateTime.parse(data['approvedAt']) : null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error mapping mading comment: $e');
      }
      return null;
    }
  }
}