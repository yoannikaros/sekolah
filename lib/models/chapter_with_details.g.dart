// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter_with_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChapterWithDetails _$ChapterWithDetailsFromJson(Map<String, dynamic> json) =>
    ChapterWithDetails(
      chapter: Chapter.fromJson(json['chapter'] as Map<String, dynamic>),
      teacherName: json['teacherName'] as String,
      subjectName: json['subjectName'] as String,
      totalTasks: (json['totalTasks'] as num).toInt(),
      activeTasks: (json['activeTasks'] as num).toInt(),
    );

Map<String, dynamic> _$ChapterWithDetailsToJson(ChapterWithDetails instance) =>
    <String, dynamic>{
      'chapter': instance.chapter,
      'teacherName': instance.teacherName,
      'subjectName': instance.subjectName,
      'totalTasks': instance.totalTasks,
      'activeTasks': instance.activeTasks,
    };
