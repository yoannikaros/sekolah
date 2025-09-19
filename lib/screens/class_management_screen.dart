import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClassManagementScreen extends StatelessWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kelas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Manajemen Kelas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Fitur ini akan segera hadir',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}