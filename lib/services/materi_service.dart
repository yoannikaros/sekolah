import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/materi_models.dart';

class MateriService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Materi CRUD Operations
  // Update createMateri to include schoolId
  Future<String?> createMateri(Materi materi) async {
    try {
      final materiData = {
        'judul': materi.judul,
        'description': materi.description,
        'teacherId': materi.teacherId,
        'subjectId': materi.subjectId,
        'schoolId': materi.schoolId,
        'classCodeIds': materi.classCodeIds,
        'createdAt': materi.createdAt.toIso8601String(),
        'updatedAt': materi.updatedAt.toIso8601String(),
        'isActive': materi.isActive,
        'sortOrder': materi.sortOrder,
        'imageUrl': materi.imageUrl,
        'attachments': materi.attachments,
      };
      
      final docRef = await _firestore.collection('materi').add(materiData);
      if (kDebugMode) {
        print('Materi created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating materi: $e');
      }
      return null;
    }
  }

  Future<bool> updateMateri(String id, Materi materi) async {
    try {
      final materiData = {
        'judul': materi.judul,
        'description': materi.description,
        'teacherId': materi.teacherId,
        'subjectId': materi.subjectId,
        'schoolId': materi.schoolId,
        'classCodeIds': materi.classCodeIds,
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': materi.isActive,
        'sortOrder': materi.sortOrder,
        'imageUrl': materi.imageUrl,
        'attachments': materi.attachments,
      };
      
      await _firestore.collection('materi').doc(id).update(materiData);
      if (kDebugMode) {
        print('Materi updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating materi: $e');
      }
      return false;
    }
  }

  Future<bool> deleteMateri(String id) async {
    try {
      await _firestore.collection('materi').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Materi soft deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting materi: $e');
      }
      return false;
    }
  }

  Future<List<Materi>> getAllMateri() async {
    try {
      if (kDebugMode) {
        print('Fetching all materi from Firebase...');
      }
      
      final querySnapshot = await _firestore
          .collection('materi')
          .where('isActive', isEqualTo: true)
          .get();

      if (kDebugMode) {
        print('Total materi documents: ${querySnapshot.docs.length}');
      }

      final materiList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Materi.fromJson(data);
      }).toList();

      // Sort after fetching to avoid index issues
      materiList.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        } else if (a.sortOrder != null) {
          return -1;
        } else if (b.sortOrder != null) {
          return 1;
        } else {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      return materiList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching materi: $e');
      }
      return [];
    }
  }

  Future<List<Materi>> getMateriByTeacher(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('materi')
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .get();

      final materiList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Materi.fromJson(data);
      }).toList();

      // Sort after fetching to avoid index issues
      materiList.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        } else if (a.sortOrder != null) {
          return -1;
        } else if (b.sortOrder != null) {
          return 1;
        } else {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      return materiList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching materi by teacher: $e');
      }
      return [];
    }
  }

  Future<List<Materi>> getMateriBySubject(String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('materi')
          .where('subjectId', isEqualTo: subjectId)
          .where('isActive', isEqualTo: true)
          .get();

      final materiList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Materi.fromJson(data);
      }).toList();

      // Sort after fetching to avoid index issues
      materiList.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        } else if (a.sortOrder != null) {
          return -1;
        } else if (b.sortOrder != null) {
          return 1;
        } else {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      return materiList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching materi by subject: $e');
      }
      return [];
    }
  }

  // Add new method to get materi by school
  Future<List<Materi>> getMateriBySchool(String schoolId) async {
    try {
      if (kDebugMode) {
        print('=== Start MateriService.getMateriBySchool Debug ===');
        print('Fetching materi for school ID: $schoolId');
      }

      final querySnapshot = await _firestore
          .collection('materi')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .get();

      if (kDebugMode) {
        print('Found ${querySnapshot.docs.length} documents');
      }

      final materiList = <Materi>[];
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final materi = Materi.fromJson(data);
          materiList.add(materi);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing document ${doc.id}: $e');
          }
        }
      }

      // Sort by creation date (newest first)
      materiList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        print('Returning ${materiList.length} materials after sorting');
        print('=== End MateriService.getMateriBySchool Debug ===');
      }

      return materiList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching materi by school: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  Future<List<Materi>> getMateriByClassCode(String classCodeId) async {
    try {
      if (kDebugMode) {
        print('=== MateriService.getMateriByClassCode Debug ===');
        print('Searching for materials with classCodeId: $classCodeId');
      }

      // First, let's check all materi documents to see what classCodeIds exist
      if (kDebugMode) {
        print('--- Checking ALL materi documents for debugging ---');
        final allMateriSnapshot = await _firestore
            .collection('materi')
            .where('isActive', isEqualTo: true)
            .get();
        
        print('Total active materi documents: ${allMateriSnapshot.docs.length}');
        for (var doc in allMateriSnapshot.docs) {
          final data = doc.data();
          print('Materi ${doc.id}: classCodeIds=${data['classCodeIds']}, subjectId=${data['subjectId']}, judul=${data['judul']}');
        }
        print('--- End ALL materi documents check ---');
      }

      final querySnapshot = await _firestore
          .collection('materi')
          .where('classCodeIds', arrayContains: classCodeId)
          .where('isActive', isEqualTo: true)
          .get();

      if (kDebugMode) {
        print('Raw query returned ${querySnapshot.docs.length} documents');
      }

      final materiList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (kDebugMode) {
          print('Document ${doc.id}: $data');
        }
        
        return Materi.fromJson(data);
      }).toList();

      // Sort after fetching to avoid index issues
      materiList.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        } else if (a.sortOrder != null) {
          return -1;
        } else if (b.sortOrder != null) {
          return 1;
        } else {
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      if (kDebugMode) {
        print('Returning ${materiList.length} materials after sorting');
        print('=== End MateriService.getMateriByClassCode Debug ===');
      }

      return materiList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching materi by class code: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  Future<Materi?> getMateriById(String id) async {
    try {
      final doc = await _firestore.collection('materi').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Materi.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching materi by ID: $e');
      }
      return null;
    }
  }

  // Detail Materi CRUD Operations
  Future<String?> createDetailMateri(DetailMateri detailMateri) async {
    try {
      final detailData = {
        'materiId': detailMateri.materiId,
        'schoolId': detailMateri.schoolId,
        'classCodeId': detailMateri.classCodeId,
        'judul': detailMateri.judul,
        'paragrafMateri': detailMateri.paragrafMateri,
        'embedYoutube': detailMateri.embedYoutube,
        'createdAt': detailMateri.createdAt.toIso8601String(),
        'updatedAt': detailMateri.updatedAt.toIso8601String(),
        'isActive': detailMateri.isActive,
        'sortOrder': detailMateri.sortOrder,
        'attachments': detailMateri.attachments,
        'imageUrl': detailMateri.imageUrl,
      };
      
      final docRef = await _firestore.collection('detail_materi').add(detailData);
      if (kDebugMode) {
        print('Detail Materi created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating detail materi: $e');
      }
      return null;
    }
  }

  Future<bool> updateDetailMateri(String id, DetailMateri detailMateri) async {
    try {
      final detailData = {
        'materiId': detailMateri.materiId,
        'schoolId': detailMateri.schoolId,
        'classCodeId': detailMateri.classCodeId,
        'judul': detailMateri.judul,
        'paragrafMateri': detailMateri.paragrafMateri,
        'embedYoutube': detailMateri.embedYoutube,
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': detailMateri.isActive,
        'sortOrder': detailMateri.sortOrder,
        'attachments': detailMateri.attachments,
        'imageUrl': detailMateri.imageUrl,
      };
      
      await _firestore.collection('detail_materi').doc(id).update(detailData);
      if (kDebugMode) {
        print('Detail Materi updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating detail materi: $e');
      }
      return false;
    }
  }

  Future<bool> deleteDetailMateri(String id) async {
    try {
      await _firestore.collection('detail_materi').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Detail Materi soft deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting detail materi: $e');
      }
      return false;
    }
  }

  Future<List<DetailMateri>> getDetailMateriByMateriId(String materiId) async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_materi')
          .where('materiId', isEqualTo: materiId)
          .where('isActive', isEqualTo: true)
          .get();

      final detailList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DetailMateri.fromJson(data);
      }).toList();

      // Sort after fetching to avoid index issues
      detailList.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        } else if (a.sortOrder != null) {
          return -1;
        } else if (b.sortOrder != null) {
          return 1;
        } else {
          return a.createdAt.compareTo(b.createdAt);
        }
      });

      return detailList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching detail materi: $e');
      }
      return [];
    }
  }

  // Add new method to get detail materi by school and class code
  Future<List<DetailMateri>> getDetailMateriBySchoolAndClassCode(String schoolId, String classCodeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_materi')
          .where('schoolId', isEqualTo: schoolId)
          .where('classCodeId', isEqualTo: classCodeId)
          .where('isActive', isEqualTo: true)
          .get();

      final detailList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DetailMateri.fromJson(data);
      }).toList();

      // Sort after fetching to avoid index issues
      detailList.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        } else if (a.sortOrder != null) {
          return -1;
        } else if (b.sortOrder != null) {
          return 1;
        } else {
          return a.createdAt.compareTo(b.createdAt);
        }
      });

      return detailList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching detail materi by school and class code: $e');
      }
      return [];
    }
  }

  // Add new method to get detail materi by materi, school and class code
  Future<List<DetailMateri>> getDetailMateriByMateriSchoolAndClassCode(String materiId, String schoolId, String classCodeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_materi')
          .where('materiId', isEqualTo: materiId)
          .where('schoolId', isEqualTo: schoolId)
          .where('classCodeId', isEqualTo: classCodeId)
          .where('isActive', isEqualTo: true)
          .get();

      final detailList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return DetailMateri.fromJson(data);
      }).toList();

      // Sort after fetching to avoid index issues
      detailList.sort((a, b) {
        if (a.sortOrder != null && b.sortOrder != null) {
          return a.sortOrder!.compareTo(b.sortOrder!);
        } else if (a.sortOrder != null) {
          return -1;
        } else if (b.sortOrder != null) {
          return 1;
        } else {
          return a.createdAt.compareTo(b.createdAt);
        }
      });

      return detailList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching detail materi by materi, school and class code: $e');
      }
      return [];
    }
  }

  Future<DetailMateri?> getDetailMateriById(String id) async {
    try {
      final doc = await _firestore.collection('detail_materi').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return DetailMateri.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching detail materi by ID: $e');
      }
      return null;
    }
  }

  // Helper methods untuk mendapatkan data relasi
  Future<MateriWithDetails?> getMateriWithDetails(String materiId) async {
    try {
      final materi = await getMateriById(materiId);
      if (materi == null) return null;

      final details = await getDetailMateriByMateriId(materiId);
      
      // Get teacher name
      String teacherName = 'Unknown Teacher';
      try {
        final teacherDoc = await _firestore.collection('teachers').doc(materi.teacherId).get();
        if (teacherDoc.exists) {
          teacherName = teacherDoc.data()?['name'] ?? 'Unknown Teacher';
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching teacher name: $e');
        }
      }

      // Get subject name
      String subjectName = 'Unknown Subject';
      try {
        final subjectDoc = await _firestore.collection('subjects').doc(materi.subjectId).get();
        if (subjectDoc.exists) {
          subjectName = subjectDoc.data()?['name'] ?? 'Unknown Subject';
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching subject name: $e');
        }
      }

      // Get class code names
      List<String> classCodeNames = [];
      for (String classCodeId in materi.classCodeIds) {
        try {
          final classCodeDoc = await _firestore.collection('class_codes').doc(classCodeId).get();
          if (classCodeDoc.exists) {
            final name = classCodeDoc.data()?['name'] ?? 'Unknown Class';
            classCodeNames.add(name);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching class code name: $e');
          }
          classCodeNames.add('Unknown Class');
        }
      }

      return MateriWithDetails(
        materi: materi,
        teacherName: teacherName,
        subjectName: subjectName,
        classCodeNames: classCodeNames,
        details: details,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching materi with details: $e');
      }
      return null;
    }
  }

  // Batch operations
  Future<bool> deleteAllDetailMateriByMateriId(String materiId) async {
    try {
      final querySnapshot = await _firestore
          .collection('detail_materi')
          .where('materiId', isEqualTo: materiId)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      if (kDebugMode) {
        print('All detail materi for materi $materiId soft deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all detail materi: $e');
      }
      return false;
    }
  }

  // Search functionality
  Future<List<Materi>> searchMateri(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('materi')
          .where('isActive', isEqualTo: true)
          .get();

      final materiList = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Materi.fromJson(data);
          })
          .where((materi) =>
              materi.judul.toLowerCase().contains(query.toLowerCase()) ||
              (materi.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();

      return materiList;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching materi: $e');
      }
      return [];
    }
  }
}