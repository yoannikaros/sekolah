import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/mading_models.dart';
import '../../services/mading_service.dart';

class MadingManagementScreen extends StatefulWidget {
  const MadingManagementScreen({super.key});

  @override
  State<MadingManagementScreen> createState() => _MadingManagementScreenState();
}

class _MadingManagementScreenState extends State<MadingManagementScreen>
    with SingleTickerProviderStateMixin {
  final MadingService _madingService = MadingService();
  List<MadingPost> _posts = [];
  List<MadingComment> _pendingComments = [];
  bool _isLoading = true;
  late TabController _tabController;
  MadingFilter _currentFilter = MadingFilter();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _madingService.getAllMadingPosts(filter: _currentFilter);
      final pendingComments = await _madingService.getPendingComments();
      
      if (kDebugMode) {
        print('Loaded ${posts.length} mading posts');
        print('Loaded ${pendingComments.length} pending comments');
      }
      
      setState(() {
        _posts = posts;
        _pendingComments = pendingComments;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading mading data: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _showPostDialog({MadingPost? post}) async {
    final titleController = TextEditingController(text: post?.title ?? '');
    final descriptionController = TextEditingController(text: post?.description ?? '');
    final classCodeController = TextEditingController(text: post?.classCode ?? '');
    final schoolIdController = TextEditingController(text: post?.schoolId ?? '');
    final imageUrlController = TextEditingController(text: post?.imageUrl ?? '');
    final documentUrlController = TextEditingController(text: post?.documentUrl ?? '');
    final tagsController = TextEditingController(text: post?.tags.join(', ') ?? '');
    
    MadingType selectedType = post?.type ?? MadingType.studentWork;
    MadingStatus selectedStatus = post?.status ?? MadingStatus.draft;
    DateTime? selectedDueDate = post?.dueDate;
    bool isPublished = post?.isPublished ?? false;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(post == null ? 'Tambah Post Mading' : 'Edit Post Mading'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: schoolIdController,
                              decoration: const InputDecoration(
                                labelText: 'ID Sekolah',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: classCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Kode Kelas',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<MadingType>(
                              value: selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Tipe',
                                border: OutlineInputBorder(),
                              ),
                              items: MadingType.values.map((type) {
                                String label;
                                switch (type) {
                                  case MadingType.assignment:
                                    label = 'Tugas';
                                    break;
                                  case MadingType.studentWork:
                                    label = 'Karya Siswa';
                                    break;
                                  case MadingType.announcement:
                                    label = 'Pengumuman';
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<MadingStatus>(
                              value: selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: MadingStatus.values.map((status) {
                                String label;
                                switch (status) {
                                  case MadingStatus.draft:
                                    label = 'Draft';
                                    break;
                                  case MadingStatus.published:
                                    label = 'Dipublikasi';
                                    break;
                                  case MadingStatus.archived:
                                    label = 'Diarsipkan';
                                    break;
                                  case MadingStatus.rejected:
                                    label = 'Ditolak';
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(label),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedStatus = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Gambar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: documentUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Dokumen',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (pisahkan dengan koma)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (selectedType == MadingType.assignment)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedDueDate == null
                                    ? 'Pilih Tanggal Deadline'
                                    : 'Deadline: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}',
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDueDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    selectedDueDate = date;
                                  });
                                }
                              },
                              child: const Text('Pilih Tanggal'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Publikasikan'),
                        value: isPublished,
                        onChanged: (value) {
                          setDialogState(() {
                            isPublished = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        schoolIdController.text.isEmpty ||
                        classCodeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mohon lengkapi semua field yang wajib')),
                      );
                      return;
                    }

                    final tags = tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();

                    final newPost = MadingPost(
                      id: post?.id ?? '',
                      title: titleController.text,
                      description: descriptionController.text,
                      imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
                      documentUrl: documentUrlController.text.isEmpty ? null : documentUrlController.text,
                      authorId: 'admin', // TODO: Get from current admin user
                      authorName: 'Admin', // TODO: Get from current admin user
                      schoolId: schoolIdController.text,
                      classCode: classCodeController.text,
                      type: selectedType,
                      status: selectedStatus,
                      createdAt: post?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                      dueDate: selectedDueDate,
                      tags: tags,
                      isPublished: isPublished,
                    );

                    // Store context reference before async operation
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    bool success;
                    if (post == null) {
                      final id = await _madingService.createMadingPost(newPost);
                      success = id != null;
                    } else {
                      success = await _madingService.updateMadingPost(post.id, newPost);
                    }

                    if (success) {
                      navigator.pop();
                      _loadData();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(post == null
                              ? 'Post berhasil ditambahkan'
                              : 'Post berhasil diperbarui'),
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Gagal menyimpan post')),
                      );
                    }
                  },
                  child: Text(post == null ? 'Tambah' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePost(MadingPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus post "${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _madingService.deleteMadingPost(post.id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post berhasil dihapus')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus post')),
          );
        }
      }
    }
  }

  Future<void> _approveComment(MadingComment comment) async {
    final success = await _madingService.approveComment(comment.id, 'admin'); // TODO: Get admin ID
    if (success) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar berhasil disetujui')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyetujui komentar')),
        );
      }
    }
  }

  Future<void> _deleteComment(MadingComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _madingService.deleteComment(comment.id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komentar berhasil dihapus')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus komentar')),
          );
        }
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Posts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MadingType?>(
                value: _currentFilter.type,
                decoration: const InputDecoration(
                  labelText: 'Tipe',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<MadingType?>(
                    value: null,
                    child: Text('Semua Tipe'),
                  ),
                  ...MadingType.values.map((type) {
                    String label;
                    switch (type) {
                      case MadingType.assignment:
                        label = 'Tugas';
                        break;
                      case MadingType.studentWork:
                        label = 'Karya Siswa';
                        break;
                      case MadingType.announcement:
                        label = 'Pengumuman';
                        break;
                    }
                    return DropdownMenuItem(
                      value: type,
                      child: Text(label),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(type: value);
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MadingStatus?>(
                value: _currentFilter.status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<MadingStatus?>(
                    value: null,
                    child: Text('Semua Status'),
                  ),
                  ...MadingStatus.values.map((status) {
                    String label;
                    switch (status) {
                      case MadingStatus.draft:
                        label = 'Draft';
                        break;
                      case MadingStatus.published:
                        label = 'Dipublikasi';
                        break;
                      case MadingStatus.archived:
                        label = 'Diarsipkan';
                        break;
                      case MadingStatus.rejected:
                        label = 'Ditolak';
                        break;
                    }
                    return DropdownMenuItem(
                      value: status,
                      child: Text(label),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(status: value);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _currentFilter = MadingFilter();
                });
                Navigator.of(context).pop();
                _loadData();
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadData();
              },
              child: const Text('Terapkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Mading Online'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Posts (${_posts.length})',
              icon: const Icon(Icons.article),
            ),
            Tab(
              text: 'Komentar Pending (${_pendingComments.length})',
              icon: const Icon(Icons.comment),
            ),
            const Tab(
              text: 'Statistik',
              icon: Icon(Icons.analytics),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildCommentsTab(),
                _buildStatisticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada post mading'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(post.type),
              child: Icon(
                _getTypeIcon(post.type),
                color: Colors.white,
              ),
            ),
            title: Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(_getTypeLabel(post.type)),
                      backgroundColor: _getTypeColor(post.type).withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_getStatusLabel(post.status)),
                      backgroundColor: _getStatusColor(post.status).withValues(alpha: 0.2),
                    ),
                  ],
                ),
                Text(
                  'Kelas: ${post.classCode} | Likes: ${post.likesCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: post.isPublished ? 'unpublish' : 'publish',
                  child: Row(
                    children: [
                      Icon(post.isPublished ? Icons.visibility_off : Icons.visibility),
                      const SizedBox(width: 8),
                      Text(post.isPublished ? 'Sembunyikan' : 'Publikasikan'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    _showPostDialog(post: post);
                    break;
                  case 'publish':
                    await _madingService.publishPost(post.id);
                    _loadData();
                    break;
                  case 'unpublish':
                    await _madingService.updateMadingPost(
                      post.id,
                      post.copyWith(isPublished: false),
                    );
                    _loadData();
                    break;
                  case 'delete':
                    _deletePost(post);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    if (_pendingComments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tidak ada komentar yang menunggu persetujuan'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingComments.length,
      itemBuilder: (context, index) {
        final comment = _pendingComments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.comment, color: Colors.white),
            ),
            title: Text(comment.authorName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  'Post ID: ${comment.postId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _approveComment(comment),
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Setujui',
                ),
                IconButton(
                  onPressed: () => _deleteComment(comment),
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Tolak',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    final totalPosts = _posts.length;
    final publishedPosts = _posts.where((p) => p.isPublished).length;
    final assignments = _posts.where((p) => p.type == MadingType.assignment).length;
    final studentWorks = _posts.where((p) => p.type == MadingType.studentWork).length;
    final announcements = _posts.where((p) => p.type == MadingType.announcement).length;
    final totalLikes = _posts.fold<int>(0, (sum, post) => sum + post.likesCount);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistik Mading Online',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem('Total Posts', totalPosts.toString()),
                  _buildStatItem('Posts Dipublikasi', publishedPosts.toString()),
                  _buildStatItem('Total Likes', totalLikes.toString()),
                  _buildStatItem('Komentar Pending', _pendingComments.length.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berdasarkan Tipe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem('Tugas', assignments.toString()),
                  _buildStatItem('Karya Siswa', studentWorks.toString()),
                  _buildStatItem('Pengumuman', announcements.toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(MadingType type) {
    switch (type) {
      case MadingType.assignment:
        return Colors.blue;
      case MadingType.studentWork:
        return Colors.green;
      case MadingType.announcement:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(MadingType type) {
    switch (type) {
      case MadingType.assignment:
        return Icons.assignment;
      case MadingType.studentWork:
        return Icons.palette;
      case MadingType.announcement:
        return Icons.announcement;
    }
  }

  String _getTypeLabel(MadingType type) {
    switch (type) {
      case MadingType.assignment:
        return 'Tugas';
      case MadingType.studentWork:
        return 'Karya Siswa';
      case MadingType.announcement:
        return 'Pengumuman';
    }
  }

  Color _getStatusColor(MadingStatus status) {
    switch (status) {
      case MadingStatus.draft:
        return Colors.grey;
      case MadingStatus.published:
        return Colors.green;
      case MadingStatus.archived:
        return Colors.blue;
      case MadingStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusLabel(MadingStatus status) {
    switch (status) {
      case MadingStatus.draft:
        return 'Draft';
      case MadingStatus.published:
        return 'Dipublikasi';
      case MadingStatus.archived:
        return 'Diarsipkan';
      case MadingStatus.rejected:
        return 'Ditolak';
    }
  }
}