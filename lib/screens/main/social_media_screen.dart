import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/social_media_models.dart';
import '../../services/social_media_service.dart';
import '../../services/auth_service.dart';
import 'create_post_screen.dart';
import 'profile_detail_screen.dart';
import 'post_detail_screen.dart';

class SocialMediaScreen extends StatefulWidget {
  const SocialMediaScreen({super.key});

  @override
  State<SocialMediaScreen> createState() => _SocialMediaScreenState();
}

class _SocialMediaScreenState extends State<SocialMediaScreen>
    with SingleTickerProviderStateMixin {
  final SocialMediaService _socialMediaService = SocialMediaService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  PostType? _selectedFilter;
  String? _currentClassCode;
  String? _currentUserName;
  List<SocialMediaPost> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  StreamSubscription<List<SocialMediaPost>>? _postsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadUserClassCode();
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserClassCode() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      setState(() {
        _currentClassCode = userProfile?.classCode;
        _currentUserName = userProfile?.name ?? 'User';
      });
    } catch (e) {
      debugPrint('Error loading class code: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    
    // Cancel previous subscription to prevent multiple streams
    await _postsSubscription?.cancel();
    
    setState(() {
      _isLoading = true;
      _posts.clear();
      _hasMore = true;
    });

    try {
      String? classCodeFilter;
      if (_tabController.index == 1) {
        classCodeFilter = _currentClassCode;
      }
      
      _postsSubscription = _socialMediaService
          .getPostsFeed(
            limit: 10, 
            filterType: _selectedFilter,
            classCode: classCodeFilter,
          )
          .listen(
            (posts) {
              if (mounted) {
                setState(() {
                  _posts = posts;
                  _isLoading = false;
                  _hasMore = posts.length >= 10; // Update hasMore based on results
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);

    try {
      // Implementasi pagination akan ditambahkan di sini
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  void _onTabChanged() {
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Slightly warmer background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            // Logo/Icon with modern gradient
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF404040)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.1),
                     blurRadius: 8,
                     offset: const Offset(0, 2),
                   ),
                 ],
              ),
              child: const Icon(
                LucideIcons.atSign,
                color: Colors.white,
                size: 20,
              ),
            ),
            const Spacer(),
            // Menu icon with modern styling
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  LucideIcons.menu,
                  color: Color(0xFF1A1A1A),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.05),
                   blurRadius: 4,
                   offset: const Offset(0, 1),
                 ),
               ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(0);
                      _onTabChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabController.index == 0 
                                ? const Color(0xFF1A1A1A)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'For you',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _tabController.index == 0 
                              ? FontWeight.w700 
                              : FontWeight.w500,
                          color: _tabController.index == 0 
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF666666),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(1);
                      _onTabChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabController.index == 1 
                                ? const Color(0xFF1A1A1A)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _currentClassCode ?? 'Kelas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _tabController.index == 1 
                              ? FontWeight.w700 
                              : FontWeight.w500,
                          color: _tabController.index == 1 
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF666666),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          _buildPostsList(isClassTab: false),
          _buildPostsList(isClassTab: true),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.15),
               blurRadius: 12,
               offset: const Offset(0, 4),
             ),
           ],
        ),
        child: FloatingActionButton(
          onPressed: () => _navigateToCreatePost(),
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildPostsList({required bool isClassTab}) {
    // Filter posts based on tab - create a safe copy
    List<SocialMediaPost> filteredPosts = List.from(_posts);
    
    if (isClassTab) {
      if (_currentClassCode == null || _currentClassCode!.isEmpty) {
        // If no class code, show empty state
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  LucideIcons.users,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tidak ada kode kelas',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda belum terdaftar di kelas manapun',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }
      // Filter posts by class code - create a safe filtered list
      filteredPosts = _posts.where((post) => post.classCode == _currentClassCode).toList();
    }

    if (_isLoading && filteredPosts.isEmpty) {
      return Column(
        children: [
          _buildPostingSection(isClassTab: isClassTab),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            ),
          ),
        ],
      );
    }

    if (filteredPosts.isEmpty) {
      return Column(
        children: [
          _buildPostingSection(isClassTab: isClassTab),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      LucideIcons.messageSquare,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isClassTab ? 'Belum ada postingan di kelas' : 'Belum ada postingan',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isClassTab 
                        ? 'Jadilah yang pertama membuat postingan di kelas $_currentClassCode!'
                        : 'Jadilah yang pertama membuat postingan!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        itemCount: filteredPosts.length + 1 + (_hasMore ? 1 : 0), // +1 for posting section
        itemBuilder: (context, index) {
          // First item is the posting section
          if (index == 0) {
            return _buildPostingSection(isClassTab: isClassTab);
          }
          
          // Adjust index for posts
          final postIndex = index - 1;
          
          if (postIndex == filteredPosts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            );
          }

          // Add bounds checking to prevent RangeError
          if (postIndex >= filteredPosts.length) {
            return const SizedBox.shrink();
          }

          return _buildThreadsPostCard(filteredPosts[postIndex]);
        },
      ),
    );
  }

  Widget _buildPostingSection({required bool isClassTab}) {
     return Container(
       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha: 0.04),
             blurRadius: 6,
             offset: const Offset(0, 1),
           ),
         ],
       ),
       child: Material(
         color: Colors.transparent,
         child: InkWell(
           onTap: () {
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => const CreatePostScreen(),
               ),
             );
           },
           borderRadius: BorderRadius.circular(12),
           child: Padding(
             padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture with modern styling
                 Container(
                   width: 36,
                   height: 36,
                   margin: EdgeInsets.only(bottom: 6),
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       colors: [
                         Colors.grey[200]!,
                         Colors.grey[300]!,
                       ],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                     ),
                     borderRadius: BorderRadius.circular(18),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.06),
                         blurRadius: 3,
                         offset: const Offset(0, 1),
                       ),
                     ],
                   ),
                   child: Center(
                     child: Text(
                       (_currentUserName != null && _currentUserName!.isNotEmpty)
                           ? _currentUserName![0].toUpperCase()
                           : 'U',
                       style: const TextStyle(
                         color: Color(0xFF1A1A1A),
                         fontWeight: FontWeight.w700,
                         fontSize: 16,
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(width: 12),
                // Post Input Section
                Expanded(
                  child: Text(
                    isClassTab 
                        ? 'Apa yang ingin kamu bagikan di kelas $_currentClassCode?'
                        : 'Mau Cerita Apa?',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                // Add subtle arrow indicator
                Icon(
                  LucideIcons.edit3,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreadsPostCard(SocialMediaPost post) {
     return Container(
       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha: 0.04),
             blurRadius: 6,
             offset: const Offset(0, 1),
           ),
         ],
       ),
       child: Material(
         color: Colors.transparent,
         child: InkWell(
           onTap: () => _navigateToPostDetail(post),
           borderRadius: BorderRadius.circular(12),
           child: Padding(
             padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture with modern styling
                GestureDetector(
                   onTap: () => _navigateToProfile(post.authorId, post.authorName),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue[100]!,
                          Colors.blue[200]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.blue.withValues(alpha: 0.15),
                           blurRadius: 3,
                           offset: const Offset(0, 1),
                         ),
                       ],
                    ),
                    child: Center(
                      child: Text(
                       (post.authorName.isNotEmpty)
                           ? post.authorName[0].toUpperCase()
                           : 'U',
                       style: const TextStyle(
                         color: Color(0xFF1565C0),
                         fontWeight: FontWeight.w700,
                         fontSize: 16,
                       ),
                     ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Post Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with username and time
                      Row(
                        children: [
                          GestureDetector(
                           onTap: () => _navigateToProfile(post.authorId, post.authorName),
                           child: Text(
                             post.authorName,
                             style: const TextStyle(
                               fontWeight: FontWeight.w600,
                               fontSize: 14,
                               color: Color(0xFF1A1A1A),
                             ),
                           ),
                         ),
                         const SizedBox(width: 6),
                         Container(
                           width: 3,
                           height: 3,
                           decoration: BoxDecoration(
                             color: Colors.grey[400],
                             borderRadius: BorderRadius.circular(1.5),
                           ),
                         ),
                         const SizedBox(width: 6),
                         Text(
                           _formatDateTime(post.createdAt),
                           style: TextStyle(
                             color: Colors.grey[500],
                             fontSize: 12,
                             fontWeight: FontWeight.w400,
                           ),
                         ),
                         const Spacer(),
                         if (post.authorId == _socialMediaService.currentUserId)
                           Container(
                             decoration: BoxDecoration(
                               color: Colors.grey[50],
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: PopupMenuButton<String>(
                               onSelected: (value) => _handlePostAction(value, post),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.edit2, size: 16),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Hapus', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    LucideIcons.moreHorizontal,
                                    color: Colors.grey[600],
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Post content with better typography
                     Text(
                       post.content,
                       style: const TextStyle(
                         fontSize: 14,
                         height: 1.4,
                         color: Color(0xFF2A2A2A),
                       ),
                     ),
                     if (post.isModerated)
                       Container(
                         margin: const EdgeInsets.only(top: 12),
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         decoration: BoxDecoration(
                           color: const Color(0xFFFEF3C7),
                           borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD97706), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.shield,
                                size: 16,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Konten telah dimoderasi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Action buttons with modern styling
                      Row(
                        children: [
                          _buildThreadsActionButton(
                           icon: post.likedBy.contains(_socialMediaService.currentUserId) ? LucideIcons.heart : LucideIcons.heart,
                           label: '${post.likesCount}',
                           color: post.likedBy.contains(_socialMediaService.currentUserId) ? Colors.red : Colors.grey[600]!,
                           onTap: () => _toggleLike(post.id),
                         ),
                         const SizedBox(width: 16),
                         _buildThreadsActionButton(
                           icon: LucideIcons.messageCircle,
                           label: '${post.commentsCount}',
                           color: Colors.grey[600]!,
                           onTap: () => _navigateToPostDetail(post),
                         ),
                         const SizedBox(width: 16),
                        //  _buildThreadsActionButton(
                        //    icon: LucideIcons.repeat2,
                        //    label: 'Share',
                        //    color: Colors.grey[600]!,
                        //    onTap: () => _sharePost(post),
                        //  ),
                        //  const SizedBox(width: 16),
                        //  _buildThreadsActionButton(
                        //    icon: LucideIcons.send,
                        //    label: 'Send',
                        //    color: Colors.grey[600]!,
                        //    onTap: () => _sharePost(post),
                        //  ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreadsActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}j';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }



  Future<void> _toggleLike(String postId) async {
    try {
      await _socialMediaService.togglePostLike(postId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handlePostAction(String action, SocialMediaPost post) {
    switch (action) {
      case 'edit':
        _editPost(post);
        break;
      case 'delete':
        _deletePost(post);
        break;
    }
  }

  void _editPost(SocialMediaPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          editPost: post,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadPosts();
      }
    });
  }

  Future<void> _deletePost(SocialMediaPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: const Text('Apakah Anda yakin ingin menghapus postingan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _socialMediaService.deletePost(post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Postingan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadPosts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }



  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  void _navigateToPostDetail(SocialMediaPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }

  void _navigateToProfile(String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          userId: userId,
          userName: userName,
        ),
      ),
    );
  }

}