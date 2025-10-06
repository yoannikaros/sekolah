import 'package:json_annotation/json_annotation.dart';
import 'chapter_models.dart';

part 'chapter_with_details.g.dart';

@JsonSerializable()
class ChapterWithDetails {
  final Chapter chapter;
  final String teacherName;
  final String subjectName;
  final int totalTasks;
  final int activeTasks;

  ChapterWithDetails({
    required this.chapter,
    required this.teacherName,
    required this.subjectName,
    required this.totalTasks,
    required this.activeTasks,
  });

  factory ChapterWithDetails.fromJson(Map<String, dynamic> json) =>
      _$ChapterWithDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterWithDetailsToJson(this);
}