import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onDelete;
  
  const CommentItem({
    super.key,
    required this.comment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header with author info
          Row(
            children: [
              // Author avatar
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blue[100],
                child: Text(
                  (comment.author != null && comment.author!.fullName.isNotEmpty) 
                      ? comment.author!.fullName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    fontSize: 11,
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
                      comment.author?.fullName ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status indicator and actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status badge (if not approved)
                  if (comment.status != CommentStatus.approved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: comment.status.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: comment.status.color),
                      ),
                      child: Text(
                        comment.status.displayName,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: comment.status.color,
                        ),
                      ),
                    ),
                  
                  // Delete button (for comment author or moderators)
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.user;
                      final canDelete = user?.id == comment.authorId ||
                          user?.role == 'teacher' ||
                          user?.role == 'school_admin';
                      
                      if (canDelete) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: InkWell(
                            onTap: () => _showDeleteDialog(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                LucideIcons.trash2,
                                size: 14,
                                color: Colors.red[400],
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Comment content
          Text(
            comment.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context) {
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
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}