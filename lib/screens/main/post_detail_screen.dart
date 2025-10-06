import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/social_media_models.dart';
import '../../services/social_media_service.dart';
import '../../services/auth_service.dart';
import 'create_post_screen.dart';
import 'profile_detail_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final SocialMediaPost post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final SocialMediaService _socialMediaService = SocialMediaService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late SocialMediaPost _post;
  List<PostComment> _comments = [];
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;
  bool _isFollowing = false;
  String? _currentUserId;
  PostComment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadCurrentUser();
    _loadComments();
    _loadPostDetails();
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      setState(() {
        _currentUserId = userProfile?.id;
      });
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  Future<void> _loadPostDetails() async {
    try {
      final updatedPost = await _socialMediaService.getPostById(_post.id);
      if (mounted && updatedPost != null) {
        setState(() {
          _post = updatedPost;
        });
      }
    } catch (e) {
      debugPrint('Error loading post details: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    if (_currentUserId == null || _currentUserId == _post.authorId) return;
    
    try {
      final isFollowing = await _socialMediaService.isFollowing(_currentUserId!, _post.authorId);
      setState(() {
        _isFollowing = isFollowing;
      });
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null || _currentUserId == _post.authorId) return;

    try {
      if (_isFollowing) {
        await _socialMediaService.unfollowUser(_post.authorId);
      } else {
        await _socialMediaService.followUser(_post.authorId);
      }
      
      setState(() {
        _isFollowing = !_isFollowing;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Berhasil mengikuti ${_post.authorName}' : 'Berhenti mengikuti ${_post.authorName}'),
            backgroundColor: _isFollowing ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ${_isFollowing ? 'unfollow' : 'follow'}: $e')),
        );
      }
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          userId: _post.authorId,
          userName: _post.authorName,
        ),
      ),
    );
  }

  void _navigateToCommentAuthorProfile(String authorId, String authorName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          userId: authorId,
          userName: authorName,
        ),
      ),
    );
  }

  void _loadComments() {
    _socialMediaService.getCommentsByPost(_post.id).listen(
      (comments) {
        if (mounted) {
          setState(() {
            _comments = comments;
            _isLoadingComments = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _isLoadingComments = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading comments: $e')),
          );
        }
      },
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      await _socialMediaService.addComment(
        postId: _post.id,
        content: _commentController.text.trim(),
        replyToCommentId: _replyingTo?.id,
      );

      _commentController.clear();
      setState(() {
        _replyingTo = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _togglePostLike() async {
    try {
      await _socialMediaService.togglePostLike(_post.id);
      await _loadPostDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleCommentLike(PostComment comment) async {
    try {
      await _socialMediaService.toggleCommentLike(comment.id, _post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _replyToComment(PostComment comment) {
    setState(() {
      _replyingTo = comment;
    });
    FocusScope.of(context).requestFocus(FocusNode());
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
        title: const Text(
          'Status',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: const Icon(LucideIcons.bell, color: Colors.black),
          //   onPressed: () {},
          // ),
          IconButton(
            icon: const Icon(LucideIcons.moreHorizontal, color: Colors.black),
            onPressed: () {
              if (_post.authorId == _socialMediaService.currentUserId) {
                _showPostOptions();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dengan jumlah tayangan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${_post.commentsCount + 1} tayangan',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Postingan utama yang dipilih
          _buildSelectedPost(),
          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          // Section Popular dan komentar
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildPopularSection(),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildSelectedPost() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _navigateToProfile,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: Text(
                _post.authorName.isNotEmpty ? _post.authorName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _navigateToProfile,
                      child: Text(
                        _post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(_post.createdAt),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _post.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    height: 1.4,
                  ),
                ),
                // Note: SocialMediaPost doesn't have imageUrl property
                // Remove image display for now as it's not part of the model
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _togglePostLike,
                      child: Icon(
                        _post.likedBy.contains(_socialMediaService.currentUserId)
                            ? LucideIcons.heart
                            : LucideIcons.heart,
                        size: 20,
                        color: _post.likedBy.contains(_socialMediaService.currentUserId)
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_post.likesCount}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      LucideIcons.messageCircle,
                      size: 20,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_post.commentsCount}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Follow button - only show if not viewing own post
          if (_currentUserId != null && _currentUserId != _post.authorId)
            GestureDetector(
              onTap: _toggleFollow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _isFollowing ? Colors.grey[200] : Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: _isFollowing ? Border.all(color: Colors.grey[400]!) : null,
                ),
                child: Text(
                  _isFollowing ? 'Mengikuti' : 'Ikuti',
                  style: TextStyle(
                    color: _isFollowing ? Colors.black : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Popular',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: Colors.black,
          ),
          const Spacer(),
          const Text(
            'Lihat aktivitas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_isLoadingComments) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Belum ada komentar',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Organize comments into main comments and replies
    final mainComments = _comments.where((c) => c.replyToCommentId == null).toList();
    final repliesMap = <String, List<PostComment>>{};
    
    for (final comment in _comments) {
      if (comment.replyToCommentId != null) {
        repliesMap.putIfAbsent(comment.replyToCommentId!, () => []).add(comment);
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mainComments.length,
      itemBuilder: (context, index) {
        final comment = mainComments[index];
        final replies = repliesMap[comment.id] ?? [];
        
        return Column(
          children: [
            _buildCommentItem(comment, false),
            if (replies.isNotEmpty)
              ...replies.map((reply) => _buildCommentItem(reply, true)),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(PostComment comment, bool isReply) {
    return Container(
      padding: EdgeInsets.only(
        left: isReply ? 48 : 16,
        right: 16,
        top: 10,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line for replies
          if (isReply)
            Container(
              width: 2,
              height: 60,
              color: Colors.grey[300],
              margin: const EdgeInsets.only(right: 12),
            ),
          // Avatar
          GestureDetector(
            onTap: () => _navigateToCommentAuthorProfile(comment.authorId, comment.authorName),
            child: CircleAvatar(
              radius: isReply ? 14 : 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: isReply ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToCommentAuthorProfile(comment.authorId, comment.authorName),
                      child: Text(
                        comment.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isReply ? 13 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isReply ? 12 : 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: isReply ? 13 : 14,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleCommentLike(comment),
                      child: Icon(
                        comment.likedBy.contains(_socialMediaService.currentUserId)
                            ? LucideIcons.heart
                            : LucideIcons.heart,
                        size: isReply ? 14 : 16,
                        color: comment.likedBy.contains(_socialMediaService.currentUserId)
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${comment.likesCount}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isReply ? 11 : 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isReply) // Only show reply button for main comments
                      GestureDetector(
                        onTap: () => _replyToComment(comment),
                        child: Text(
                          'Balas',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isReply ? 11 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (comment.authorId == _socialMediaService.currentUserId)
            PopupMenuButton<String>(
              onSelected: (value) => _handleCommentAction(value, comment),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Icon(
                LucideIcons.moreHorizontal,
                size: isReply ? 14 : 16,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: _replyingTo != null 
                      ? 'Balas ${_replyingTo!.authorName}...'
                      : 'Tulis komentar...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
                maxLines: null,
                style: const TextStyle(fontSize: 15),
                onChanged: (value) {
                  setState(() {}); // Rebuild to show/hide send button
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _commentController.text.trim().isEmpty || _isSubmittingComment 
                  ? null 
                  : _submitComment,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _commentController.text.trim().isEmpty 
                      ? Colors.grey[300] 
                      : Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isSubmittingComment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        LucideIcons.send,
                        size: 16,
                        color: _commentController.text.trim().isEmpty 
                            ? Colors.grey[600] 
                            : Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Postingan'),
              onTap: () {
                Navigator.pop(context);
                _handlePostAction('edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Postingan', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handlePostAction('delete');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handlePostAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreatePostScreen(editPost: _post),
          ),
        ).then((_) {
          if (mounted) {
            _loadPostDetails();
          }
        });
        break;
      case 'delete':
        _deletePost();
        break;
    }
  }

  void _handleCommentAction(String action, PostComment comment) {
    switch (action) {
      case 'edit':
        _editComment(comment);
        break;
      case 'delete':
        _deleteComment(comment);
        break;
    }
  }

  void _editComment(PostComment comment) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: comment.originalContent);
        return AlertDialog(
          title: const Text('Edit Komentar'),
          content: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Edit komentar...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                try {
                  navigator.pop();
                  await _socialMediaService.updateComment(
                    commentId: comment.id,
                    newContent: controller.text.trim(),
                  );
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Komentar berhasil diperbarui'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(PostComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
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

    if (confirmed == true) {
      try {
        await _socialMediaService.deleteComment(comment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Komentar berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  Future<void> _deletePost() async {
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

    if (confirmed == true) {
      try {
        await _socialMediaService.deletePost(_post.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Postingan berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
}