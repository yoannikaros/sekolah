import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/mading_models.dart';
import '../../services/mading_service.dart';

class MadingDetailScreen extends StatefulWidget {
  final MadingPost post;
  final String currentUserId;
  final String currentUserRole;
  final bool autoFocusComment;

  const MadingDetailScreen({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserRole,
    this.autoFocusComment = false,
  });

  @override
  State<MadingDetailScreen> createState() => _MadingDetailScreenState();
}

class _MadingDetailScreenState extends State<MadingDetailScreen> {
  final MadingService _madingService = MadingService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  String? _replyToCommentId;
  String? _replyToUserName;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoFocusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _commentFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Detail Karya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.post.studentId == widget.currentUserId || widget.currentUserRole == 'teacher')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus Karya'),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.white),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(),
                  _buildPostImage(),
                  _buildPostContent(),
                  _buildPostActions(),
                  const Divider(height: 32),
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

  Widget _buildPostHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo[100],
            radius: 24,
            child: Text(
              widget.post.studentName.isNotEmpty ? widget.post.studentName[0].toUpperCase() : 'S',
              style: TextStyle(
                color: Colors.indigo[700],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${widget.post.studentClass} • ${_formatDate(widget.post.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (widget.post.subjectId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Mata Pelajaran',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return Hero(
      tag: 'post_image_${widget.post.id}',
      child: SizedBox(
        width: double.infinity,
        height: 400,
        child: CachedNetworkImage(
          imageUrl: widget.post.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.description.isNotEmpty)
            Text(
              widget.post.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostActions() {
    final isLiked = widget.post.likedBy.contains(widget.currentUserId);
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isLiked ? Colors.red[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.post.likesCount}',
                    style: TextStyle(
                      color: isLiked ? Colors.red : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.post.commentsCount}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Komentar (${widget.post.commentsCount})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StreamBuilder<List<MadingComment>>(
            stream: _madingService.getComments(widget.post.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading comments: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                );
              }

              final comments = snapshot.data ?? [];
              final mainComments = comments.where((c) => c.parentCommentId == null).toList();

              if (mainComments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada komentar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jadilah yang pertama berkomentar!',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mainComments.length,
                itemBuilder: (context, index) {
                  final comment = mainComments[index];
                  final replies = comments.where((c) => c.parentCommentId == comment.id).toList();
                  return _buildCommentItem(comment, replies);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(MadingComment comment, List<MadingComment> replies) {
    final isLiked = comment.likedBy.contains(widget.currentUserId);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _getUserRoleColor(comment.userRole),
                radius: 16,
                child: Text(
                  comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                        Text(
                          comment.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getUserRoleColor(comment.userRole),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getUserRoleText(comment.userRole),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.comment,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleCommentLike(comment.id),
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likesCount}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _replyToComment(comment.id, comment.userName),
                          child: Text(
                            'Balas',
                            style: TextStyle(
                              color: Colors.indigo[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (comment.userId == widget.currentUserId || widget.currentUserRole == 'teacher')
                          const SizedBox(width: 16),
                        if (comment.userId == widget.currentUserId || widget.currentUserRole == 'teacher')
                          GestureDetector(
                            onTap: () => _deleteComment(comment.id),
                            child: Text(
                              'Hapus',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Replies
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Column(
                children: replies.map((reply) => _buildReplyItem(reply)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyItem(MadingComment reply) {
    final isLiked = reply.likedBy.contains(widget.currentUserId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _getUserRoleColor(reply.userRole),
            radius: 12,
            child: Text(
              reply.userName.isNotEmpty ? reply.userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getUserRoleColor(reply.userRole),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getUserRoleText(reply.userRole),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(reply.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reply.comment,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleCommentLike(reply.id),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey[600],
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${reply.likesCount}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (reply.userId == widget.currentUserId || widget.currentUserRole == 'teacher')
                      const SizedBox(width: 12),
                    if (reply.userId == widget.currentUserId || widget.currentUserRole == 'teacher')
                      GestureDetector(
                        onTap: () => _deleteComment(reply.id),
                        child: Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToCommentId != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, color: Colors.indigo[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Membalas $_replyToUserName',
                      style: TextStyle(
                        color: Colors.indigo[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, color: Colors.indigo[600], size: 16),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: _replyToCommentId != null 
                        ? 'Tulis balasan...' 
                        : 'Tulis komentar...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.indigo[600]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.indigo[600],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: _isSubmittingComment ? null : _submitComment,
                  icon: _isSubmittingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleLike() {
    _madingService.toggleLikePost(widget.post.id, widget.currentUserId);
  }

  void _toggleCommentLike(String commentId) {
    _madingService.toggleLikeComment(commentId, widget.currentUserId);
  }

  void _replyToComment(String commentId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = userName;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  Future<void> _submitComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      await _madingService.addComment(
        postId: widget.post.id,
        userId: widget.currentUserId,
        userName: 'Current User', // You should get this from user data
        userRole: widget.currentUserRole,
        comment: comment,
        parentCommentId: _replyToCommentId,
      );

      _commentController.clear();
      _cancelReply();
      
      // Scroll to bottom to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim komentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Karya'),
        content: const Text('Apakah Anda yakin ingin menghapus karya ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _madingService.deletePost(widget.post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Karya berhasil dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _madingService.deleteComment(commentId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getUserRoleColor(String role) {
    switch (role) {
      case 'teacher':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      case 'student':
      default:
        return Colors.indigo;
    }
  }

  String _getUserRoleText(String role) {
    switch (role) {
      case 'teacher':
        return 'Guru';
      case 'admin':
        return 'Admin';
      case 'student':
      default:
        return 'Siswa';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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