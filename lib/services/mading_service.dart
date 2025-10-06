import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mading_models.dart';

class MadingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Collections
  CollectionReference get _madingCollection => _firestore.collection('mading_posts');
  CollectionReference get _commentsCollection => _firestore.collection('mading_comments');
  CollectionReference get _subjectsCollection => _firestore.collection('subjects');

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String postId) async {
    try {
      String fileName = 'mading_images/$postId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Create new mading post
  Future<String> createMadingPost({
    required File imageFile,
    required String schoolId,
    String? subjectId,
    required String studentId,
    required String studentName,
    required String studentClass,
    required String description,
  }) async {
    try {
      // Create document reference to get ID
      DocumentReference docRef = _madingCollection.doc();
      String postId = docRef.id;
      
      // Upload image
      String imageUrl = await uploadImage(imageFile, postId);
      
      // Create mading post
      MadingPost post = MadingPost(
        id: postId,
        imageUrl: imageUrl,
        schoolId: schoolId,
        subjectId: subjectId,
        studentId: studentId,
        studentName: studentName,
        studentClass: studentClass,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isApproved: true, // Auto-approve student posts
      );
      
      await docRef.set(post.toFirestore());
      return postId;
    } catch (e) {
      throw Exception('Failed to create mading post: $e');
    }
  }

  // Get mading posts by school
  Stream<List<MadingPost>> getMadingPostsBySchool(String schoolId) {
    return _firestore
        .collectionGroup('mading_posts')
        .where('schoolId', isEqualTo: schoolId)
        // .where('isApproved', isEqualTo: true) // Temporarily commented out
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<MadingPost> posts = [];
      for (var doc in snapshot.docs) {
        try {
          posts.add(MadingPost.fromFirestore(doc));
        } catch (e) {
          // Skip invalid documents
        }
      }
      return posts;
    });
  }

  Stream<List<MadingPost>> getMadingPostsBySubject(String schoolId, String subjectId) {
    return _firestore
        .collectionGroup('mading_posts')
        .where('schoolId', isEqualTo: schoolId)
        .where('subjectId', isEqualTo: subjectId)
        // .where('isApproved', isEqualTo: true) // Temporarily commented out
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<MadingPost> posts = [];
      for (var doc in snapshot.docs) {
        try {
          posts.add(MadingPost.fromFirestore(doc));
        } catch (e) {
          // Skip invalid documents
        }
      }
      return posts;
    });
  }

  Stream<List<Subject>> getSubjectsBySchool(String schoolId) {
    return _firestore
        .collection('subjects')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Subject.fromFirestore(doc);
      }).toList();
    });
  }

  // Get mading posts by student
  Stream<List<MadingPost>> getMadingPostsByStudent(String studentId) {
    return _madingCollection
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MadingPost.fromFirestore(doc))
            .toList());
  }

  // Get pending posts for approval
  Stream<List<MadingPost>> getPendingPosts(String schoolId) {
    return _madingCollection
        .where('schoolId', isEqualTo: schoolId)
        .where('isApproved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MadingPost.fromFirestore(doc))
            .toList());
  }

  // Approve post
  Future<void> approvePost(String postId, String teacherId) async {
    try {
      await _madingCollection.doc(postId).update({
        'isApproved': true,
        'approvedBy': teacherId,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to approve post: $e');
    }
  }

  // Like/Unlike post
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      DocumentSnapshot doc = await _madingCollection.doc(postId).get();
      MadingPost post = MadingPost.fromFirestore(doc);
      
      List<String> likedBy = List.from(post.likedBy);
      int likesCount = post.likesCount;
      
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        likesCount--;
      } else {
        likedBy.add(userId);
        likesCount++;
      }
      
      await _madingCollection.doc(postId).update({
        'likedBy': likedBy,
        'likesCount': likesCount,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      // Get post data to delete image from storage
      DocumentSnapshot doc = await _madingCollection.doc(postId).get();
      if (doc.exists) {
        MadingPost post = MadingPost.fromFirestore(doc);
        
        // Delete image from storage
        try {
          await _storage.refFromURL(post.imageUrl).delete();
        } catch (e) {
          debugPrint('Failed to delete image from storage: $e');
        }
        
        // Delete all comments for this post
        QuerySnapshot comments = await _commentsCollection
            .where('postId', isEqualTo: postId)
            .get();
        
        WriteBatch batch = _firestore.batch();
        for (DocumentSnapshot comment in comments.docs) {
          batch.delete(comment.reference);
        }
        
        // Delete the post
        batch.delete(_madingCollection.doc(postId));
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Add comment
  Future<String> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userRole,
    required String comment,
    String? parentCommentId,
  }) async {
    try {
      DocumentReference docRef = _commentsCollection.doc();
      String commentId = docRef.id;
      
      MadingComment madingComment = MadingComment(
        id: commentId,
        postId: postId,
        userId: userId,
        userName: userName,
        userRole: userRole,
        comment: comment,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );
      
      await docRef.set(madingComment.toFirestore());
      
      // Update comments count in post
      await _updateCommentsCount(postId);
      
      return commentId;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get comments for a post
  Stream<List<MadingComment>> getComments(String postId) {
    return _commentsCollection
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MadingComment.fromFirestore(doc))
            .toList());
  }

  // Like/Unlike comment
  Future<void> toggleLikeComment(String commentId, String userId) async {
    try {
      DocumentSnapshot doc = await _commentsCollection.doc(commentId).get();
      MadingComment comment = MadingComment.fromFirestore(doc);
      
      List<String> likedBy = List.from(comment.likedBy);
      int likesCount = comment.likesCount;
      
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        likesCount--;
      } else {
        likedBy.add(userId);
        likesCount++;
      }
      
      await _commentsCollection.doc(commentId).update({
        'likedBy': likedBy,
        'likesCount': likesCount,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      DocumentSnapshot doc = await _commentsCollection.doc(commentId).get();
      if (doc.exists) {
        MadingComment comment = MadingComment.fromFirestore(doc);
        
        // Delete replies to this comment
        QuerySnapshot replies = await _commentsCollection
            .where('parentCommentId', isEqualTo: commentId)
            .get();
        
        WriteBatch batch = _firestore.batch();
        for (DocumentSnapshot reply in replies.docs) {
          batch.delete(reply.reference);
        }
        
        // Delete the comment
        batch.delete(_commentsCollection.doc(commentId));
        await batch.commit();
        
        // Update comments count
        await _updateCommentsCount(comment.postId);
      }
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Update comments count for a post
  Future<void> _updateCommentsCount(String postId) async {
    try {
      QuerySnapshot comments = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .get();
      
      await _madingCollection.doc(postId).update({
        'commentsCount': comments.docs.length,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Failed to update comments count: $e');
    }
  }

  // Subject management
  Future<String> createSubject({
    required String name,
    required String schoolId,
    String? description,
    String? color,
  }) async {
    try {
      DocumentReference docRef = _subjectsCollection.doc();
      String subjectId = docRef.id;
      
      Subject subject = Subject(
        id: subjectId,
        name: name,
        schoolId: schoolId,
        description: description,
        color: color,
      );
      
      await docRef.set(subject.toFirestore());
      return subjectId;
    } catch (e) {
      throw Exception('Failed to create subject: $e');
    }
  }

  // Get single post
  Future<MadingPost?> getPost(String postId) async {
    try {
      DocumentSnapshot doc = await _madingCollection.doc(postId).get();
      if (doc.exists) {
        return MadingPost.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get post: $e');
    }
  }

  // Update post
  Future<void> updatePost(String postId, {
    String? description,
    String? subjectId,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': Timestamp.now(),
      };
      
      if (description != null) updates['description'] = description;
      if (subjectId != null) updates['subjectId'] = subjectId;
      
      await _madingCollection.doc(postId).update(updates);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }
}