import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/social_media_models.dart';
import '../../models/chat_models.dart';
import '../../services/social_media_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../chat/chat_screen.dart';
import 'post_detail_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProfileDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  final SocialMediaService _socialMediaService = SocialMediaService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  UserProfile? _userProfile;
  List<SocialMediaPost> _userPosts = [];
  List<PostComment> _userComments = [];
  List<SocialMediaPost> _likedPosts = [];
  List<SocialMediaPost> _topicPosts = [];
  bool _isLoading = true;
  bool _isLoadingComments = false;
  bool _isFollowing = false;
  String? _currentUserId;

  // Check if viewing current user's profile
  bool get _isCurrentUser => _currentUserId != null && _currentUserId == widget.userId;
  
  // Get tab count based on whether it's current user
  int get _tabCount => _isCurrentUser ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser().then((_) {
      // Initialize TabController after determining if it's current user
      _tabController = TabController(length: _tabCount, vsync: this);
      if (mounted) {
        setState(() {});
      }
      
      // Load liked posts only for current user
      if (_isCurrentUser) {
        _loadLikedPosts();
      }
      
      // Check follow status after current user is loaded
      _checkFollowStatus();
    });
    _loadUserProfile();
    _loadUserPosts();
    _loadUserComments();
    _loadTopicPosts(); // Load topic posts for all users
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userProfile = await _authService.getCurrentUserProfile();
    setState(() {
      _currentUserId = userProfile?.id;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      if (kDebugMode) {
        print('DEBUG: Loading profile for userId: ${widget.userId}');
      }
      
      final profile = await _socialMediaService.getUserProfile(widget.userId);
      
      if (kDebugMode) {
        print('DEBUG: Profile loaded - ${profile != null ? 'Success' : 'Failed'}');
        if (profile != null) {
          print('DEBUG: Profile name: ${profile.name}');
          print('DEBUG: Profile id: ${profile.id}');
        }
      }
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading profile: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: $e')),
        );
      }
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final posts = await _socialMediaService.getUserPosts(widget.userId);
      setState(() {
        _userPosts = posts;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat postingan: $e')),
        );
      }
    }
  }

  Future<void> _loadTopicPosts() async {
    try {
      if (kDebugMode) {
        print('DEBUG: Loading topic posts for userId: ${widget.userId}');
      }
      
      final posts = await _socialMediaService.getUserPosts(widget.userId);
      
      // Filter hanya postingan dengan type topic
      final topicPosts = posts.where((post) => post.type == PostType.topic).toList();
      
      if (kDebugMode) {
        print('DEBUG: Found ${posts.length} total posts, ${topicPosts.length} topic posts');
        for (var post in topicPosts) {
          final contentPreview = post.content.length > 50 
              ? '${post.content.substring(0, 50)}...' 
              : post.content;
          print('DEBUG: Topic Post - ID: ${post.id}, Type: ${post.type}, Content: $contentPreview');
        }
      }
      
      setState(() {
        _topicPosts = topicPosts;
      });
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Error loading topic posts: $e');
      }
      if (mounted) {
        setState(() {
          _topicPosts = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat postingan topik: $e')),
        );
      }
    }
  }

  Future<void> _loadUserComments() async {
    try {
      if (kDebugMode) {
        print('DEBUG: Loading comments for userId: ${widget.userId}');
      }
      
      setState(() {
        _isLoadingComments = true;
      });
      
      _socialMediaService.getCommentsByUser(widget.userId).listen(
        (comments) {
          if (mounted) {
            if (kDebugMode) {
              print('DEBUG: Received ${comments.length} comments in ProfileDetailScreen');
              for (var comment in comments) {
                try {
                  // Validasi data komentar sebelum diproses
                  if (comment.content.isEmpty) {
                    print('DEBUG: Comment ID: ${comment.id}, Content: [Empty content]');
                    continue;
                  }
                  
                  final contentPreview = comment.content.length > 50 
                      ? '${comment.content.substring(0, 50)}...' 
                      : comment.content;
                  print('DEBUG: Comment ID: ${comment.id}, Content: $contentPreview');
                } catch (e) {
                  print('DEBUG: Comment ID: ${comment.id}, Content: [Error displaying content: $e]');
                  print('DEBUG: Comment data: ${comment.toJson()}');
                }
              }
            }
            
            // Filter komentar yang valid sebelum set state
            final validComments = comments.where((comment) {
              return comment.content.isNotEmpty && !comment.isDeleted;
            }).toList();
            
            if (kDebugMode) {
              print('DEBUG: Filtered ${validComments.length} valid comments from ${comments.length} total');
            }
            
            setState(() {
              _userComments = validComments;
              _isLoadingComments = false;
            });
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('DEBUG: Error loading comments in ProfileDetailScreen: $error');
          }
          if (mounted) {
            setState(() {
              _userComments = [];
              _isLoadingComments = false;
            });
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Exception in _loadUserComments: $e');
      }
      if (mounted) {
        setState(() {
          _userComments = [];
          _isLoadingComments = false;
        });
      }
    }
  }

  void _loadLikedPosts() {
    if (!_isCurrentUser) return;
    
    try {
      if (kDebugMode) {
        print('DEBUG: Loading liked posts for current user: ${widget.userId}');
      }
      
      _socialMediaService.getLikedPostsByUser(widget.userId).listen(
        (likedPosts) {
          if (mounted) {
            if (kDebugMode) {
              print('DEBUG: Received ${likedPosts.length} liked posts');
            }
            setState(() {
              _likedPosts = likedPosts;
            });
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('DEBUG: Error loading liked posts: $error');
          }
          if (mounted) {
            setState(() {
              _likedPosts = [];
            });
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Exception in _loadLikedPosts: $e');
      }
      if (mounted) {
        setState(() {
          _likedPosts = [];
        });
      }
    }
  }

  Future<void> _checkFollowStatus() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;
    
    try {
      final isFollowing = await _socialMediaService.isFollowing(_currentUserId!, widget.userId);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      // Handle error silently but log for debugging
      debugPrint('Error checking follow status: $e');
      if (mounted) {
        setState(() {
          _isFollowing = false; // Default to not following on error
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;

    try {
      if (_isFollowing) {
        await _socialMediaService.unfollowUser(widget.userId);
      } else {
        await _socialMediaService.followUser(widget.userId);
      }
      
      setState(() {
        _isFollowing = !_isFollowing;
        if (_userProfile != null) {
          _userProfile = _userProfile!.copyWith(
            followersCount: _isFollowing 
                ? _userProfile!.followersCount + 1 
                : _userProfile!.followersCount - 1,
          );
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing 
                ? 'Berhasil mengikuti ${_userProfile?.name ?? widget.userName}' 
                : 'Berhenti mengikuti ${_userProfile?.name ?? widget.userName}'),
            backgroundColor: _isFollowing ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal ${_isFollowing ? 'berhenti mengikuti' : 'mengikuti'}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _startChat() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;

    try {
      // Check if private chat already exists
      final existingChatRoom = await _chatService.getPrivateChatRoom(_currentUserId!, widget.userId);
      
      ChatRoom chatRoom;
      if (existingChatRoom != null) {
        chatRoom = existingChatRoom;
      } else {
        // Create new private chat room
        final chatRoomId = await _chatService.createChatRoom(
          name: widget.userName,
          participants: [_currentUserId!, widget.userId],
          type: 'private',
        );
        
        chatRoom = ChatRoom(
          id: chatRoomId,
          name: widget.userName,
          participants: [_currentUserId!, widget.userId],
          createdBy: _currentUserId!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          type: 'private',
        );
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(LucideIcons.instagram, color: Colors.black),
          //   onPressed: () {},
          // ),
          // IconButton(
          //   icon: const Icon(LucideIcons.bell, color: Colors.black),
          //   onPressed: () {},
          // ),
          IconButton(
            icon: const Icon(LucideIcons.moreHorizontal, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProfileHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                     controller: _tabController,
                     children: _isCurrentUser
                         ? [
                             _buildPostsTab(),
                             _buildRepliesTab(),
                             _buildMediaTab(),
                             _buildTopicTab(),
                           ]
                         : [
                             _buildPostsTab(),
                             _buildRepliesTab(),
                             _buildTopicTab(),
                           ],
                   ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile info row
          Row(
            children: [
              // Profile avatar
              CircleAvatar(
                radius: 40,
                backgroundImage: _userProfile?.avatar != null
                    ? NetworkImage(_userProfile!.avatar!)
                    : null,
                child: _userProfile?.avatar == null
                    ? const Icon(
                        LucideIcons.user,
                        size: 40,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      _userPosts.length.toString(),
                      'postingan',
                    ),
                    _buildStatColumn(
                      _userProfile?.followersCount.toString() ?? '0',
                      'pengikut',
                    ),
                    _buildStatColumn(
                      _userProfile?.followingCount.toString() ?? '0',
                      'mengikuti',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Name and username
          Text(
            _userProfile?.name ?? (widget.userName.isNotEmpty ? widget.userName : 'Loading...'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (widget.userName.isNotEmpty)
            Text(
              '@${widget.userName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _userProfile!.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Action Buttons - Hide when viewing own profile
          if (_currentUserId != null && _currentUserId != widget.userId)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? Colors.grey[200] : Colors.black,
                      foregroundColor: _isFollowing ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: _isFollowing 
                            ? BorderSide(color: Colors.grey[300]!)
                            : BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      _isFollowing ? 'Mengikuti' : 'Ikuti',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _startChat,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Kirim Pesan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.black,
        indicatorWeight: 1,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: _isCurrentUser
            ? const [
                Tab(text: 'Status'),
                Tab(text: 'Balasan'),
                Tab(text: 'Suka'),
                Tab(text: 'Topik'),
              ]
            : const [
                Tab(text: 'Status'),
                Tab(text: 'Balasan'),
                Tab(text: 'Topik'),
              ],
      ),
    );
  }

  Widget _buildMediaTab() {
    if (!_isCurrentUser) {
      // This should not be called for non-current users, but just in case
      return const SizedBox.shrink();
    }

    if (_likedPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.heart,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada postingan yang disukai',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedPosts.length,
      itemBuilder: (context, index) {
        return _buildLikedPostCard(_likedPosts[index]);
      },
    );
  }

  Widget _buildLikedPostCard(SocialMediaPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pink[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.heart,
                          size: 12,
                          color: Colors.pink[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Disukai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.pink[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.heart,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    LucideIcons.messageCircle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Oleh: ${post.authorName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepliesTab() {
    if (kDebugMode) {
      print('DEBUG: Building replies tab - isLoading: $_isLoadingComments, comments count: ${_userComments.length}');
    }
    
    if (_isLoadingComments) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_userComments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada balasan',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Komentar yang Anda buat akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (kDebugMode) {
      print('DEBUG: Displaying ${_userComments.length} comments in replies tab');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userComments.length,
      itemBuilder: (context, index) {
        if (kDebugMode) {
          print('DEBUG: Building comment card for index $index');
        }
        return _buildCommentCard(_userComments[index]);
      },
    );
  }

  Widget _buildCommentCard(PostComment comment) {
    if (kDebugMode) {
      print('DEBUG: Building comment card for comment ID: ${comment.id}');
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Balasan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(comment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  LucideIcons.heart,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${comment.likesCount}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Post ID: ${comment.postId.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_userPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.fileText,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada postingan',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(_userPosts[index]);
      },
    );
  }

  Widget _buildPostCard(SocialMediaPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Post type indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: post.type == PostType.topic 
                          ? const Color(0xFF667EEA).withValues(alpha: 0.1)
                          : const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.type == PostType.topic 
                              ? LucideIcons.messageSquare
                              : LucideIcons.heart,
                          size: 12,
                          color: post.type == PostType.topic 
                              ? const Color(0xFF667EEA)
                              : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.type == PostType.topic ? 'Topik' : 'Status',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: post.type == PostType.topic 
                                ? const Color(0xFF667EEA)
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.heart,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    LucideIcons.messageCircle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTopicTab() {
    if (kDebugMode) {
      print('DEBUG: Building topic tab - topic posts count: ${_topicPosts.length}');
    }
    
    if (_topicPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada postingan topik',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Postingan dengan tipe topik akan muncul di sini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (kDebugMode) {
      print('DEBUG: Displaying ${_topicPosts.length} topic posts in topic tab');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topicPosts.length,
      itemBuilder: (context, index) {
        if (kDebugMode) {
          print('DEBUG: Building topic post card for index $index');
        }
        return _buildTopicPostCard(_topicPosts[index]);
      },
    );
  }

  Widget _buildTopicPostCard(SocialMediaPost post) {
    if (kDebugMode) {
      print('DEBUG: Building topic post card for post ID: ${post.id}');
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.messageSquare,
                          size: 12,
                          color: Color(0xFF667EEA),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Topik',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF667EEA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.heart,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    LucideIcons.messageCircle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Oleh: ${post.authorName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}