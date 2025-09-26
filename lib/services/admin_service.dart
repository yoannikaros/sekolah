import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/quiz_models.dart';
import '../models/admin_models.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // School CRUD Operations
  Future<String?> createSchool(School school) async {
    try {
      // Create a proper school data map for Firebase
      final schoolData = {
        'name': school.name,
        'address': school.address,
        'phone': school.phone,
        'email': school.email,
        'website': school.website,
        'createdAt': school.createdAt.toIso8601String(),
        'isActive': true,
        'logoUrl': school.logoUrl,
      };
      
      final docRef = await _firestore.collection('schools').add(schoolData);
      if (kDebugMode) {
        print('School created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating school: $e');
      }
      return null;
    }
  }

  Future<bool> updateSchool(String id, School school) async {
    try {
      // Create a proper school data map for Firebase update
      final schoolData = {
        'name': school.name,
        'address': school.address,
        'phone': school.phone,
        'email': school.email,
        'website': school.website,
        'isActive': school.isActive,
        'logoUrl': school.logoUrl,
        // Don't update createdAt as it should remain unchanged
      };
      
      await _firestore.collection('schools').doc(id).update(schoolData);
      if (kDebugMode) {
        print('School updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating school: $e');
      }
      return false;
    }
  }

  Future<bool> deleteSchool(String id) async {
    try {
      await _firestore.collection('schools').doc(id).update({'isActive': false});
      if (kDebugMode) {
        print('School soft deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting school: $e');
      }
      return false;
    }
  }

  Future<List<School>> getAllSchools() async {
    try {
      if (kDebugMode) {
        print('Fetching all schools from Firebase...');
      }
      
      // First, try to get all schools without isActive filter to debug
      final querySnapshot = await _firestore
          .collection('schools')
          .orderBy('name')
          .get();

      if (kDebugMode) {
        print('Total documents in schools collection: ${querySnapshot.docs.length}');
        for (var doc in querySnapshot.docs) {
          print('Document ID: ${doc.id}, Data: ${doc.data()}');
        }
      }

      final schools = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            // Include documents that don't have isActive field or have isActive = true
            return data['isActive'] == null || data['isActive'] == true;
          })
          .map((doc) => School.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      if (kDebugMode) {
        print('Retrieved ${schools.length} active schools from Firebase');
        for (var school in schools) {
          print('School: ${school.name}, ID: ${school.id}');
        }
      }
      
      return schools;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all schools: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  Future<School?> getSchoolById(String id) async {
    try {
      final doc = await _firestore.collection('schools').doc(id).get();
      if (doc.exists) {
        final school = School.fromJson({...doc.data()!, 'id': doc.id});
        if (kDebugMode) {
          print('Retrieved school: ${school.name} with ID: $id');
        }
        return school;
      }
      if (kDebugMode) {
        print('School not found with ID: $id');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting school: $e');
      }
      return null;
    }
  }

  // Subject CRUD Operations
  Future<String?> createSubject(Subject subject) async {
    try {
      final docRef = await _firestore.collection('subjects').add(subject.toJson());
      return docRef.id;
    } catch (e) {
      // Error creating subject: $e
      return null;
    }
  }

  Future<bool> updateSubject(String id, Subject subject) async {
    try {
      await _firestore.collection('subjects').doc(id).update(subject.toJson());
      return true;
    } catch (e) {
      // Error updating subject: $e
      return false;
    }
  }

  Future<bool> deleteSubject(String id) async {
    try {
      await _firestore.collection('subjects').doc(id).update({'isActive': false});
      return true;
    } catch (e) {
      // Error deleting subject: $e
      return false;
    }
  }

  Future<List<Subject>> getAllSubjects() async {
    try {
      if (kDebugMode) {
        print('Fetching all subjects from Firebase...');
      }
      
      // Remove isActive filter to get all subjects, then filter in app
      final querySnapshot = await _firestore
          .collection('subjects')
          .orderBy('name')  // Changed from sortOrder to name for better ordering
          .get();

      if (kDebugMode) {
        print('Total documents in subjects collection: ${querySnapshot.docs.length}');
        for (var doc in querySnapshot.docs) {
          print('Document ID: ${doc.id}, Data: ${doc.data()}');
        }
      }

      final subjects = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            // Include documents that don't have isActive field or have isActive = true
            return data['isActive'] == null || data['isActive'] == true;
          })
          .map((doc) => Subject.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      
      if (kDebugMode) {
        print('Retrieved ${subjects.length} active subjects from Firebase');
        for (var subject in subjects) {
          print('Subject: ${subject.name}, ID: ${subject.id}');
        }
      }
      
      return subjects;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all subjects: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  Future<List<Subject>> getSubjectsByClassCode(String classCodeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subjects')
          .where('classCodeIds', arrayContains: classCodeId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Subject.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting subjects by class code: $e');
      }
      return [];
    }
  }

  Future<Subject?> getSubjectById(String id) async {
    try {
      final doc = await _firestore.collection('subjects').doc(id).get();
      if (doc.exists) {
        return Subject.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      // Error getting subject: $e
      return null;
    }
  }

  // Class Code CRUD Operations
  Future<String?> createClassCode(ClassCode classCode) async {
    try {
      final docRef = await _firestore.collection('class_codes').add(classCode.toJson());
      return docRef.id;
    } catch (e) {
      // Error creating class code: $e
      return null;
    }
  }

  Future<bool> updateClassCode(String id, ClassCode classCode) async {
    try {
      await _firestore.collection('class_codes').doc(id).update(classCode.toJson());
      return true;
    } catch (e) {
      // Error updating class code: $e
      return false;
    }
  }

  Future<bool> deleteClassCode(String id) async {
    try {
      if (kDebugMode) {
        print('Permanently deleting class code with ID: $id');
      }
      
      // Permanently delete the document from Firebase
      await _firestore.collection('class_codes').doc(id).delete();
      
      if (kDebugMode) {
        print('Class code permanently deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error permanently deleting class code: $e');
      }
      return false;
    }
  }

  Future<List<ClassCode>> getAllClassCodes() async {
    try {
      if (kDebugMode) {
        print('Fetching all class codes from Firebase...');
      }
      
      final querySnapshot = await _firestore
          .collection('class_codes')
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('Total class codes documents: ${querySnapshot.docs.length}');
        for (var doc in querySnapshot.docs) {
          print('Class Code Document ID: ${doc.id}, Data: ${doc.data()}');
        }
      }

      final classCodes = querySnapshot.docs
          .map((doc) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              
              // Handle different date formats from Firebase
              if (data['createdAt'] is String) {
                // Already a string, keep as is
              } else if (data['createdAt'] is Timestamp) {
                // Convert Timestamp to ISO string
                data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
              } else if (data['createdAt'] == null) {
                // Set default date if missing
                data['createdAt'] = DateTime.now().toIso8601String();
              }
              
              // Always use Firestore document ID as the id field
              data['id'] = doc.id;
              
              // Handle empty or null schoolId
              if (data['schoolId'] == null || data['schoolId'] == '') {
                data['schoolId'] = null;
              }
              
              if (kDebugMode) {
                print('Processing class code ${doc.id}: code=${data['code']}, schoolId=${data['schoolId']}, isActive=${data['isActive']}');
              }
              
              return ClassCode.fromJson(data);
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing class code document ${doc.id}: $e');
                print('Document data: ${doc.data()}');
              }
              return null;
            }
          })
          .where((classCode) => classCode != null)
          .cast<ClassCode>()
          .toList();

      if (kDebugMode) {
        print('Successfully parsed ${classCodes.length} class codes');
      }

      return classCodes;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all class codes: $e');
      }
      return [];
    }
  }

  Future<ClassCode?> getClassCodeById(String id) async {
    try {
      final doc = await _firestore.collection('class_codes').doc(id).get();
      if (doc.exists) {
        return ClassCode.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      // Error getting class code: $e
      return null;
    }
  }

  // Student CRUD Operations
  Future<String?> createStudent(Student student) async {
    try {
      final docRef = await _firestore.collection('students').add(student.toJson());
      return docRef.id;
    } catch (e) {
      // Error creating student: $e
      return null;
    }
  }

  Future<bool> updateStudent(String id, Student student) async {
    try {
      await _firestore.collection('students').doc(id).update(student.toJson());
      return true;
    } catch (e) {
      // Error updating student: $e
      return false;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      await _firestore.collection('students').doc(id).update({'isActive': false});
      return true;
    } catch (e) {
      // Error deleting student: $e
      return false;
    }
  }

  Future<List<Student>> getAllStudents() async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .orderBy('enrolledAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Student.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Error getting all students: $e
      return [];
    }
  }

  Future<List<Student>> getStudentsByClassCode(String classCodeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('classCodeId', isEqualTo: classCodeId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Student.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Error getting students by class code: $e
      return [];
    }
  }

  Future<Student?> getStudentById(String id) async {
    try {
      final doc = await _firestore.collection('students').doc(id).get();
      if (doc.exists) {
        return Student.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      // Error getting student: $e
      return null;
    }
  }

  // Question CRUD Operations
  Future<String?> createQuestion(Question question) async {
    try {
      final docRef = await _firestore.collection('questions').add(question.toJson());
      return docRef.id;
    } catch (e) {
      // Error creating question: $e
      return null;
    }
  }

  Future<bool> updateQuestion(String id, Question question) async {
    try {
      await _firestore.collection('questions').doc(id).update(question.toJson());
      return true;
    } catch (e) {
      // Error updating question: $e
      return false;
    }
  }

  Future<bool> deleteQuestion(String id) async {
    try {
      await _firestore.collection('questions').doc(id).delete();
      return true;
    } catch (e) {
      // Error deleting question: $e
      return false;
    }
  }

  Future<List<Question>> getAllQuestions() async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .orderBy('category')
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Error getting all questions: $e
      return [];
    }
  }

  Future<List<Question>> getQuestionsByCategory(QuestionCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('category', isEqualTo: category.name)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Error getting questions by category: $e
      return [];
    }
  }

  Future<Question?> getQuestionById(String id) async {
    try {
      final doc = await _firestore.collection('questions').doc(id).get();
      if (doc.exists) {
        return Question.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      // Error getting question: $e
      return null;
    }
  }

  // Quiz CRUD Operations
  Future<String?> createQuiz(Quiz quiz) async {
    try {
      final docRef = await _firestore.collection('quizzes').add(quiz.toJson());
      return docRef.id;
    } catch (e) {
      // Error creating quiz: $e
      return null;
    }
  }

  Future<bool> updateQuiz(String id, Quiz quiz) async {
    try {
      await _firestore.collection('quizzes').doc(id).update(quiz.toJson());
      return true;
    } catch (e) {
      // Error updating quiz: $e
      return false;
    }
  }

  Future<bool> deleteQuiz(String id) async {
    try {
      await _firestore.collection('quizzes').doc(id).update({'isActive': false});
      return true;
    } catch (e) {
      // Error deleting quiz: $e
      return false;
    }
  }

  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final querySnapshot = await _firestore
          .collection('quizzes')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Quiz.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Error getting all quizzes: $e
      return [];
    }
  }

  Future<List<Quiz>> getQuizzesBySubject(String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('subjectId', isEqualTo: subjectId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Quiz.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Error getting quizzes by subject: $e
      return [];
    }
  }

  Future<List<Question>> getQuestionsByQuiz(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('quizId', isEqualTo: quizId)
          .orderBy('order')
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Error getting questions by quiz: $e
      return [];
    }
  }

  Future<List<ClassCode>> getClassCodesBySchool(String schoolId) async {
    try {
      final querySnapshot = await _firestore
          .collection('class_codes')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ClassCode.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      // Error getting class codes by school: $e
      return [];
    }
  }

  // Admin User Operations
  Future<String?> createAdminUser(AdminUser adminUser) async {
    try {
      debugPrint('Creating admin user with data: ${adminUser.toJson()}');
      
      // Check if admin with this email already exists
      final existingAdmin = await getAdminUserByEmail(adminUser.email);
      if (existingAdmin != null) {
        debugPrint('Admin with email ${adminUser.email} already exists');
        throw Exception('Admin dengan email ini sudah terdaftar');
      }
      
      // Create Firebase Authentication user first
      debugPrint('Creating Firebase Auth user for admin: ${adminUser.email}');
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminUser.email.trim().toLowerCase(),
        password: adminUser.password,
      );
      
      debugPrint('Firebase Auth user created with UID: ${userCredential.user?.uid}');
      
      // Update admin user with Firebase UID
      final adminUserWithUid = AdminUser(
        id: userCredential.user?.uid ?? '',
        name: adminUser.name,
        email: adminUser.email,
        password: adminUser.password,
        role: adminUser.role,
        createdAt: adminUser.createdAt,
        isActive: adminUser.isActive,
        lastLogin: adminUser.lastLogin,
        managedClassCodes: adminUser.managedClassCodes,
      );
      
      // Store admin data in Firestore with Firebase UID as document ID
      await _firestore.collection('admin_users').doc(userCredential.user?.uid).set(adminUserWithUid.toJson());
      debugPrint('Admin user created successfully in Firestore with ID: ${userCredential.user?.uid}');
      
      return userCredential.user?.uid;
    } catch (e) {
      debugPrint('Error creating admin user: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow; // Re-throw the error so it can be caught in the UI
    }
  }

  Future<AdminUser?> getAdminUserByEmail(String email) async {
    try {
      debugPrint('Looking for admin user with email: $email');
      
      final querySnapshot = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} admin users with email: $email');

      if (querySnapshot.docs.isNotEmpty) {
        final adminUser = AdminUser.fromJson({...querySnapshot.docs.first.data(), 'id': querySnapshot.docs.first.id});
        debugPrint('Admin user found: ${adminUser.name} (${adminUser.email})');
        return adminUser;
      }
      
      debugPrint('No admin user found with email: $email');
      return null;
    } catch (e) {
      debugPrint('Error getting admin user by email: $e');
      return null;
    }
  }

  // Utility Methods
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final classCodesCount = await _firestore
          .collection('class_codes')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      final studentsCount = await _firestore
          .collection('students')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      final questionsCount = await _firestore
          .collection('questions')
          .count()
          .get();

      final quizzesCount = await _firestore
          .collection('quizzes')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return {
        'classCodes': classCodesCount.count,
        'students': studentsCount.count,
        'questions': questionsCount.count,
        'quizzes': quizzesCount.count,
      };
    } catch (e) {
      // Error getting dashboard stats: $e
      return {
        'classCodes': 0,
        'students': 0,
        'questions': 0,
        'quizzes': 0,
      };
    }
  }

  Future<String> generateUniqueClassCode() async {
    String code;
    
    while (true) {
      code = _generateClassCode();
      final existing = await _firestore
          .collection('class_codes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      
      if (existing.docs.isEmpty) {
        return code;
      }
    }
  }

  // Authentication
  Future<AdminUser?> authenticateAdmin(String email, String password) async {
    try {
      debugPrint('Attempting admin authentication for email: $email');
      
      // First try to authenticate with Firebase Auth
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
        
        debugPrint('Firebase Auth successful for admin: ${userCredential.user?.uid}');
        
        // Get admin data from Firestore using Firebase UID
        final adminDoc = await _firestore
            .collection('admin_users')
            .doc(userCredential.user?.uid)
            .get();
            
        if (adminDoc.exists && adminDoc.data() != null) {
          final adminUser = AdminUser.fromJson({...adminDoc.data()!, 'id': adminDoc.id});
          
          if (adminUser.isActive) {
            // Update last login time
            await _firestore
                .collection('admin_users')
                .doc(adminDoc.id)
                .update({'lastLogin': DateTime.now().toIso8601String()});
            
            debugPrint('Admin authentication successful: ${adminUser.name}');
            return adminUser;
          } else {
            debugPrint('Admin account is inactive');
            throw Exception('Akun admin tidak aktif');
          }
        } else {
          debugPrint('Admin data not found in Firestore');
          throw Exception('Data admin tidak ditemukan');
        }
      } catch (e) {
        debugPrint('Firebase Auth failed, trying legacy authentication: $e');
        
        // Fallback to legacy authentication for existing admins
        final querySnapshot = await _firestore
            .collection('admin_users')
            .where('email', isEqualTo: email.trim().toLowerCase())
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        debugPrint('Legacy query found ${querySnapshot.docs.length} admin users');

        if (querySnapshot.docs.isNotEmpty) {
          final adminData = querySnapshot.docs.first.data();
          final adminUser = AdminUser.fromJson({...adminData, 'id': querySnapshot.docs.first.id});
          
          debugPrint('Admin user found: ${adminUser.name}');
          debugPrint('Stored password: ${adminUser.password}');
          debugPrint('Provided password: $password');
          
          if (adminUser.password == password) {
            debugPrint('Password match successful');
            
            // Update last login time
            await _firestore
                .collection('admin_users')
                .doc(querySnapshot.docs.first.id)
                .update({'lastLogin': DateTime.now().toIso8601String()});
            
            debugPrint('Admin authentication successful (legacy): ${adminUser.name}');
            return adminUser;
          } else {
            debugPrint('Password mismatch');
            throw Exception('Email atau password salah');
          }
        } else {
          debugPrint('No admin user found with email: $email');
          throw Exception('Email atau password salah');
        }
      }
    } catch (e) {
      debugPrint('Error in admin authentication: $e');
      rethrow;
    }
  }

  // Create default admin user (for initial setup)
  Future<void> createDefaultAdmin() async {
    try {
      final existingAdmin = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: 'admin@example.com')
          .limit(1)
          .get();

      if (existingAdmin.docs.isEmpty) {
        final defaultAdmin = AdminUser(
          id: '',
          name: 'Super Admin',
          email: 'admin@example.com',
          password: 'admin123', // In production, this should be hashed
          role: AdminRole.superAdmin,
          isActive: true,
          createdAt: DateTime.now(),
          lastLogin: null,
        );

        await _firestore.collection('admin_users').add(defaultAdmin.toJson());
        debugPrint('Default admin user created');
      }
    } catch (e) {
      debugPrint('Error creating default admin: $e');
    }
  }

  // Teacher CRUD Operations
  Future<String?> createTeacher({
    required String name,
    required String email,
    required String password,
    required String schoolId,
    String? phone,
    String? address,
    String? employeeId,
    List<String> subjectIds = const [],
  }) async {
    try {
      // Create Firebase Auth user first
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;
      final now = DateTime.now();

      // Create teacher data for Firestore
      final teacherData = {
        'name': name,
        'email': email,
        'schoolId': schoolId,
        'phone': phone,
        'address': address,
        'employeeId': employeeId,
        'subjectIds': subjectIds,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isActive': true,
        'profileImageUrl': null,
        'lastLogin': null,
      };

      // Save teacher to Firestore with the same ID as Firebase Auth
      await _firestore.collection('teachers').doc(userId).set(teacherData);

      if (kDebugMode) {
        print('Teacher created successfully with ID: $userId');
      }
      return userId;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating teacher: $e');
      }
      return null;
    }
  }

  Future<bool> updateTeacher(String id, Teacher teacher) async {
    try {
      final teacherData = {
        'name': teacher.name,
        'email': teacher.email,
        'schoolId': teacher.schoolId,
        'phone': teacher.phone,
        'address': teacher.address,
        'employeeId': teacher.employeeId,
        'subjectIds': teacher.subjectIds,
        'updatedAt': teacher.updatedAt.toIso8601String(),
        'isActive': teacher.isActive,
        'profileImageUrl': teacher.profileImageUrl,
      };

      await _firestore.collection('teachers').doc(id).update(teacherData);
      
      if (kDebugMode) {
        print('Teacher updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating teacher: $e');
      }
      return false;
    }
  }

  Future<bool> deleteTeacher(String id) async {
    try {
      // Soft delete - just mark as inactive
      await _firestore.collection('teachers').doc(id).update({'isActive': false});
      
      if (kDebugMode) {
        print('Teacher soft deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting teacher: $e');
      }
      return false;
    }
  }

  Future<List<Teacher>> getAllTeachers() async {
    try {
      if (kDebugMode) {
        print('Fetching all teachers from Firebase...');
      }

      // First, try to get all documents without complex query to debug
      QuerySnapshot querySnapshot;
      try {
        // Try with the original query first
        querySnapshot = await _firestore
            .collection('teachers')
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();
      } catch (e) {
        if (kDebugMode) {
          print('Complex query failed, trying simple query: $e');
        }
        // Fallback to simple query without orderBy if composite index doesn't exist
        try {
          querySnapshot = await _firestore
              .collection('teachers')
              .where('isActive', isEqualTo: true)
              .get();
        } catch (e2) {
          if (kDebugMode) {
            print('isActive query failed, trying to get all documents: $e2');
          }
          // Final fallback - get all documents
          querySnapshot = await _firestore
              .collection('teachers')
              .get();
        }
      }

      if (kDebugMode) {
        print('Total teacher documents found: ${querySnapshot.docs.length}');
        // Debug: print all documents to see what's in Firebase
        for (var doc in querySnapshot.docs) {
          print('Document ID: ${doc.id}, Data: ${doc.data()}');
        }
      }

      final teachers = <Teacher>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID to data
          
          // Check if document has required fields and is active
          if (data['isActive'] == null || data['isActive'] == true) {
            final teacher = Teacher.fromJson(data);
            teachers.add(teacher);
            if (kDebugMode) {
              print('Successfully parsed teacher: ${teacher.name} (ID: ${teacher.id})');
            }
          } else {
            if (kDebugMode) {
              print('Skipping inactive teacher: ${data['name'] ?? 'Unknown'}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing teacher document ${doc.id}: $e');
            print('Document data: ${doc.data()}');
          }
        }
      }

      // Sort teachers by name manually if we couldn't use orderBy
      teachers.sort((a, b) => a.name.compareTo(b.name));

      if (kDebugMode) {
        print('Successfully parsed ${teachers.length} teachers');
      }

      return teachers;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching teachers: $e');
      }
      return [];
    }
  }

  Future<Teacher?> getTeacherById(String id) async {
    try {
      final doc = await _firestore.collection('teachers').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Teacher.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching teacher by ID: $e');
      }
      return null;
    }
  }

  Future<List<Teacher>> getTeachersBySchool(String schoolId) async {
    try {
      final querySnapshot = await _firestore
          .collection('teachers')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Teacher.fromJson(data);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching teachers by school: $e');
      }
      return [];
    }
  }

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // New methods for hierarchical quiz management

  // AdminQuiz CRUD Operations
  Future<String?> createAdminQuiz(AdminQuiz quiz) async {
    try {
      final quizData = {
        'title': quiz.title,
        'description': quiz.description,
        'subjectId': quiz.subjectId,
        'classCodeId': quiz.classCodeId,
        'chapterIds': quiz.chapterIds,
        'createdBy': quiz.createdBy,
        'createdAt': quiz.createdAt.toIso8601String(),
        'updatedAt': quiz.updatedAt.toIso8601String(),
        'isActive': quiz.isActive,
        'isPublished': quiz.isPublished,
        'timeLimit': quiz.timeLimit,
        'publishedAt': quiz.publishedAt?.toIso8601String(),
        'dueDate': quiz.dueDate?.toIso8601String(),
      };
      
      final docRef = await _firestore.collection('admin_quizzes').add(quizData);
      if (kDebugMode) {
        print('AdminQuiz created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating admin quiz: $e');
      }
      return null;
    }
  }

  Future<bool> updateAdminQuiz(AdminQuiz quiz) async {
    try {
      final quizData = {
        'title': quiz.title,
        'description': quiz.description,
        'subjectId': quiz.subjectId,
        'classCodeId': quiz.classCodeId,
        'chapterIds': quiz.chapterIds,
        'updatedAt': quiz.updatedAt.toIso8601String(),
        'isActive': quiz.isActive,
        'isPublished': quiz.isPublished,
        'timeLimit': quiz.timeLimit,
        'publishedAt': quiz.publishedAt?.toIso8601String(),
        'dueDate': quiz.dueDate?.toIso8601String(),
      };
      
      await _firestore.collection('admin_quizzes').doc(quiz.id).update(quizData);
      if (kDebugMode) {
        print('AdminQuiz updated successfully with ID: ${quiz.id}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin quiz: $e');
      }
      return false;
    }
  }

  Future<bool> deleteAdminQuiz(String id) async {
    try {
      await _firestore.collection('admin_quizzes').doc(id).update({'isActive': false});
      if (kDebugMode) {
        print('AdminQuiz soft deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting admin quiz: $e');
      }
      return false;
    }
  }

  Future<List<AdminQuiz>> getAdminQuizzes() async {
    try {
      if (kDebugMode) {
        print('Fetching admin quizzes from Firebase...');
      }
      
      final querySnapshot = await _firestore
          .collection('admin_quizzes')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final quizzes = <AdminQuiz>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse dates safely
          if (data['createdAt'] is String) {
            data['createdAt'] = DateTime.parse(data['createdAt']);
          }
          if (data['updatedAt'] is String) {
            data['updatedAt'] = DateTime.parse(data['updatedAt']);
          }
          if (data['publishedAt'] is String) {
            data['publishedAt'] = DateTime.parse(data['publishedAt']);
          }
          if (data['dueDate'] is String) {
            data['dueDate'] = DateTime.parse(data['dueDate']);
          }
          
          final quiz = AdminQuiz.fromJson(data);
          quizzes.add(quiz);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing admin quiz document ${doc.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('Successfully parsed ${quizzes.length} admin quizzes');
      }

      return quizzes;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching admin quizzes: $e');
      }
      return [];
    }
  }

  Future<AdminQuiz?> getAdminQuizById(String id) async {
    try {
      final doc = await _firestore.collection('admin_quizzes').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        
        // Parse dates safely
        if (data['createdAt'] is String) {
          data['createdAt'] = DateTime.parse(data['createdAt']);
        }
        if (data['updatedAt'] is String) {
          data['updatedAt'] = DateTime.parse(data['updatedAt']);
        }
        if (data['publishedAt'] is String) {
          data['publishedAt'] = DateTime.parse(data['publishedAt']);
        }
        if (data['dueDate'] is String) {
          data['dueDate'] = DateTime.parse(data['dueDate']);
        }
        
        return AdminQuiz.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching admin quiz by ID: $e');
      }
      return null;
    }
  }

  // QuizChapter CRUD Operations
  Future<String?> createQuizChapter(QuizChapter chapter) async {
    try {
      final chapterData = {
        'title': chapter.title,
        'description': chapter.description,
        'quizId': chapter.quizId,
        'questionIds': chapter.questionIds,
        'orderIndex': chapter.orderIndex,
        'createdAt': chapter.createdAt.toIso8601String(),
        'updatedAt': chapter.updatedAt.toIso8601String(),
        'isActive': chapter.isActive,
      };
      
      final docRef = await _firestore.collection('quiz_chapters').add(chapterData);
      
      // Update parent quiz's chapterIds
      await _updateQuizChapterIds(chapter.quizId);
      
      if (kDebugMode) {
        print('QuizChapter created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating quiz chapter: $e');
      }
      return null;
    }
  }

  Future<bool> updateQuizChapter(QuizChapter chapter) async {
    try {
      final chapterData = {
        'title': chapter.title,
        'description': chapter.description,
        'questionIds': chapter.questionIds,
        'orderIndex': chapter.orderIndex,
        'updatedAt': chapter.updatedAt.toIso8601String(),
        'isActive': chapter.isActive,
      };
      
      await _firestore.collection('quiz_chapters').doc(chapter.id).update(chapterData);
      if (kDebugMode) {
        print('QuizChapter updated successfully with ID: ${chapter.id}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating quiz chapter: $e');
      }
      return false;
    }
  }

  Future<bool> deleteQuizChapter(String id) async {
    try {
      // Get chapter to find parent quiz
      final chapterDoc = await _firestore.collection('quiz_chapters').doc(id).get();
      if (chapterDoc.exists) {
        final quizId = chapterDoc.data()!['quizId'] as String;
        
        // Soft delete chapter
        await _firestore.collection('quiz_chapters').doc(id).update({'isActive': false});
        
        // Update parent quiz's chapterIds
        await _updateQuizChapterIds(quizId);
        
        if (kDebugMode) {
          print('QuizChapter soft deleted successfully with ID: $id');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting quiz chapter: $e');
      }
      return false;
    }
  }

  Future<List<QuizChapter>> getQuizChapters(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quiz_chapters')
          .where('quizId', isEqualTo: quizId)
          .where('isActive', isEqualTo: true)
          .orderBy('orderIndex')
          .get();

      final chapters = <QuizChapter>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse dates safely
          if (data['createdAt'] is String) {
            data['createdAt'] = DateTime.parse(data['createdAt']);
          }
          if (data['updatedAt'] is String) {
            data['updatedAt'] = DateTime.parse(data['updatedAt']);
          }
          
          final chapter = QuizChapter.fromJson(data);
          chapters.add(chapter);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing quiz chapter document ${doc.id}: $e');
          }
        }
      }

      return chapters;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching quiz chapters: $e');
      }
      return [];
    }
  }

  // AdminQuestion CRUD Operations
  Future<String?> createAdminQuestion(AdminQuestion question) async {
    try {
      final questionData = {
        'questionText': question.questionText,
        'type': question.type.name,
        'chapterId': question.chapterId,
        'options': question.options,
        'correctAnswerIndex': question.correctAnswerIndex,
        'correctAnswerText': question.correctAnswerText,
        'explanation': question.explanation,
        'points': question.points,
        'orderIndex': question.orderIndex,
        'imageUrl': question.imageUrl,
        'createdAt': question.createdAt.toIso8601String(),
        'updatedAt': question.updatedAt.toIso8601String(),
        'isActive': question.isActive,
        'metadata': question.metadata,
      };
      
      final docRef = await _firestore.collection('admin_questions').add(questionData);
      
      // Update parent chapter's questionIds
      await _updateChapterQuestionIds(question.chapterId);
      
      if (kDebugMode) {
        print('AdminQuestion created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating admin question: $e');
      }
      return null;
    }
  }

  Future<bool> updateAdminQuestion(AdminQuestion question) async {
    try {
      final questionData = {
        'questionText': question.questionText,
        'type': question.type.name,
        'options': question.options,
        'correctAnswerIndex': question.correctAnswerIndex,
        'correctAnswerText': question.correctAnswerText,
        'explanation': question.explanation,
        'points': question.points,
        'orderIndex': question.orderIndex,
        'imageUrl': question.imageUrl,
        'updatedAt': question.updatedAt.toIso8601String(),
        'isActive': question.isActive,
        'metadata': question.metadata,
      };
      
      await _firestore.collection('admin_questions').doc(question.id).update(questionData);
      if (kDebugMode) {
        print('AdminQuestion updated successfully with ID: ${question.id}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin question: $e');
      }
      return false;
    }
  }

  Future<bool> deleteAdminQuestion(String id) async {
    try {
      // Get question to find parent chapter
      final questionDoc = await _firestore.collection('admin_questions').doc(id).get();
      if (questionDoc.exists) {
        final chapterId = questionDoc.data()!['chapterId'] as String;
        
        // Soft delete question
        await _firestore.collection('admin_questions').doc(id).update({'isActive': false});
        
        // Update parent chapter's questionIds
        await _updateChapterQuestionIds(chapterId);
        
        if (kDebugMode) {
          print('AdminQuestion soft deleted successfully with ID: $id');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting admin question: $e');
      }
      return false;
    }
  }

  Future<List<AdminQuestion>> getChapterQuestions(String chapterId) async {
    try {
      final querySnapshot = await _firestore
          .collection('admin_questions')
          .where('chapterId', isEqualTo: chapterId)
          .where('isActive', isEqualTo: true)
          .orderBy('orderIndex')
          .get();

      final questions = <AdminQuestion>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse dates safely
          if (data['createdAt'] is String) {
            data['createdAt'] = DateTime.parse(data['createdAt']);
          }
          if (data['updatedAt'] is String) {
            data['updatedAt'] = DateTime.parse(data['updatedAt']);
          }
          
          // Parse enum
          if (data['type'] is String) {
            data['type'] = AdminQuestionType.values.firstWhere(
              (e) => e.name == data['type'],
              orElse: () => AdminQuestionType.multipleChoice,
            );
          }
          
          final question = AdminQuestion.fromJson(data);
          questions.add(question);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing admin question document ${doc.id}: $e');
          }
        }
      }

      return questions;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching chapter questions: $e');
      }
      return [];
    }
  }

  // Helper methods to maintain relationships
  Future<void> _updateQuizChapterIds(String quizId) async {
    try {
      final chaptersSnapshot = await _firestore
          .collection('quiz_chapters')
          .where('quizId', isEqualTo: quizId)
          .where('isActive', isEqualTo: true)
          .get();

      final chapterIds = chaptersSnapshot.docs.map((doc) => doc.id).toList();
      
      await _firestore.collection('admin_quizzes').doc(quizId).update({
        'chapterIds': chapterIds,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating quiz chapter IDs: $e');
      }
    }
  }

  Future<void> _updateChapterQuestionIds(String chapterId) async {
    try {
      final questionsSnapshot = await _firestore
          .collection('admin_questions')
          .where('chapterId', isEqualTo: chapterId)
          .where('isActive', isEqualTo: true)
          .get();

      final questionIds = questionsSnapshot.docs.map((doc) => doc.id).toList();
      
      await _firestore.collection('quiz_chapters').doc(chapterId).update({
        'questionIds': questionIds,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating chapter question IDs: $e');
      }
    }
  }

  // Student Quiz Attempt CRUD Operations
  Future<String?> createStudentQuizAttempt(StudentQuizAttempt attempt) async {
    try {
      final attemptData = {
        'studentId': attempt.studentId,
        'quizId': attempt.quizId,
        'answers': attempt.answers.map((key, value) => MapEntry(key, value.toJson())),
        'startedAt': attempt.startedAt.toIso8601String(),
        'completedAt': attempt.completedAt?.toIso8601String(),
        'totalScore': attempt.totalScore,
        'isCompleted': attempt.isCompleted,
        'timeSpent': attempt.timeSpent,
      };
      
      final docRef = await _firestore.collection('student_quiz_attempts').add(attemptData);
      if (kDebugMode) {
        print('StudentQuizAttempt created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating student quiz attempt: $e');
      }
      return null;
    }
  }

  Future<bool> updateStudentQuizAttempt(StudentQuizAttempt attempt) async {
    try {
      final attemptData = {
        'answers': attempt.answers.map((key, value) => MapEntry(key, value.toJson())),
        'completedAt': attempt.completedAt?.toIso8601String(),
        'totalScore': attempt.totalScore,
        'isCompleted': attempt.isCompleted,
        'timeSpent': attempt.timeSpent,
      };
      
      await _firestore.collection('student_quiz_attempts').doc(attempt.id).update(attemptData);
      if (kDebugMode) {
        print('StudentQuizAttempt updated successfully with ID: ${attempt.id}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating student quiz attempt: $e');
      }
      return false;
    }
  }

  Future<List<StudentQuizAttempt>> getStudentQuizAttempts(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('student_quiz_attempts')
          .where('studentId', isEqualTo: studentId)
          .orderBy('startedAt', descending: true)
          .get();

      final attempts = <StudentQuizAttempt>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse dates safely
          if (data['startedAt'] is String) {
            data['startedAt'] = DateTime.parse(data['startedAt']);
          }
          if (data['completedAt'] is String) {
            data['completedAt'] = DateTime.parse(data['completedAt']);
          }
          
          // Parse answers map
          if (data['answers'] is Map) {
            final answersMap = <String, StudentAnswer>{};
            (data['answers'] as Map<String, dynamic>).forEach((key, value) {
              if (value is Map<String, dynamic>) {
                // Parse enum
                if (value['questionType'] is String) {
                  value['questionType'] = AdminQuestionType.values.firstWhere(
                    (e) => e.name == value['questionType'],
                    orElse: () => AdminQuestionType.multipleChoice,
                  );
                }
                // Parse date
                if (value['answeredAt'] is String) {
                  value['answeredAt'] = DateTime.parse(value['answeredAt']);
                }
                answersMap[key] = StudentAnswer.fromJson(value);
              }
            });
            data['answers'] = answersMap;
          }
          
          final attempt = StudentQuizAttempt.fromJson(data);
          attempts.add(attempt);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing student quiz attempt document ${doc.id}: $e');
          }
        }
      }

      return attempts;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching student quiz attempts: $e');
      }
      return [];
    }
  }

  Future<List<StudentQuizAttempt>> getQuizAttempts(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('student_quiz_attempts')
          .where('quizId', isEqualTo: quizId)
          .orderBy('startedAt', descending: true)
          .get();

      final attempts = <StudentQuizAttempt>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse dates safely
          if (data['startedAt'] is String) {
            data['startedAt'] = DateTime.parse(data['startedAt']);
          }
          if (data['completedAt'] is String) {
            data['completedAt'] = DateTime.parse(data['completedAt']);
          }
          
          // Parse answers map
          if (data['answers'] is Map) {
            final answersMap = <String, StudentAnswer>{};
            (data['answers'] as Map<String, dynamic>).forEach((key, value) {
              if (value is Map<String, dynamic>) {
                // Parse enum
                if (value['questionType'] is String) {
                  value['questionType'] = AdminQuestionType.values.firstWhere(
                    (e) => e.name == value['questionType'],
                    orElse: () => AdminQuestionType.multipleChoice,
                  );
                }
                // Parse date
                if (value['answeredAt'] is String) {
                  value['answeredAt'] = DateTime.parse(value['answeredAt']);
                }
                answersMap[key] = StudentAnswer.fromJson(value);
              }
            });
            data['answers'] = answersMap;
          }
          
          final attempt = StudentQuizAttempt.fromJson(data);
          attempts.add(attempt);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing student quiz attempt document ${doc.id}: $e');
          }
        }
      }

      return attempts;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching quiz attempts: $e');
      }
      return [];
    }
  }

  // Task Management CRUD Operations
  Future<String?> createTask(AdminTask task) async {
    try {
      final taskData = {
        'tanggalDibuat': task.tanggalDibuat.toIso8601String(),
        'kodeKelas': task.kodeKelas,
        'mataPelajaran': task.mataPelajaran,
        'judul': task.judul,
        'deskripsi': task.deskripsi,
        'linkSoal': task.linkSoal,
        'tanggalDibuka': task.tanggalDibuka.toIso8601String(),
        'tanggalBerakhir': task.tanggalBerakhir.toIso8601String(),
        'linkPdf': task.linkPdf,
        'komentar': task.komentar.map((comment) => comment.toJson()).toList(),
        'submissions': task.submissions.map((submission) => submission.toJson()).toList(),
        'createdBy': task.createdBy,
        'createdAt': task.createdAt.toIso8601String(),
        'updatedAt': task.updatedAt.toIso8601String(),
        'isActive': task.isActive,
      };
      
      final docRef = await _firestore.collection('admin_tasks').add(taskData);
      if (kDebugMode) {
        print('Task created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task: $e');
      }
      return null;
    }
  }

  Future<bool> updateTask(String id, AdminTask task) async {
    try {
      final taskData = {
        'tanggalDibuat': task.tanggalDibuat.toIso8601String(),
        'kodeKelas': task.kodeKelas,
        'mataPelajaran': task.mataPelajaran,
        'judul': task.judul,
        'deskripsi': task.deskripsi,
        'linkSoal': task.linkSoal,
        'tanggalDibuka': task.tanggalDibuka.toIso8601String(),
        'tanggalBerakhir': task.tanggalBerakhir.toIso8601String(),
        'linkPdf': task.linkPdf,
        'komentar': task.komentar.map((comment) => comment.toJson()).toList(),
        'submissions': task.submissions.map((submission) => submission.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': task.isActive,
      };
      
      await _firestore.collection('admin_tasks').doc(id).update(taskData);
      if (kDebugMode) {
        print('Task updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating task: $e');
      }
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _firestore.collection('admin_tasks').doc(id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Task deleted successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting task: $e');
      }
      return false;
    }
  }

  Future<List<AdminTask>> getAllTasks() async {
    try {
      if (kDebugMode) {
        print('=== STARTING getAllTasks() ===');
        print('Fetching all tasks from Firebase...');
      }
      
      // First, try to get all tasks without isActive filter to debug
      final querySnapshot = await _firestore
          .collection('admin_tasks')
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('=== FIREBASE QUERY RESULT ===');
        print('Total documents in admin_tasks collection: ${querySnapshot.docs.length}');
        
        if (querySnapshot.docs.isEmpty) {
          print('WARNING: No documents found in admin_tasks collection!');
          print('This means either:');
          print('1. No tasks have been created yet');
          print('2. Collection name is incorrect');
          print('3. Firebase rules are blocking access');
        } else {
          print('=== DOCUMENTS FOUND ===');
          for (var doc in querySnapshot.docs) {
            print('Document ID: ${doc.id}');
            print('Document Data: ${doc.data()}');
            print('---');
          }
        }
      }

      final tasks = <AdminTask>[];
      if (kDebugMode) {
        print('=== PROCESSING DOCUMENTS ===');
        print('Starting to process ${querySnapshot.docs.length} documents...');
      }
      
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          
          if (kDebugMode) {
            print('Processing document ${doc.id}:');
            print('  isActive: ${data['isActive']}');
          }
          
          // Check if task is active (include documents that don't have isActive field or have isActive = true)
          if (data['isActive'] == false) {
            if (kDebugMode) {
              print('  -> Skipping inactive task: ${doc.id}');
            }
            continue;
          }
          
          if (kDebugMode) {
            print('  -> Processing active task: ${doc.id}');
          }
          
          data['id'] = doc.id;
          
          // No need to manually parse dates anymore - the DateTimeConverter handles it
          // Parse comments
          if (data['komentar'] is List) {
            final commentsList = <TaskComment>[];
            for (final commentData in data['komentar']) {
              if (commentData is Map<String, dynamic>) {
                commentsList.add(TaskComment.fromJson(commentData));
              }
            }
            data['komentar'] = commentsList;
          } else {
            data['komentar'] = <TaskComment>[];
          }
          
          // Parse submissions (removed duplicate code)
          if (data['submissions'] is List) {
            final submissionsList = <StudentSubmission>[];
            for (final submissionData in data['submissions']) {
              if (submissionData is Map<String, dynamic>) {
                submissionsList.add(StudentSubmission.fromJson(submissionData));
              }
            }
            data['submissions'] = submissionsList;
          } else {
            data['submissions'] = <StudentSubmission>[];
          }
          
          final task = AdminTask.fromJson(data);
          tasks.add(task);
          
          if (kDebugMode) {
            print('  -> Successfully parsed task: ${task.judul} (ID: ${task.id})');
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('  -> ERROR parsing task document ${doc.id}: $e');
            print('  -> Document data: ${doc.data()}');
            print('  -> Stack trace: $stackTrace');
          }
        }
      }

      if (kDebugMode) {
        print('=== FINAL RESULT ===');
        print('Retrieved ${tasks.length} active tasks from Firebase');
        if (tasks.isNotEmpty) {
          print('Tasks found:');
          for (var task in tasks) {
            print('  - ${task.judul} (Class: ${task.kodeKelas}, Subject: ${task.mataPelajaran})');
          }
        } else {
          print('NO TASKS FOUND! This could be because:');
          print('1. All tasks have isActive = false');
          print('2. Tasks exist but failed to parse');
          print('3. No tasks exist in the collection');
        }
      }

      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  Future<AdminTask?> getTaskById(String id) async {
    try {
      final doc = await _firestore.collection('admin_tasks').doc(id).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      
      // No manual date parsing needed - DateTimeConverter handles it automatically
      
      return AdminTask.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching task: $e');
      }
      return null;
    }
  }

  Future<bool> addTaskComment(String taskId, TaskComment comment) async {
    try {
      final task = await getTaskById(taskId);
      if (task == null) return false;
      
      final updatedComments = List<TaskComment>.from(task.komentar);
      updatedComments.add(comment);
      
      final updatedTask = task.copyWith(
        komentar: updatedComments,
        updatedAt: DateTime.now(),
      );
      
      return await updateTask(taskId, updatedTask);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding task comment: $e');
      }
      return false;
    }
  }

  Future<List<AdminTask>> getTasksByClassCode(String classCode) async {
    try {
      if (kDebugMode) print('DEBUG: Fetching tasks for class code: $classCode');
      final querySnapshot = await _firestore
          .collection('admin_tasks')
          .where('isActive', isEqualTo: true)
          .where('kodeKelas', isEqualTo: classCode)
          .get();

      if (kDebugMode) print('DEBUG: Found ${querySnapshot.docs.length} documents in admin_tasks collection');

      final tasks = <AdminTask>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          if (kDebugMode) print('DEBUG: Processing task document ${doc.id}: ${data['judul']}');
          
          // No manual date parsing needed - DateTimeConverter handles it automatically
          
          final task = AdminTask.fromJson(data);
          tasks.add(task);
          if (kDebugMode) print('DEBUG: Successfully parsed task: ${task.judul}');
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task document ${doc.id}: $e');
          }
        }
      }

      // Sort tasks by creation date in memory instead of in query
      tasks.sort((a, b) => b.tanggalDibuat.compareTo(a.tanggalDibuat));

      if (kDebugMode) print('DEBUG: Successfully parsed ${tasks.length} tasks');
      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks by class code: $e');
      }
      return [];
    }
  }

  // School Account Operations
  Future<SchoolAccount?> getSchoolAccountByEmail(String email) async {
    try {
      debugPrint('Looking for school account with email: $email');
      
      final querySnapshot = await _firestore
          .collection('school_accounts')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} school accounts with email: $email');

      if (querySnapshot.docs.isNotEmpty) {
        final schoolAccount = SchoolAccount.fromJson({...querySnapshot.docs.first.data(), 'id': querySnapshot.docs.first.id});
        debugPrint('School account found: ${schoolAccount.schoolName} (${schoolAccount.email})');
        return schoolAccount;
      }
      
      debugPrint('No school account found with email: $email');
      return null;
    } catch (e) {
      debugPrint('Error getting school account by email: $e');
      return null;
    }
  }

  Future<String?> createSchoolAccount(SchoolAccount schoolAccount) async {
    try {
      debugPrint('Creating school account with data: ${schoolAccount.toJson()}');
      
      // Check if school account with this email already exists
      final existingAccount = await getSchoolAccountByEmail(schoolAccount.email);
      if (existingAccount != null) {
        debugPrint('School account with email ${schoolAccount.email} already exists');
        throw Exception('Akun sekolah dengan email ini sudah terdaftar');
      }
      
      // Create school account data for Firestore
      final schoolAccountData = schoolAccount.toJson();
      
      final docRef = await _firestore.collection('school_accounts').add(schoolAccountData);
      debugPrint('School account created successfully in Firestore with ID: ${docRef.id}');
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating school account: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<bool> updateSchoolAccount(String accountId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      
      await _firestore
          .collection('school_accounts')
          .doc(accountId)
          .update(updates);
      
      debugPrint('School account updated successfully: $accountId');
      return true;
    } catch (e) {
      debugPrint('Error updating school account: $e');
      return false;
    }
  }

  Future<bool> deleteSchoolAccount(String accountId) async {
    try {
      await _firestore
          .collection('school_accounts')
          .doc(accountId)
          .update({
            'isActive': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      
      debugPrint('School account deactivated successfully: $accountId');
      return true;
    } catch (e) {
      debugPrint('Error deactivating school account: $e');
      return false;
    }
  }

  Future<List<SchoolAccount>> getAllSchoolAccounts() async {
    try {
      final querySnapshot = await _firestore
          .collection('school_accounts')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final schoolAccounts = <SchoolAccount>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse dates
          if (data['createdAt'] is String) {
            data['createdAt'] = DateTime.parse(data['createdAt']);
          }
          if (data['updatedAt'] is String) {
            data['updatedAt'] = DateTime.parse(data['updatedAt']);
          }
          if (data['lastLogin'] is String) {
            data['lastLogin'] = DateTime.parse(data['lastLogin']);
          }
          if (data['resetTokenExpiry'] is String) {
            data['resetTokenExpiry'] = DateTime.parse(data['resetTokenExpiry']);
          }
          
          final schoolAccount = SchoolAccount.fromJson(data);
          schoolAccounts.add(schoolAccount);
        } catch (e) {
          debugPrint('Error parsing school account document ${doc.id}: $e');
        }
      }

      return schoolAccounts;
    } catch (e) {
      debugPrint('Error fetching school accounts: $e');
      return [];
    }
  }

  // School-specific operations with permission checks
  Future<bool> hasSchoolPermission(String schoolAccountId, String permission) async {
    try {
      final schoolAccount = await _firestore
          .collection('school_accounts')
          .doc(schoolAccountId)
          .get();

      if (schoolAccount.exists && schoolAccount.data() != null) {
        final data = schoolAccount.data()!;
        final permissions = List<String>.from(data['permissions'] ?? []);
        return permissions.contains(permission);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking school permission: $e');
      return false;
    }
  }



  Future<List<Subject>> getSubjectsBySchool(String schoolId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subjects')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final subjects = <Subject>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          
          // Parse dates
          if (data['createdAt'] is String) {
            data['createdAt'] = DateTime.parse(data['createdAt']);
          }
          if (data['updatedAt'] is String) {
            data['updatedAt'] = DateTime.parse(data['updatedAt']);
          }
          
          final subject = Subject.fromJson(data);
          subjects.add(subject);
        } catch (e) {
          debugPrint('Error parsing subject document ${doc.id}: $e');
        }
      }

      return subjects;
    } catch (e) {
      debugPrint('Error fetching subjects by school: $e');
      return [];
    }
  }



  Future<Map<String, dynamic>> getSchoolDashboardStats(String schoolId) async {
    try {
      final teachersCount = await _firestore
          .collection('teachers')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      final subjectsCount = await _firestore
          .collection('subjects')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      final classCodesCount = await _firestore
          .collection('class_codes')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      // Count students through class codes
      final classCodesSnapshot = await _firestore
          .collection('class_codes')
          .where('schoolId', isEqualTo: schoolId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalStudents = 0;
      for (final classDoc in classCodesSnapshot.docs) {
        final studentsCount = await _firestore
            .collection('students')
            .where('classCodeId', isEqualTo: classDoc.id)
            .where('isActive', isEqualTo: true)
            .count()
            .get();
        totalStudents += studentsCount.count ?? 0;
      }

      return {
        'teachers': teachersCount.count ?? 0,
        'subjects': subjectsCount.count ?? 0,
        'classCodes': classCodesCount.count ?? 0,
        'students': totalStudents,
      };
    } catch (e) {
      debugPrint('Error getting school dashboard stats: $e');
      return {
        'teachers': 0,
        'subjects': 0,
        'classCodes': 0,
        'students': 0,
      };
    }
  }
}