import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mading/post_card.dart';
import '../../widgets/mading/post_filter_chip.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class MadingScreen extends StatefulWidget {
  const MadingScreen({super.key});

  @override
  State<MadingScreen> createState() => _MadingScreenState();
}

class _MadingScreenState extends State<MadingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  PostType? _selectedType;
  PostStatus? _selectedStatus;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load posts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _onFilterChanged({PostType? type, PostStatus? status}) {
    setState(() {
      _selectedType = type;
      _selectedStatus = status;
    });
    
    context.read<PostProvider>().fetchPosts(
      type: type,
      status: status,
    );
  }
  
  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    ).then((_) {
      // Refresh posts after creating new post
      if (mounted) {
        context.read<PostProvider>().refreshPosts();
      }
    });
  }
  
  void _navigateToPostDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mading Online',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.filter, color: Colors.white),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Karya Seni'),
            Tab(text: 'Tugas'),
            Tab(text: 'Proyek'),
          ],
          onTap: (index) {
            PostType? filterType;
            switch (index) {
              case 1:
                filterType = PostType.artwork;
                break;
              case 2:
                filterType = PostType.assignment;
                break;
              case 3:
                filterType = PostType.project;
                break;
              default:
                filterType = null;
            }
            _onFilterChanged(type: filterType);
          },
        ),
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (postProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi Kesalahan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    postProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      postProvider.clearError();
                      postProvider.refreshPosts();
                    },
                    icon: const Icon(LucideIcons.refreshCw),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          
          final posts = postProvider.approvedPosts;
          
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.fileText,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Postingan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jadilah yang pertama membuat postingan!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToCreatePost,
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Buat Postingan'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => postProvider.refreshPosts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PostCard(
                    post: post,
                    onTap: () => _navigateToPostDetail(post),
                    onLike: () => postProvider.toggleLike(post.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Only show FAB if user is logged in
          if (!authProvider.isAuthenticated) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: _navigateToCreatePost,
            backgroundColor: Colors.blue[600],
            child: const Icon(
              LucideIcons.plus,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
  
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Postingan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Type Filter
              Text(
                'Jenis Postingan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  PostFilterChip(
                    label: 'Semua',
                    isSelected: _selectedType == null,
                    onTap: () => _onFilterChanged(type: null),
                  ),
                  PostFilterChip(
                    label: 'Karya Seni',
                    isSelected: _selectedType == PostType.artwork,
                    onTap: () => _onFilterChanged(type: PostType.artwork),
                  ),
                  PostFilterChip(
                    label: 'Tugas',
                    isSelected: _selectedType == PostType.assignment,
                    onTap: () => _onFilterChanged(type: PostType.assignment),
                  ),
                  PostFilterChip(
                    label: 'Proyek',
                    isSelected: _selectedType == PostType.project,
                    onTap: () => _onFilterChanged(type: PostType.project),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Status Filter (for teachers/admins)
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.user;
                  if (user?.role == 'teacher' || user?.role == 'school_admin') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Postingan',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            PostFilterChip(
                              label: 'Semua',
                              isSelected: _selectedStatus == null,
                              onTap: () => _onFilterChanged(status: null),
                            ),
                            PostFilterChip(
                              label: 'Menunggu',
                              isSelected: _selectedStatus == PostStatus.pending,
                              onTap: () => _onFilterChanged(status: PostStatus.pending),
                            ),
                            PostFilterChip(
                              label: 'Disetujui',
                              isSelected: _selectedStatus == PostStatus.approved,
                              onTap: () => _onFilterChanged(status: PostStatus.approved),
                            ),
                            PostFilterChip(
                              label: 'Ditolak',
                              isSelected: _selectedStatus == PostStatus.rejected,
                              onTap: () => _onFilterChanged(status: PostStatus.rejected),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // Clear Filter Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _onFilterChanged(type: null, status: null);
                    Navigator.pop(context);
                  },
                  child: const Text('Hapus Filter'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}