import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'mading_models.g.dart';

@JsonSerializable()
class MadingPost {
  final String id;
  final String imageUrl;
  final String schoolId;
  final String? subjectId; // Optional mata pelajaran
  final String studentId;
  final String studentName;
  final String studentClass;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final bool isApproved; // For teacher approval
  final String? approvedBy; // Teacher who approved

  MadingPost({
    required this.id,
    required this.imageUrl,
    required this.schoolId,
    this.subjectId,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.isApproved = false,
    this.approvedBy,
  });

  factory MadingPost.fromJson(Map<String, dynamic> json) => _$MadingPostFromJson(json);
  Map<String, dynamic> toJson() => _$MadingPostToJson(this);

  factory MadingPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle createdAt field - could be Timestamp or String
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.parse(data['createdAt']);
    } else {
      createdAt = DateTime.now();
    }
    
    // Handle updatedAt field - could be Timestamp or String
    DateTime updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is String) {
      updatedAt = DateTime.parse(data['updatedAt']);
    } else {
      updatedAt = DateTime.now();
    }
    
    return MadingPost(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      schoolId: data['schoolId'] ?? '',
      subjectId: data['subjectId'],
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentClass: data['studentClass'] ?? '',
      description: data['description'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isApproved: data['isApproved'] ?? false,
      approvedBy: data['approvedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'schoolId': schoolId,
      'subjectId': subjectId,
      'studentId': studentId,
      'studentName': studentName,
      'studentClass': studentClass,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'likedBy': likedBy,
      'isApproved': isApproved,
      'approvedBy': approvedBy,
    };
  }

  MadingPost copyWith({
    String? id,
    String? imageUrl,
    String? schoolId,
    String? subjectId,
    String? studentId,
    String? studentName,
    String? studentClass,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
    bool? isApproved,
    String? approvedBy,
  }) {
    return MadingPost(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      schoolId: schoolId ?? this.schoolId,
      subjectId: subjectId ?? this.subjectId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentClass: studentClass ?? this.studentClass,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }
}

@JsonSerializable()
class MadingComment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String userRole; // 'student', 'teacher', 'admin'
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy;
  final String? parentCommentId; // For reply comments

  MadingComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.likedBy = const [],
    this.parentCommentId,
  });

  factory MadingComment.fromJson(Map<String, dynamic> json) => _$MadingCommentFromJson(json);
  Map<String, dynamic> toJson() => _$MadingCommentToJson(this);

  factory MadingComment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MadingComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userRole: data['userRole'] ?? '',
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      parentCommentId: data['parentCommentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'likesCount': likesCount,
      'likedBy': likedBy,
      'parentCommentId': parentCommentId,
    };
  }

  MadingComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userName,
    String? userRole,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    List<String>? likedBy,
    String? parentCommentId,
  }) {
    return MadingComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}

@JsonSerializable()
class Subject {
  final String id;
  final String name;
  final String schoolId;
  final String? description;
  final String? color; // For UI theming

  Subject({
    required this.id,
    required this.name,
    required this.schoolId,
    this.description,
    this.color,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);
  Map<String, dynamic> toJson() => _$SubjectToJson(this);

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      name: data['name'] ?? '',
      schoolId: data['schoolId'] ?? '',
      description: data['description'],
      color: data['color'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'schoolId': schoolId,
      'description': description,
      'color': color,
    };
  }
}