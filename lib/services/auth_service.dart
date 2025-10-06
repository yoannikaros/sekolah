import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/admin_models.dart';
import '../models/social_media_models.dart';
import 'admin_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
    }
  }

  // Teacher login with school code validation
  Future<Map<String, dynamic>?> signInTeacher({
    required String email,
    required String password,
  }) async {
    try {
      // First authenticate with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final userId = result.user!.uid;

      // Get teacher data from Firestore
      final teacherDoc = await _firestore.collection('teachers').doc(userId).get();
      
      if (!teacherDoc.exists) {
        // If not found in teachers collection, sign out and throw error
        await _auth.signOut();
        throw 'Akun tidak ditemukan sebagai guru. Silakan hubungi administrator.';
      }

      final teacherData = teacherDoc.data()!;
      teacherData['id'] = teacherDoc.id;
      
      // Check if teacher is active
      if (teacherData['isActive'] != true) {
        await _auth.signOut();
        throw 'Akun guru tidak aktif. Silakan hubungi administrator.';
      }

      // Update last login
      await _firestore.collection('teachers').doc(userId).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });

      // Get school information
      final schoolDoc = await _firestore.collection('schools').doc(teacherData['schoolId']).get();
      String schoolName = 'Unknown School';
      if (schoolDoc.exists) {
        schoolName = schoolDoc.data()!['name'] ?? 'Unknown School';
      }

      if (kDebugMode) {
        print('Teacher login successful: ${teacherData['name']} from $schoolName');
      }

      return {
        'user': result.user,
        'teacher': Teacher.fromJson(teacherData),
        'schoolName': schoolName,
      };
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) {
        rethrow;
      }
      throw 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
    }
  }

  // School login with email and password
  Future<Map<String, dynamic>?> signInSchool({
    required String email,
    required String password,
  }) async {
    try {
      // Query school accounts collection for matching email
      final schoolAccountQuery = await _firestore
          .collection('school_accounts')
          .where('email', isEqualTo: email.trim())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (schoolAccountQuery.docs.isEmpty) {
        throw 'Email sekolah tidak ditemukan atau tidak aktif.';
      }

      final schoolAccountDoc = schoolAccountQuery.docs.first;
      final schoolAccountData = schoolAccountDoc.data();
      
      // Verify password (in production, this should be hashed)
      if (schoolAccountData['password'] != password) {
        throw 'Password salah. Silakan coba lagi.';
      }

      // Update last login
      await _firestore.collection('school_accounts').doc(schoolAccountDoc.id).update({
        'lastLogin': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Get school information
      final schoolDoc = await _firestore.collection('schools').doc(schoolAccountData['schoolId']).get();
      
      if (!schoolDoc.exists) {
        throw 'Data sekolah tidak ditemukan.';
      }

      final schoolData = schoolDoc.data()!;
      schoolData['id'] = schoolDoc.id;

      if (kDebugMode) {
        print('School login successful: ${schoolAccountData['schoolName']}');
      }

      // Create school account object
      final schoolAccount = SchoolAccount.fromJson({
        ...schoolAccountData,
        'id': schoolAccountDoc.id,
      });

      return {
        'schoolAccount': schoolAccount,
        'school': School.fromJson(schoolData),
      };
    } catch (e) {
      if (e is String) {
        rethrow;
      }
      throw 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
    }
  }

  // Check if current user is a teacher
  Future<Teacher?> getCurrentTeacher() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final teacherDoc = await _firestore.collection('teachers').doc(user.uid).get();
      if (!teacherDoc.exists) return null;

      final teacherData = teacherDoc.data()!;
      teacherData['id'] = teacherDoc.id;
      
      return Teacher.fromJson(teacherData);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current teacher: $e');
      }
      return null;
    }
  }

  // Check if current user is a school account
  Future<SchoolAccount?> getCurrentSchoolAccount() async {
    try {
      // This method would be used if we integrate with Firebase Auth
      // For now, we'll implement it for future use
      final user = _auth.currentUser;
      if (user == null) return null;

      final schoolAccountQuery = await _firestore
          .collection('school_accounts')
          .where('email', isEqualTo: user.email)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (schoolAccountQuery.docs.isEmpty) return null;

      final schoolAccountDoc = schoolAccountQuery.docs.first;
      final schoolAccountData = schoolAccountDoc.data();
      schoolAccountData['id'] = schoolAccountDoc.id;
      
      return SchoolAccount.fromJson(schoolAccountData);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current school account: $e');
      }
      return null;
    }
  }

  // Validate teacher credentials and school access
  Future<bool> validateTeacherAccess(String teacherId, String schoolId) async {
    try {
      final teacherDoc = await _firestore.collection('teachers').doc(teacherId).get();
      
      if (!teacherDoc.exists) return false;
      
      final teacherData = teacherDoc.data()!;
      return teacherData['schoolId'] == schoolId && teacherData['isActive'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating teacher access: $e');
      }
      return false;
    }
  }

  // Validate school account access
  Future<bool> validateSchoolAccess(String schoolAccountId, String schoolId) async {
    try {
      final schoolAccountDoc = await _firestore.collection('school_accounts').doc(schoolAccountId).get();
      
      if (!schoolAccountDoc.exists) return false;
      
      final schoolAccountData = schoolAccountDoc.data()!;
      return schoolAccountData['schoolId'] == schoolId && schoolAccountData['isActive'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating school access: $e');
      }
      return false;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Gagal keluar dari akun. Silakan coba lagi.';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal mengirim email reset password. Silakan coba lagi.';
    }
  }

  // Send password reset email for school account
  Future<void> sendSchoolPasswordResetEmail({required String email}) async {
    try {
      // Check if school account exists
      final schoolAccountQuery = await _firestore
          .collection('school_accounts')
          .where('email', isEqualTo: email.trim())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (schoolAccountQuery.docs.isEmpty) {
        throw 'Email sekolah tidak ditemukan.';
      }

      // Generate reset token
      final resetToken = _generateResetToken();
      final resetTokenExpiry = DateTime.now().add(const Duration(hours: 1));

      // Update school account with reset token
      await _firestore.collection('school_accounts').doc(schoolAccountQuery.docs.first.id).update({
        'resetToken': resetToken,
        'resetTokenExpiry': resetTokenExpiry.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // In a real implementation, you would send an email here
      // For now, we'll just log the reset token
      if (kDebugMode) {
        print('Password reset token for $email: $resetToken');
      }
    } catch (e) {
      if (e is String) {
        rethrow;
      }
      throw 'Gagal mengirim email reset password. Silakan coba lagi.';
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Gagal mengirim email verifikasi. Silakan coba lagi.';
    }
  }

  // Reload user to get updated email verification status
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      // Ignore reload errors
    }
  }

  // Generate reset token
  String _generateResetToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'email-already-in-use':
        return 'Email sudah digunakan. Silakan gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan. Hubungi administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan. Hubungi administrator.';
      case 'invalid-credential':
        return 'Email atau password salah. Silakan coba lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa koneksi Anda.';
      default:
        return e.message ?? 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('user_profiles').doc(user.uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  // Update user class code
  Future<bool> updateUserClassCode(String classCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('Error: No authenticated user found');
        }
        return false;
      }

      // First validate if the class code exists and is active
      final classCodeQuery = await _firestore
          .collection('class_codes')
          .where('code', isEqualTo: classCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (classCodeQuery.docs.isEmpty) {
        // Try case-insensitive search
        final allCodesSnapshot = await _firestore
            .collection('class_codes')
            .where('isActive', isEqualTo: true)
            .get();
        
        bool found = false;
        for (final doc in allCodesSnapshot.docs) {
          final docData = doc.data();
          final docCode = docData['code']?.toString().toUpperCase();
          if (docCode == classCode.toUpperCase()) {
            found = true;
            break;
          }
        }
        
        if (!found) {
          if (kDebugMode) {
            print('Error: Class code not found or inactive: $classCode');
          }
          return false;
        }
      }

      // First check if user profile document exists
      final userProfileRef = _firestore.collection('user_profiles').doc(user.uid);
      final userProfileDoc = await userProfileRef.get();
      
      if (!userProfileDoc.exists) {
        if (kDebugMode) {
          print('User profile document does not exist, creating one...');
        }
        // Create user profile document if it doesn't exist
        await userProfileRef.set({
          'id': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email,
          'classCode': classCode.toUpperCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      } else {
        // Update existing document
        await userProfileRef.update({
          'classCode': classCode.toUpperCase(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      if (kDebugMode) {
        print('Class code updated successfully: ${classCode.toUpperCase()}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating class code: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return false;
    }
  }

  // Remove user class code
  Future<bool> removeUserClassCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('user_profiles').doc(user.uid).update({
        'classCode': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing class code: $e');
      }
      return false;
    }
  }

  // Create or update user profile
  Future<bool> createOrUpdateUserProfile({
    required String name,
    String? avatar,
    String? bio,
    String? classCode,
    String? email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userProfile = UserProfile(
        id: user.uid,
        name: name,
        avatar: avatar,
        bio: bio,
        classCode: classCode,
        email: email ?? user.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('user_profiles').doc(user.uid).set(
        userProfile.toFirestore(),
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating/updating user profile: $e');
      }
      return false;
    }
  }

  // Create student profile in students collection
  Future<bool> createStudentProfile({
    required String name,
    required String email,
    String? classCode,
    String? phone,
    String? address,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('No current user found when creating student profile');
        }
        return false;
      }

      if (kDebugMode) {
        print('Creating student profile for user: ${user.uid}');
      }

      // Check if student profile already exists
      final existingStudent = await _firestore.collection('students').doc(user.uid).get();
      if (existingStudent.exists) {
        if (kDebugMode) {
          print('Student profile already exists for user: ${user.uid}');
        }
        return true; // Already exists, no need to create
      }

      // If classCode is provided, find the actual class code document ID
      String classCodeId = '';
      String schoolId = '';
      
      if (classCode != null && classCode.isNotEmpty) {
        if (kDebugMode) {
          print('Looking up class code: $classCode');
        }
        
        // Search for class code by code field
        final classCodeQuery = await _firestore
            .collection('class_codes')
            .where('code', isEqualTo: classCode)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
            
        if (classCodeQuery.docs.isNotEmpty) {
          final classCodeDoc = classCodeQuery.docs.first;
          classCodeId = classCodeDoc.id; // Use document ID
          final classCodeData = classCodeDoc.data();
          schoolId = classCodeData['schoolId'] ?? '';
          
          if (kDebugMode) {
            print('Found class code: $classCode -> ID: $classCodeId, School ID: $schoolId');
          }
        } else {
          if (kDebugMode) {
            print('Class code not found: $classCode');
          }
        }
      }

      final student = Student(
        id: user.uid, // Use Firebase Auth UID as document ID
        name: name,
        email: email,
        studentId: user.uid, // Use Firebase Auth UID as student ID
        classCodeId: classCodeId, // Use the document ID, not the code
        schoolId: schoolId, // Set the school ID from class code
        enrolledAt: DateTime.now(),
        isActive: true,
      );

      // Use the modified createStudent method with UID parameter
      final adminService = AdminService();
      final result = await adminService.createStudent(student, uid: user.uid);
      
      if (kDebugMode) {
        print('Student profile created successfully for user: ${user.uid} with classCodeId: $classCodeId and schoolId: $schoolId');
      }
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating student profile: $e');
      }
      return false;
    }
  }

  // Get or create student profile
  Future<Map<String, dynamic>?> getOrCreateStudentProfile({
    required String name,
    required String email,
    String? classCode,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // First try to get existing student profile
      final studentDoc = await _firestore.collection('students').doc(user.uid).get();
      
      if (studentDoc.exists) {
        final studentData = studentDoc.data()!;
        studentData['id'] = studentDoc.id;
        if (kDebugMode) {
          print('Found existing student profile for user: ${user.uid}');
        }
        return studentData;
      }

      // If doesn't exist, create new student profile
      if (kDebugMode) {
        print('Student profile not found, creating new one for user: ${user.uid}');
      }
      
      final success = await createStudentProfile(
        name: name,
        email: email,
        classCode: classCode,
      );

      if (success) {
        // Fetch the newly created profile
        final newStudentDoc = await _firestore.collection('students').doc(user.uid).get();
        if (newStudentDoc.exists) {
          final studentData = newStudentDoc.data()!;
          studentData['id'] = newStudentDoc.id;
          return studentData;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting or creating student profile: $e');
      }
      return null;
    }
  }

  // Get student data by user ID
  Future<Student?> getStudentData(String userId) async {
    try {
      final studentDoc = await _firestore.collection('students').doc(userId).get();
      
      if (studentDoc.exists) {
        final studentData = studentDoc.data()!;
        studentData['id'] = studentDoc.id;
        return Student.fromJson(studentData);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting student data: $e');
      }
      return null;
    }
  }
}