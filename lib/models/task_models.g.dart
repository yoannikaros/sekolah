// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: json['id'] as String,
  teacherId: json['teacherId'] as String,
  subjectId: json['subjectId'] as String,
  chapterId: json['chapterId'] as String?,
  title: json['title'] as String,
  description: json['description'] as String,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  openDate: const DateTimeConverter().fromJson(json['openDate']),
  dueDate: const DateTimeConverter().fromJson(json['dueDate']),
  taskLink: json['taskLink'] as String,
  isActive: json['isActive'] as bool? ?? true,
  updatedAt: const NullableDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'teacherId': instance.teacherId,
  'subjectId': instance.subjectId,
  'chapterId': instance.chapterId,
  'title': instance.title,
  'description': instance.description,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'openDate': const DateTimeConverter().toJson(instance.openDate),
  'dueDate': const DateTimeConverter().toJson(instance.dueDate),
  'taskLink': instance.taskLink,
  'isActive': instance.isActive,
  'updatedAt': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

TaskClass _$TaskClassFromJson(Map<String, dynamic> json) => TaskClass(
  id: json['id'] as String,
  taskId: json['taskId'] as String,
  classId: json['classId'] as String,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$TaskClassToJson(TaskClass instance) => <String, dynamic>{
  'id': instance.id,
  'taskId': instance.taskId,
  'classId': instance.classId,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'isActive': instance.isActive,
};

TaskSubmission _$TaskSubmissionFromJson(Map<String, dynamic> json) =>
    TaskSubmission(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      studentId: json['studentId'] as String,
      submissionLink: json['submissionLink'] as String,
      submissionDate: const DateTimeConverter().fromJson(
        json['submissionDate'],
      ),
      notes: json['notes'] as String?,
      isLate: json['isLate'] as bool? ?? false,
      gradedAt: const NullableDateTimeConverter().fromJson(json['gradedAt']),
      score: (json['score'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$TaskSubmissionToJson(
  TaskSubmission instance,
) => <String, dynamic>{
  'id': instance.id,
  'taskId': instance.taskId,
  'studentId': instance.studentId,
  'submissionLink': instance.submissionLink,
  'submissionDate': const DateTimeConverter().toJson(instance.submissionDate),
  'notes': instance.notes,
  'isLate': instance.isLate,
  'gradedAt': const NullableDateTimeConverter().toJson(instance.gradedAt),
  'score': instance.score,
  'feedback': instance.feedback,
  'isActive': instance.isActive,
};

TaskWithDetails _$TaskWithDetailsFromJson(Map<String, dynamic> json) =>
    TaskWithDetails(
      task: Task.fromJson(json['task'] as Map<String, dynamic>),
      teacherName: json['teacherName'] as String,
      subjectName: json['subjectName'] as String,
      classNames:
          (json['classNames'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      submissionCount: (json['submissionCount'] as num).toInt(),
      totalStudents: (json['totalStudents'] as num).toInt(),
    );

Map<String, dynamic> _$TaskWithDetailsToJson(TaskWithDetails instance) =>
    <String, dynamic>{
      'task': instance.task,
      'teacherName': instance.teacherName,
      'subjectName': instance.subjectName,
      'classNames': instance.classNames,
      'submissionCount': instance.submissionCount,
      'totalStudents': instance.totalStudents,
    };

TaskSubmissionWithDetails _$TaskSubmissionWithDetailsFromJson(
  Map<String, dynamic> json,
) => TaskSubmissionWithDetails(
  submission: TaskSubmission.fromJson(
    json['submission'] as Map<String, dynamic>,
  ),
  studentName: json['studentName'] as String,
  taskTitle: json['taskTitle'] as String,
);

Map<String, dynamic> _$TaskSubmissionWithDetailsToJson(
  TaskSubmissionWithDetails instance,
) => <String, dynamic>{
  'submission': instance.submission,
  'studentName': instance.studentName,
  'taskTitle': instance.taskTitle,
};
