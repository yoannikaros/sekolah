import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';

class PostActions extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  
  const PostActions({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Like button
          _buildActionButton(
            context: context,
            icon: post.isLiked ? LucideIcons.heart : LucideIcons.heart,
            label: (post.likesCount ?? 0) > 0 ? (post.likesCount ?? 0).toString() : 'Suka',
            color: post.isLiked ? Colors.red : Colors.grey[600],
            onTap: onLike,
            isActive: post.isLiked,
          ),
          
          const SizedBox(width: 24),
          
          // Comment button
          _buildActionButton(
            context: context,
            icon: LucideIcons.messageCircle,
            label: (post.commentsCount ?? 0) > 0 ? (post.commentsCount ?? 0).toString() : 'Komentar',
            color: Colors.grey[600],
            onTap: onComment,
          ),
          
          const Spacer(),
          
          // Share button
          _buildActionButton(
            context: context,
            icon: LucideIcons.share,
            label: 'Bagikan',
            color: Colors.grey[600],
            onTap: () => _showShareOptions(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color? color,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Disable like/comment actions if not authenticated
        final isEnabled = authProvider.isAuthenticated || 
            (icon == LucideIcons.share); // Share is always enabled
        
        return InkWell(
          onTap: isEnabled ? onTap : () => _showLoginRequired(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isEnabled 
                      ? (isActive ? color : color) 
                      : Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isEnabled 
                        ? (isActive ? color : Colors.grey[700]) 
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.lock, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Login diperlukan untuk berinteraksi'),
          ],
        ),
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
  
  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Bagikan Postingan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Share options
              Column(
                children: [
                  _buildShareOption(
                    context: context,
                    icon: LucideIcons.copy,
                    title: 'Salin Link',
                    subtitle: 'Salin link postingan ke clipboard',
                    onTap: () {
                      Navigator.pop(context);
                      _copyLink(context);
                    },
                  ),
                  
                  const Divider(),
                  
                  _buildShareOption(
                    context: context,
                    icon: LucideIcons.messageCircle,
                    title: 'Bagikan via WhatsApp',
                    subtitle: 'Kirim link melalui WhatsApp',
                    onTap: () {
                      Navigator.pop(context);
                      _shareViaWhatsApp();
                    },
                  ),
                  
                  const Divider(),
                  
                  _buildShareOption(
                    context: context,
                    icon: LucideIcons.share2,
                    title: 'Bagikan Lainnya',
                    subtitle: 'Bagikan melalui aplikasi lain',
                    onTap: () {
                      Navigator.pop(context);
                      _shareViaOthers();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.blue[600],
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              LucideIcons.chevronRight,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  void _copyLink(BuildContext context) {
    // TODO: Implement copy link functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.check, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Link berhasil disalin'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _shareViaWhatsApp() {
    // TODO: Implement WhatsApp sharing
  }
  
  void _shareViaOthers() {
    // TODO: Implement system share sheet
  }
}