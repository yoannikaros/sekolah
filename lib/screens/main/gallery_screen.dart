import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/gallery_models.dart';
import '../../services/gallery_service.dart';
import '../../services/auth_service.dart';
import 'instagram_style_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  final String schoolId;
  final String classCode;

  const GalleryScreen({
    super.key,
    required this.schoolId,
    required this.classCode,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

enum ViewMode { grid, list }

class _GalleryScreenState extends State<GalleryScreen> with TickerProviderStateMixin {
  final GalleryService _galleryService = GalleryService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  List<GalleryPhotoWithStats> _photos = [];
  bool _isLoading = true;
  String? _currentStudentId;
  String? _currentStudentName;
  ViewMode _currentViewMode = ViewMode.list;
  
  // Animation controllers for like animations
  final Map<String, AnimationController> _likeAnimationControllers = {};
  final Map<String, Animation<double>> _likeAnimations = {};

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadPhotos();
  }

  Future<void> _initializeUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _currentStudentId = user.uid;
        _currentStudentName = user.displayName ?? 'Unknown';
      });
    }
  }

  Future<void> _loadPhotos() async {
    if (_currentStudentId == null) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final photos = await _galleryService.getPhotosWithStats(
        schoolId: widget.schoolId,
        classCode: widget.classCode,
        currentStudentId: _currentStudentId!,
      );
      
      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading photos: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_currentStudentId == null || _currentStudentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    _showUploadDialog(File(image.path));
  }

  void _showUploadDialog(File imageFile) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Photo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _uploadPhoto(
              imageFile,
              titleController.text,
              descriptionController.text,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto(File imageFile, String title, String description) async {
    Navigator.pop(context); // Close dialog
    
    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')),
        );
      }
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Uploading photo...'),
            ],
          ),
        ),
      );
    }

    try {
      // Upload image to Firebase Storage
      final uploadResult = await _galleryService.uploadPhotoWithWatermark(
        imageFile: imageFile,
        classCode: widget.classCode,
        schoolId: widget.schoolId,
        albumId: 'default', // You can create album selection later
      );

      if (uploadResult != null) {
        // Create gallery photo record
        final photo = GalleryPhoto(
          id: '',
          title: title,
          description: description,
          originalImageUrl: uploadResult['originalUrl']!,
          watermarkedImageUrl: uploadResult['watermarkedUrl']!,
          thumbnailUrl: uploadResult['thumbnailUrl']!,
          schoolId: widget.schoolId,
          classCode: widget.classCode,
          albumId: 'default',
          uploadedBy: _currentStudentId!,
          uploaderName: _currentStudentName!,
          createdAt: DateTime.now(),
        );

        await _galleryService.createGalleryPhoto(photo);
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!')),
          );
          
          _loadPhotos(); // Refresh the list
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload photo')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photo: $e')),
        );
      }
    }
  }

  // Initialize animation controller for a photo
  void _initLikeAnimation(String photoId) {
    if (!_likeAnimationControllers.containsKey(photoId)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      final animation = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
      
      _likeAnimationControllers[photoId] = controller;
      _likeAnimations[photoId] = animation;
    }
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _likeAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleLike(GalleryPhotoWithStats photoWithStats) async {
    if (_currentStudentId == null || _currentStudentName == null) return;

    final photoId = photoWithStats.photo.id;
    
    // Initialize animation controller if not exists
    _initLikeAnimation(photoId);
    
    // Optimistic update - update UI immediately
    final wasLiked = photoWithStats.isLikedByCurrentUser;
    final newLikeCount = wasLiked 
        ? photoWithStats.likeCount - 1 
        : photoWithStats.likeCount + 1;
    
    // Update the photo in the list immediately
    final photoIndex = _photos.indexWhere((p) => p.photo.id == photoId);
    if (photoIndex != -1) {
      setState(() {
        _photos[photoIndex] = GalleryPhotoWithStats(
          photo: photoWithStats.photo,
          likeCount: newLikeCount,
          commentCount: photoWithStats.commentCount,
          isLikedByCurrentUser: !wasLiked,
        );
      });
      
      // Trigger animation if liking (not unliking)
      if (!wasLiked) {
        _likeAnimationControllers[photoId]?.forward().then((_) {
          _likeAnimationControllers[photoId]?.reverse();
        });
      }
    }

    try {
      // Perform the actual API call in the background
      if (wasLiked) {
        await _galleryService.unlikePhoto(
          photoId: photoId,
          studentId: _currentStudentId!,
        );
      } else {
        await _galleryService.likePhoto(
          photoId: photoId,
          studentId: _currentStudentId!,
          studentName: _currentStudentName!,
          schoolId: widget.schoolId,
        );
      }
    } catch (e) {
      // If API call fails, revert the optimistic update
      if (mounted && photoIndex != -1) {
        setState(() {
          _photos[photoIndex] = photoWithStats; // Revert to original state
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
        );
      }
    }
  }

  void _showCommentsDialog(GalleryPhotoWithStats photoWithStats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
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
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Comments list
              Expanded(
                child: CommentsDialogContent(
                  photoWithStats: photoWithStats,
                  currentStudentId: _currentStudentId!,
                  currentStudentName: _currentStudentName!,
                  schoolId: widget.schoolId,
                  onCommentAdded: _loadPhotos,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _currentViewMode = _currentViewMode == ViewMode.grid 
                    ? ViewMode.list 
                    : ViewMode.grid;
              });
            },
            icon: Icon(
              _currentViewMode == ViewMode.grid 
                  ? Icons.view_list 
                  : Icons.grid_view,
              color: Colors.black,
            ),
          ),
          IconButton(
            onPressed: _pickAndUploadImage,
            icon: const Icon(Icons.add_a_photo, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No photos yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the camera icon to add your first photo',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPhotos,
                  child: _currentViewMode == ViewMode.grid
                      ? _buildGridView()
                      : _buildListView(),
                ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photoWithStats = _photos[index];
        return GestureDetector(
          onTap: () => _showInstagramStyleDetail(photoWithStats),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    photoWithStats.photo.thumbnailUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error_outline, color: Colors.grey, size: 24),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better visibility of icons
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                  // Like and comment indicators
                  if (photoWithStats.likeCount > 0 || photoWithStats.commentCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (photoWithStats.likeCount > 0) ...[
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${photoWithStats.likeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (photoWithStats.likeCount > 0 && photoWithStats.commentCount > 0)
                              const SizedBox(width: 6),
                            if (photoWithStats.commentCount > 0) ...[
                              const Icon(
                                Icons.chat_bubble,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${photoWithStats.commentCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photoWithStats = _photos[index];
        return InstagramStylePhotoCard(
          photoWithStats: photoWithStats,
          onLike: () => _toggleLike(photoWithStats),
          onComment: () => _showCommentsDialog(photoWithStats),
          currentStudentId: _currentStudentId,
          onRefresh: _loadPhotos,
        );
      },
    );
  }

  void _showInstagramStyleDetail(GalleryPhotoWithStats photoWithStats) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InstagramStyleDetailScreen(
          photoWithStats: photoWithStats,
          currentStudentId: _currentStudentId!,
          currentStudentName: _currentStudentName!,
          schoolId: widget.schoolId,
          onLike: () => _toggleLike(photoWithStats),
          onComment: () => _showInstagramStyleDetail(photoWithStats),
          onRefresh: _loadPhotos,
        ),
      ),
    );
  }
}

class InstagramStylePhotoCard extends StatefulWidget {
  final GalleryPhotoWithStats photoWithStats;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final String? currentStudentId;
  final VoidCallback? onRefresh;

  const InstagramStylePhotoCard({
    super.key,
    required this.photoWithStats,
    required this.onLike,
    required this.onComment,
    this.currentStudentId,
    this.onRefresh,
  });

  @override
  State<InstagramStylePhotoCard> createState() => _InstagramStylePhotoCardState();
}

class _InstagramStylePhotoCardState extends State<InstagramStylePhotoCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    // Trigger animation if liking (not unliking)
    if (!widget.photoWithStats.isLikedByCurrentUser) {
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }
    widget.onLike();
  }

  void _showOptionsMenu(BuildContext context) {
    final photo = widget.photoWithStats.photo;
    final isOwner = widget.currentStudentId == photo.uploadedBy;
    
    if (!isOwner) return; // Only show menu for post owners
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Description'),
              onTap: () {
                Navigator.pop(context);
                _showEditDescriptionDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Post'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDescriptionDialog(BuildContext context) {
    final photo = widget.photoWithStats.photo;
    final descriptionController = TextEditingController(text: photo.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateDescription(context, descriptionController.text),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deletePost(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDescription(BuildContext context, String newDescription) async {
    Navigator.pop(context);
    
    try {
      final galleryService = GalleryService();
      final photo = widget.photoWithStats.photo;
      final updatedPhoto = photo.copyWith(
        description: newDescription,
        updatedAt: DateTime.now(),
      );
      
      final success = await galleryService.updateGalleryPhoto(photo.id, updatedPhoto);
      
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description updated successfully!')),
        );
        widget.onRefresh?.call();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update description')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating description: $e')),
        );
      }
    }
  }

  Future<void> _deletePost(BuildContext context) async {
    Navigator.pop(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting post...'),
          ],
        ),
      ),
    );
    
    try {
      final galleryService = GalleryService();
      final success = await galleryService.deleteGalleryPhoto(widget.photoWithStats.photo.id);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (success) {
          // Navigate back to gallery screen first
          Navigator.pop(context);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully!')),
          );
          
          // Refresh the gallery
          widget.onRefresh?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete post')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photoWithStats.photo;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: Text(
                    photo.uploaderName.isNotEmpty 
                        ? photo.uploaderName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.uploaderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
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
                IconButton(
                  onPressed: () => _showOptionsMenu(context),
                  icon: const Icon(Icons.more_vert, size: 20),
                ),
              ],
            ),
          ),
          
          // Photo
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              photo.watermarkedImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.grey, size: 40),
                  ),
                );
              },
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _likeAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _likeAnimation.value,
                      child: IconButton(
                        onPressed: _handleLike,
                        icon: Icon(
                          widget.photoWithStats.isLikedByCurrentUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.photoWithStats.isLikedByCurrentUser
                              ? Colors.red
                              : Colors.black,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    );
                  },
                ),
                  // Like count
          if (widget.photoWithStats.likeCount > 0)
            Text(
              '${widget.photoWithStats.likeCount} ${widget.photoWithStats.likeCount == 1 ? 'like' : 'likes'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: widget.onComment,
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.black,
                    size: 26,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Title and description
          if (photo.title.isNotEmpty || photo.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                    if (photo.description.isNotEmpty) ...[
                      if (photo.title.isNotEmpty) const TextSpan(text: '  '),
                      if (photo.title.isEmpty) const TextSpan(text: ' '),
                      TextSpan(text: photo.description),
                    ],
                  ],
                ),
              ),
            ),
          
              // View comments
          if (widget.photoWithStats.commentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: GestureDetector(
                onTap: widget.onComment,
                child: Text(
                  'View all ${widget.photoWithStats.commentCount} comments',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 12),
        ],
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
}

class CommentsDialogContent extends StatefulWidget {
  final GalleryPhotoWithStats photoWithStats;
  final String currentStudentId;
  final String currentStudentName;
  final String schoolId;
  final VoidCallback onCommentAdded;
  final ScrollController scrollController;

  const CommentsDialogContent({
    super.key,
    required this.photoWithStats,
    required this.currentStudentId,
    required this.currentStudentName,
    required this.schoolId,
    required this.onCommentAdded,
    required this.scrollController,
  });

  @override
  State<CommentsDialogContent> createState() => _CommentsDialogContentState();
}

class _CommentsDialogContentState extends State<CommentsDialogContent> {
  final GalleryService _galleryService = GalleryService();
  final TextEditingController _commentController = TextEditingController();
  List<GalleryComment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _galleryService.getPhotoComments(
        widget.photoWithStats.photo.id,
      );
      
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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
      widget.onCommentAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Comments list
        Expanded(
          child: _isLoading
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
                      controller: widget.scrollController,
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
                                radius: 16,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  comment.studentName.isNotEmpty
                                      ? comment.studentName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
                                    const SizedBox(height: 2),
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
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
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
                    onTap: _addComment,
                    child: Text(
                      'Post',
                      style: TextStyle(
                        color: value.text.trim().isNotEmpty
                            ? Colors.blue
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
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
}