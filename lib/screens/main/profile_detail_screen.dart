import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/social_media_models.dart';
import '../../models/chat_models.dart';
import '../../services/social_media_service.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../chat/chat_screen.dart';

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
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _loadUserProfile();
    _loadUserPosts();
    _checkFollowStatus();
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
      final profile = await _socialMediaService.getUserProfile(widget.userId);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
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

  Future<void> _checkFollowStatus() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;
    
    try {
      final isFollowing = await _socialMediaService.isFollowing(_currentUserId!, widget.userId);
      setState(() {
        _isFollowing = isFollowing;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null || _currentUserId == widget.userId) return;

    setState(() {
      _isLoadingFollow = true;
    });

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ${_isFollowing ? 'unfollow' : 'follow'}: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingFollow = false;
      });
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
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 300,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF667EEA),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProfileHeader(),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(52),
                      child: Container(
                        color: const Color(0xFF667EEA),
                        child: TabBar(
                          controller: _tabController,
                          indicator: const BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          tabs: const [
                            Tab(text: 'Postingan'),
                            Tab(text: 'Info'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsTab(),
                  _buildInfoTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.userName.isNotEmpty 
                        ? widget.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // User Name
              Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              if (_userProfile?.bio != null) ...[
                const SizedBox(height: 8),
                Text(
                  _userProfile!.bio!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Postingan', _userProfile?.postsCount ?? 0),
                  _buildStatItem('Pengikut', _userProfile?.followersCount ?? 0),
                  _buildStatItem('Mengikuti', _userProfile?.followingCount ?? 0),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              if (_currentUserId != null && _currentUserId != widget.userId)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoadingFollow ? null : _toggleFollow,
                        icon: _isLoadingFollow
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_isFollowing ? LucideIcons.userMinus : LucideIcons.userPlus),
                        label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey[600] : Colors.white,
                          foregroundColor: _isFollowing ? Colors.white : const Color(0xFF667EEA),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startChat,
                        icon: const Icon(LucideIcons.messageCircle),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667EEA),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
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
                    color: post.type == PostType.topic 
                        ? Colors.blue[100] 
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.type == PostType.topic ? 'Topik' : 'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: post.type == PostType.topic 
                          ? Colors.blue[700] 
                          : Colors.green[700],
                    ),
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
    );
  }

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Informasi Profil',
            [
              if (_userProfile?.email != null)
                _buildInfoRow('Email', _userProfile!.email!),
              if (_userProfile?.classCode != null)
                _buildInfoRow('Kelas', _userProfile!.classCode!),
              _buildInfoRow('Bergabung', _formatDate(_userProfile?.createdAt ?? DateTime.now())),
              _buildInfoRow('Status', _userProfile?.isActive == true ? 'Aktif' : 'Tidak Aktif'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}