import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/material_models.dart';

class MaterialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Material CRUD Operations
  Future<String?> createMaterial(Material material) async {
    try {
      final materialData = {
        'subjectId': material.subjectId,
        'classCodeId': material.classCodeId,
        'teacherId': material.teacherId,
        'title': material.title,
        'content': material.content,
        'youtubeEmbedUrl': material.youtubeEmbedUrl,
        'comments': material.comments.map((comment) => comment.toJson()).toList(),
        'createdBy': material.createdBy,
        'createdAt': material.createdAt.toIso8601String(),
        'updatedAt': material.updatedAt.toIso8601String(),
        'isActive': material.isActive,
        'isPublished': material.isPublished,
        'publishedAt': material.publishedAt?.toIso8601String(),
        'sortOrder': material.sortOrder,
        'tags': material.tags,
        'thumbnailUrl': material.thumbnailUrl,
      };
      
      final docRef = await _firestore.collection('materials').add(materialData);
      if (kDebugMode) {
        print('Material created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating material: $e');
      }
      return null;
    }
  }

  Future<bool> updateMaterial(String id, Material material) async {
    try {
      final materialData = {
        'subjectId': material.subjectId,
        'classCodeId': material.classCodeId,
        'teacherId': material.teacherId,
        'title': material.title,
        'content': material.content,
        'youtubeEmbedUrl': material.youtubeEmbedUrl,
        'comments': material.comments.map((comment) => comment.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': material.isActive,
        'isPublished': material.isPublished,
        'publishedAt': material.publishedAt?.toIso8601String(),
        'sortOrder': material.sortOrder,
        'tags': material.tags,
        'thumbnailUrl': material.thumbnailUrl,
      };
      
      await _firestore.collection('materials').doc(id).update(materialData);
      if (kDebugMode) {
        print('Material updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating material: $e');
      }
      return false;
    }
  }

  Future<bool> deleteMaterial(String id) async {
    try {
      await _firestore.collection('materials').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Material soft deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting material: $e');
      }
      return false;
    }
  }

  Future<List<Material>> getAllMaterials({MaterialFilter? filter}) async {
    try {
      if (kDebugMode) {
        print('Fetching materials from Firebase...');
      }
      
      Query query = _firestore.collection('materials');
      
      // Apply filters
      if (filter != null) {
        if (filter.subjectId != null) {
          query = query.where('subjectId', isEqualTo: filter.subjectId);
        }
        if (filter.classCodeId != null) {
          query = query.where('classCodeId', isEqualTo: filter.classCodeId);
        }
        if (filter.teacherId != null) {
          query = query.where('teacherId', isEqualTo: filter.teacherId);
        }
        if (filter.isPublished != null) {
          query = query.where('isPublished', isEqualTo: filter.isPublished);
        }
        if (filter.isActive != null) {
          query = query.where('isActive', isEqualTo: filter.isActive);
        }
      }
      
      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();

      if (kDebugMode) {
        print('Total materials found: ${querySnapshot.docs.length}');
      }

      final materials = <Material>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          final material = Material.fromJson(data);
          
          // Apply text search filter if provided
          if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
            final searchQuery = filter.searchQuery!.toLowerCase();
            if (material.title.toLowerCase().contains(searchQuery) ||
                material.content.toLowerCase().contains(searchQuery) ||
                material.tags.any((tag) => tag.toLowerCase().contains(searchQuery))) {
              materials.add(material);
            }
          } else {
            materials.add(material);
          }
          
          if (kDebugMode) {
            print('Successfully parsed material: ${material.title} (ID: ${material.id})');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing material document ${doc.id}: $e');
            print('Document data: ${doc.data()}');
          }
        }
      }

      if (kDebugMode) {
        print('Successfully parsed ${materials.length} materials');
      }

      return materials;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching materials: $e');
      }
      return [];
    }
  }

  Future<Material?> getMaterialById(String id) async {
    try {
      final doc = await _firestore.collection('materials').doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Material.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting material: $e');
      }
      return null;
    }
  }

  Future<bool> publishMaterial(String id) async {
    try {
      await _firestore.collection('materials').doc(id).update({
        'isPublished': true,
        'publishedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Material published successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error publishing material: $e');
      }
      return false;
    }
  }

  Future<bool> unpublishMaterial(String id) async {
    try {
      await _firestore.collection('materials').doc(id).update({
        'isPublished': false,
        'publishedAt': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Material unpublished successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unpublishing material: $e');
      }
      return false;
    }
  }

  // Material Comment CRUD Operations
  Future<String?> addComment(MaterialComment comment) async {
    try {
      final commentData = comment.toJson();
      commentData.remove('id'); // Remove id as it will be auto-generated
      
      final docRef = await _firestore.collection('material_comments').add(commentData);
      
      // Also update the material document to include this comment
      await _updateMaterialComments(comment.materialId);
      
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

  Future<bool> updateComment(String id, MaterialComment comment) async {
    try {
      final commentData = comment.toJson();
      commentData['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore.collection('material_comments').doc(id).update(commentData);
      
      // Update the material document comments
      await _updateMaterialComments(comment.materialId);
      
      if (kDebugMode) {
        print('Comment updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating comment: $e');
      }
      return false;
    }
  }

  Future<bool> deleteComment(String id, String materialId) async {
    try {
      await _firestore.collection('material_comments').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Update the material document comments
      await _updateMaterialComments(materialId);
      
      if (kDebugMode) {
        print('Comment deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting comment: $e');
      }
      return false;
    }
  }

  Future<List<MaterialComment>> getCommentsByMaterialId(String materialId) async {
    try {
      final querySnapshot = await _firestore
          .collection('material_comments')
          .where('materialId', isEqualTo: materialId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();

      final comments = <MaterialComment>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final comment = MaterialComment.fromJson(data);
          comments.add(comment);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing comment document ${doc.id}: $e');
          }
        }
      }

      return comments;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching comments: $e');
      }
      return [];
    }
  }

  // Helper method to update material comments
  Future<void> _updateMaterialComments(String materialId) async {
    try {
      final comments = await getCommentsByMaterialId(materialId);
      await _firestore.collection('materials').doc(materialId).update({
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating material comments: $e');
      }
    }
  }

  // Utility methods for getting related data
  Future<List<Material>> getMaterialsBySubject(String subjectId) async {
    return getAllMaterials(filter: MaterialFilter(subjectId: subjectId, isActive: true));
  }

  Future<List<Material>> getMaterialsByClassCode(String classCodeId) async {
    return getAllMaterials(filter: MaterialFilter(classCodeId: classCodeId, isActive: true));
  }

  Future<List<Material>> getMaterialsByTeacher(String teacherId) async {
    return getAllMaterials(filter: MaterialFilter(teacherId: teacherId, isActive: true));
  }

  Future<List<Material>> getPublishedMaterials({String? subjectId, String? classCodeId}) async {
    return getAllMaterials(filter: MaterialFilter(
      subjectId: subjectId,
      classCodeId: classCodeId,
      isPublished: true,
      isActive: true,
    ));
  }
}