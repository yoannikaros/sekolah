import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class MediaPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  
  const MediaPreview({
    super.key,
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = path.basename(file.path);
    final fileExtension = path.extension(file.path).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(fileExtension);
    
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // File content
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isImage
                  ? _buildImagePreview()
                  : _buildFilePreview(fileName, fileExtension),
            ),
          ),
          
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.x,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePreview() {
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }
  
  Widget _buildFilePreview(String fileName, String fileExtension) {
    IconData fileIcon;
    Color iconColor;
    
    switch (fileExtension) {
      case '.pdf':
        fileIcon = LucideIcons.fileText;
        iconColor = Colors.red[600]!;
        break;
      case '.doc':
      case '.docx':
        fileIcon = LucideIcons.fileText;
        iconColor = Colors.blue[600]!;
        break;
      case '.ppt':
      case '.pptx':
        fileIcon = LucideIcons.presentation;
        iconColor = Colors.orange[600]!;
        break;
      case '.txt':
        fileIcon = LucideIcons.fileText;
        iconColor = Colors.grey[600]!;
        break;
      default:
        fileIcon = LucideIcons.file;
        iconColor = Colors.grey[600]!;
    }
    
    return Container(
      color: Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            fileIcon,
            size: 32,
            color: iconColor,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              fileName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fileExtension.substring(1).toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertCircle,
            size: 32,
            color: Colors.red[400],
          ),
          const SizedBox(height: 8),
          const Text(
            'Error',
            style: TextStyle(
              fontSize: 10,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}