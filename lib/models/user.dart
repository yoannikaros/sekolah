class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String fullName;
  final String? phone;
  final String? avatar;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.fullName,
    this.phone,
    this.avatar,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      isActive: json['is_active'] is int 
          ? json['is_active'] == 1 
          : (json['is_active'] as bool? ?? true),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'avatar': avatar,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}

enum UserRole {
  owner,
  schoolAdmin,
  teacher,
  parent,
  student,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.schoolAdmin:
        return 'school_admin';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.parent:
        return 'parent';
      case UserRole.student:
        return 'student';
    }
  }

  static UserRole fromString(String role) {
    switch (role) {
      case 'owner':
        return UserRole.owner;
      case 'school_admin':
        return UserRole.schoolAdmin;
      case 'teacher':
        return UserRole.teacher;
      case 'parent':
        return UserRole.parent;
      case 'student':
        return UserRole.student;
      default:
        throw ArgumentError('Invalid role: $role');
    }
  }
}