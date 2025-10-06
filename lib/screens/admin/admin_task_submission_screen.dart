import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/task_models.dart';
import '../../services/task_service.dart';

class AdminTaskSubmissionScreen extends StatefulWidget {
  final Task task;

  const AdminTaskSubmissionScreen({super.key, required this.task});

  @override
  State<AdminTaskSubmissionScreen> createState() => _AdminTaskSubmissionScreenState();
}

class _AdminTaskSubmissionScreenState extends State<AdminTaskSubmissionScreen> {
  final TaskService _taskService = TaskService();
  List<TaskSubmissionWithDetails> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final submissions = await _taskService.getSubmissionsWithDetailsByTask(widget.task.id);
      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading submissions: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading submissions: $e')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  Future<void> _updateSubmissionScore(TaskSubmission submission, double? score) async {
    try {
      final updatedSubmission = submission.copyWith(
        score: score,
        gradedAt: score != null ? DateTime.now() : null,
      );
      
      await _taskService.updateTaskSubmission(updatedSubmission.id, updatedSubmission);
      _loadSubmissions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nilai berhasil disimpan')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating score: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating score: $e')),
        );
      }
    }
  }

  void _showScoreDialog(TaskSubmissionWithDetails submissionWithDetails) {
    final submission = submissionWithDetails.submission;
    final scoreController = TextEditingController(
      text: submission.score?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Beri Nilai - ${submissionWithDetails.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tugas: ${widget.task.title}'),
            const SizedBox(height: 8),
            Text('Siswa: ${submissionWithDetails.studentName}'),
            const SizedBox(height: 16),
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(
                labelText: 'Nilai (0-100)',
                border: OutlineInputBorder(),
                hintText: 'Masukkan nilai',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            if (submission.submissionLink.isNotEmpty) ...[
              const Text('Link Pengumpulan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _launchUrl(submission.submissionLink),
                child: Text(
                  submission.submissionLink,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _updateSubmissionScore(submission, null);
              Navigator.of(context).pop();
            },
            child: const Text('Hapus Nilai'),
          ),
          ElevatedButton(
            onPressed: () {
              final scoreText = scoreController.text.trim();
              if (scoreText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mohon masukkan nilai')),
                );
                return;
              }
              
              final score = double.tryParse(scoreText);
              if (score == null || score < 0 || score > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nilai harus antara 0-100')),
                );
                return;
              }
              
              _updateSubmissionScore(submission, score);
              Navigator.of(context).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskSubmission submission) {
    if (submission.score != null) {
      return Colors.green;
    } else if (submission.submissionLink.isNotEmpty) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText(TaskSubmission submission) {
    if (submission.score != null) {
      return 'Dinilai (${submission.score})';
    } else if (submission.submissionLink.isNotEmpty) {
      return 'Sudah Mengumpulkan';
    } else {
      return 'Belum Mengumpulkan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final submittedCount = _submissions.where((s) => s.submission.submissionLink.isNotEmpty).length;
    final gradedCount = _submissions.where((s) => s.submission.score != null).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumpulan - ${widget.task.title}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Total Siswa: ${_submissions.length}'),
                Text('Sudah Mengumpulkan: $submittedCount'),
                Text('Sudah Dinilai: $gradedCount'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _submissions.isEmpty ? 0 : submittedCount / _submissions.length,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(_submissions.isEmpty ? 0 : (submittedCount / _submissions.length * 100)).toStringAsFixed(0)}%'),
                  ],
                ),
              ],
            ),
          ),
          
          // Submissions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadSubmissions,
                    child: _submissions.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada pengumpulan',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _submissions.length,
                            itemBuilder: (context, index) {
                              final submissionWithDetails = _submissions[index];
                              final submission = submissionWithDetails.submission;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(submission),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    submissionWithDetails.studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Status: ${_getStatusText(submission)}'),
                                      Text('Dikumpulkan: ${submission.submissionDate.day}/${submission.submissionDate.month}/${submission.submissionDate.year} ${submission.submissionDate.hour.toString().padLeft(2, '0')}:${submission.submissionDate.minute.toString().padLeft(2, '0')}'),
                                      if (submission.gradedAt != null)
                                        Text('Dinilai: ${submission.gradedAt!.day}/${submission.gradedAt!.month}/${submission.gradedAt!.year}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (submission.submissionLink.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.link),
                                          onPressed: () => _launchUrl(submission.submissionLink),
                                          tooltip: 'Buka Link',
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.grade),
                                        onPressed: () => _showScoreDialog(submissionWithDetails),
                                        tooltip: 'Beri Nilai',
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showScoreDialog(submissionWithDetails),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}