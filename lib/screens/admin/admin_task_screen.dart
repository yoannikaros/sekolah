import 'package:flutter/material.dart';
import 'admin_chapter_screen.dart';

class AdminTaskScreen extends StatelessWidget {
  const AdminTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new chapter-based task management
    return const AdminChapterScreen();
  }
}