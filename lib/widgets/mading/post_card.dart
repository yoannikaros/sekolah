import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with author info and type
              _buildHeader(context),
              
              const SizedBox(height: 12),
              
              // Title
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Content preview
              Text(
                post.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Media preview
              if (post.mediaFiles?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildMediaPreview(),
              ],
              
              const SizedBox(height: 12),
              
              // Actions and stats
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Author avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue[100],
          child: Text(
            (post.author != null && post.author!.fullName.isNotEmpty) 
                ? post.author!.fullName[0].toUpperCase()
                : 'U',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
              fontSize: 12,
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Author name and date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author?.fullName ?? 'Unknown User',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(post.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Type badge
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
                post.type.icon,
                size: 12,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 4),
              Text(
                post.type.displayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        
        // Status indicator (if not approved)
        if (post.status != PostStatus.approved) ...[
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: post.status.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildMediaPreview() {
    if (post.mediaFiles == null || post.mediaFiles!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final imageFiles = post.mediaFiles!
        .where((file) => file.type == 'image')
        .take(3)
        .toList();
    
    if (imageFiles.isEmpty) {
      // Show document icon if no images but has files
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.paperclip,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '${post.mediaFiles!.length} file terlampir',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          // First image (larger)
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageFiles[0].url,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    LucideIcons.image,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
          
          // Additional images or count indicator
          if (imageFiles.length > 1) ...[
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  if (imageFiles.length > 1)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: imageFiles[1].url,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              LucideIcons.image,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  if (imageFiles.length > 2) ...[
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '+${post.mediaFiles!.length - 2}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Like button
        InkWell(
          onTap: onLike,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  post.isLiked ? LucideIcons.heart : LucideIcons.heart,
                  size: 16,
                  color: post.isLiked ? Colors.red : Colors.grey[600],
                ),
                if ((post.likesCount ?? 0) > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    (post.likesCount ?? 0).toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Comment count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 16,
              color: Colors.grey[600],
            ),
            if ((post.commentsCount ?? 0) > 0) ...[
              const SizedBox(width: 4),
              Text(
                (post.commentsCount ?? 0).toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        
        const Spacer(),
        
        // Read more indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lihat detail',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: Colors.blue[600],
            ),
          ],
        ),
      ],
    );
  }
}