import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';
import '../models/social_media_models.dart';

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
}