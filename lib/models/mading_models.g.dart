// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mading_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MadingPost _$MadingPostFromJson(Map<String, dynamic> json) => MadingPost(
  id: json['id'] as String,
  imageUrl: json['imageUrl'] as String,
  schoolId: json['schoolId'] as String,
  subjectId: json['subjectId'] as String?,
  studentId: json['studentId'] as String,
  studentName: json['studentName'] as String,
  studentClass: json['studentClass'] as String,
  description: json['description'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
  likedBy:
      (json['likedBy'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isApproved: json['isApproved'] as bool? ?? false,
  approvedBy: json['approvedBy'] as String?,
);

Map<String, dynamic> _$MadingPostToJson(MadingPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imageUrl': instance.imageUrl,
      'schoolId': instance.schoolId,
      'subjectId': instance.subjectId,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'studentClass': instance.studentClass,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'likesCount': instance.likesCount,
      'commentsCount': instance.commentsCount,
      'likedBy': instance.likedBy,
      'isApproved': instance.isApproved,
      'approvedBy': instance.approvedBy,
    };

MadingComment _$MadingCommentFromJson(Map<String, dynamic> json) =>
    MadingComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userRole: json['userRole'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      likedBy:
          (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      parentCommentId: json['parentCommentId'] as String?,
    );

Map<String, dynamic> _$MadingCommentToJson(MadingComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'userId': instance.userId,
      'userName': instance.userName,
      'userRole': instance.userRole,
      'comment': instance.comment,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'likesCount': instance.likesCount,
      'likedBy': instance.likedBy,
      'parentCommentId': instance.parentCommentId,
    };

Subject _$SubjectFromJson(Map<String, dynamic> json) => Subject(
  id: json['id'] as String,
  name: json['name'] as String,
  schoolId: json['schoolId'] as String,
  description: json['description'] as String?,
  color: json['color'] as String?,
);

Map<String, dynamic> _$SubjectToJson(Subject instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'schoolId': instance.schoolId,
  'description': instance.description,
  'color': instance.color,
};
