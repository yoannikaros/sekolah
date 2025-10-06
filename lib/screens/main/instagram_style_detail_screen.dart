import 'package:flutter/material.dart';
import '../../models/gallery_models.dart';
import '../../services/gallery_service.dart';

class InstagramStyleDetailScreen extends StatefulWidget {
  final GalleryPhotoWithStats photoWithStats;
  final String currentStudentId;
  final String currentStudentName;
  final String schoolId;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onRefresh;

  const InstagramStyleDetailScreen({
    super.key,
    required this.photoWithStats,
    required this.currentStudentId,
    required this.currentStudentName,
    required this.schoolId,
    required this.onLike,
    required this.onComment,
    required this.onRefresh,
  });

  @override
  State<InstagramStyleDetailScreen> createState() =>
      _InstagramStyleDetailScreenState();
}

class _InstagramStyleDetailScreenState
    extends State<InstagramStyleDetailScreen> {
  final GalleryService _galleryService = GalleryService();
  final TextEditingController _commentController = TextEditingController();
  List<GalleryComment> _comments = [];
  bool _isLoadingComments = true;


  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await _galleryService.getPhotoComments(
        widget.photoWithStats.photo.id,
      );

      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _galleryService.addComment(
        photoId: widget.photoWithStats.photo.id,
        studentId: widget.currentStudentId,
        studentName: widget.currentStudentName,
        schoolId: widget.schoolId,
        comment: _commentController.text.trim(),
      );

      _commentController.clear();
      _loadComments();
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
      }
    }
  }

  void _showCommentsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_comments.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Comments list
              Expanded(
                child: _isLoadingComments
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _comments.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No comments yet.\nBe the first to comment!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        comment.studentName.isNotEmpty
                                            ? comment.studentName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: comment.studentName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const TextSpan(text: ' '),
                                                TextSpan(
                                                  text: comment.comment,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(comment.createdAt),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              
              // Add comment section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 0.5),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue,
                        child: Text(
                          widget.currentStudentName.isNotEmpty
                              ? widget.currentStudentName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _commentController,
                        builder: (context, value, child) {
                          return GestureDetector(
                            onTap: value.text.trim().isNotEmpty ? _addComment : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: value.text.trim().isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Post',
                                style: TextStyle(
                                  color: value.text.trim().isNotEmpty
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photoWithStats.photo;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                photo.uploaderName.isNotEmpty
                    ? photo.uploaderName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              photo.uploaderName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo section
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.0,
                child: Center(
                  child: Image.network(
                    photo.watermarkedImageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Bottom section with actions and info
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onLike,
                        child: Icon(
                          widget.photoWithStats.isLikedByCurrentUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              widget.photoWithStats.isLikedByCurrentUser
                                  ? Colors.red
                                  : Colors.black,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Like count
                      if (widget.photoWithStats.likeCount > 0)
                        Text(
                          '${widget.photoWithStats.likeCount} ${widget.photoWithStats.likeCount == 1 ? 'like' : 'likes'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _showCommentsDialog,
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.black,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 5),

                      // Comment count - Fixed this section
                      if (_comments.isNotEmpty)
                        GestureDetector(
                          onTap: _showCommentsDialog,
                          child: Text(
                            '${_comments.length} ${_comments.length == 1 ? 'comment' : 'comments'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const Spacer(),
                      // Time - Fixed positioning
                      Text(
                        _formatDate(photo.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Caption
                if (photo.title.isNotEmpty || photo.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 16, 0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: photo.uploaderName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // if (photo.title.isNotEmpty) ...[
                          //   const TextSpan(text: ' '),
                          //   TextSpan(text: photo.title),
                          // ],
                          if (photo.description.isNotEmpty) ...[
                            if (photo.title.isNotEmpty)
                              const TextSpan(text: '  '),
                            if (photo.title.isEmpty) const TextSpan(text: ' '),
                            TextSpan(text: photo.description),
                          ],

                        ],
                      ),
                    ),
                  ),
                          const SizedBox(height: 20),

                // Comments are now shown in a dialog when tapping the comment icon
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
