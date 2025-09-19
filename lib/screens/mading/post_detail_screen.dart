import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mading/media_gallery.dart';
import '../../widgets/mading/comment_item.dart';
import '../../widgets/mading/post_actions.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  
  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmittingComment = false;
  
  @override
  void initState() {
    super.initState();
    // Load comments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchComments(widget.post.id);
    });
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showErrorSnackBar('Anda harus login untuk berkomentar');
      return;
    }
    
    setState(() {
      _isSubmittingComment = true;
    });
    
    try {
      final postProvider = context.read<PostProvider>();
      await postProvider.addComment(
        postId: widget.post.id,
        content: _commentController.text.trim(),
      );
      
      if (postProvider.error == null) {
        _commentController.clear();
        // Scroll to bottom to show new comment
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        _showErrorSnackBar(postProvider.error!);
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengirim komentar: $e');
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Detail Postingan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              final canModerate = user?.role == 'teacher' || user?.role == 'school_admin';
              final isOwner = user?.id == widget.post.authorId;
              
              if (canModerate || isOwner) {
                return PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'approve':
                        _approvePost();
                        break;
                      case 'reject':
                        _rejectPost();
                        break;
                      case 'delete':
                        _deletePost();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> items = [];
                    
                    if (canModerate && widget.post.status == PostStatus.pending) {
                      items.addAll([
                        const PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(LucideIcons.check, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Setujui'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(LucideIcons.x, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Tolak'),
                            ],
                          ),
                        ),
                      ]);
                    }
                    
                    if (canModerate || isOwner) {
                      items.add(
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return items;
                  },
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Post Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Header
                  _buildPostHeader(),
                  
                  const SizedBox(height: 16),
                  
                  // Post Content
                  _buildPostContent(),
                  
                  const SizedBox(height: 16),
                  
                  // Media Gallery
                  if (widget.post.mediaFiles?.isNotEmpty == true) ...[
                    MediaGallery(mediaFiles: widget.post.mediaFiles!),
                    const SizedBox(height: 16),
                  ],
                  
                  // Post Actions
                  PostActions(
                    post: widget.post,
                    onLike: () => context.read<PostProvider>().toggleLike(widget.post.id),
                  ),
                  
                  const Divider(height: 32),
                  
                  // Comments Section
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
          
          // Comment Input
          _buildCommentInput(),
        ],
      ),
    );
  }
  
  Widget _buildPostHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            if (widget.post.status != PostStatus.approved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.post.status.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.post.status.color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.post.status.icon,
                      size: 14,
                      color: widget.post.status.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.post.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            
            if (widget.post.status != PostStatus.approved)
              const SizedBox(height: 12),
            
            // Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.post.type.icon,
                    size: 14,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.post.type.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Title
            Text(
              widget.post.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Author and Date
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    (widget.post.author?.fullName != null && widget.post.author!.fullName.isNotEmpty) 
                        ? widget.post.author!.fullName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.author?.fullName ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(widget.post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPostContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            
            if (widget.post.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Deskripsi tambahan akan ditampilkan di sini',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommentsSection() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final comments = postProvider.getCommentsForPost(widget.post.id);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.messageCircle),
                const SizedBox(width: 8),
                Text(
                  'Komentar (${comments.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (postProvider.isLoading && comments.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (comments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada komentar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jadilah yang pertama berkomentar!',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return CommentItem(
                    comment: comment,
                    onDelete: () => _deleteComment(comment.id),
                  );
                },
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildCommentInput() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.lock, color: Colors.grey),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Login untuk berkomentar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to login screen
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  authProvider.user?.fullName != null && authProvider.user!.fullName.isNotEmpty
                      ? authProvider.user!.fullName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
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
                      borderSide: BorderSide(color: Colors.blue[400]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSubmittingComment ? null : _submitComment,
                icon: _isSubmittingComment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.send),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _approvePost() async {
    try {
      await context.read<PostProvider>().approvePost(widget.post.id);
      _showSuccessSnackBar('Postingan berhasil disetujui');
    } catch (e) {
      _showErrorSnackBar('Gagal menyetujui postingan: $e');
    }
  }
  
  Future<void> _rejectPost() async {
    try {
      await context.read<PostProvider>().rejectPost(widget.post.id, 'Rejected by admin');
      _showSuccessSnackBar('Postingan berhasil ditolak');
    } catch (e) {
      _showErrorSnackBar('Gagal menolak postingan: $e');
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
      if (!mounted) return;
      try {
        await context.read<PostProvider>().deletePost(widget.post.id);
        if (!mounted) return;
        Navigator.pop(context);
        _showSuccessSnackBar('Postingan berhasil dihapus');
      } catch (e) {
        _showErrorSnackBar('Gagal menghapus postingan: $e');
      }
    }
  }
  
  Future<void> _deleteComment(int commentId) async {
    try {
          await context.read<PostProvider>().deleteComment(commentId);
          if (!mounted) return;
          _showSuccessSnackBar('Komentar berhasil dihapus');
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus komentar: $e');
    }
  }
}