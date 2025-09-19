import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/post.dart';

class MediaGallery extends StatelessWidget {
  final List<MediaFile> mediaFiles;
  
  const MediaGallery({
    super.key,
    required this.mediaFiles,
  });

  @override
  Widget build(BuildContext context) {
    final imageFiles = mediaFiles.where((file) => file.type == 'image').toList();
    final documentFiles = mediaFiles.where((file) => file.type == 'document').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images Gallery
        if (imageFiles.isNotEmpty) ...[
          Text(
            'Gambar (${imageFiles.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildImageGallery(context, imageFiles),
        ],
        
        // Documents List
        if (documentFiles.isNotEmpty) ...[
          if (imageFiles.isNotEmpty) const SizedBox(height: 16),
          Text(
            'Dokumen (${documentFiles.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDocumentsList(context, documentFiles),
        ],
      ],
    );
  }
  
  Widget _buildImageGallery(BuildContext context, List<MediaFile> imageFiles) {
    if (imageFiles.length == 1) {
      return _buildSingleImage(context, imageFiles[0], 0, imageFiles);
    } else if (imageFiles.length == 2) {
      return _buildTwoImages(context, imageFiles);
    } else {
      return _buildMultipleImages(context, imageFiles);
    }
  }
  
  Widget _buildSingleImage(BuildContext context, MediaFile image, int index, List<MediaFile> allImages) {
    return GestureDetector(
      onTap: () => _openImageGallery(context, allImages, index),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: image.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.imageOff,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat gambar',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTwoImages(BuildContext context, List<MediaFile> imageFiles) {
    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageGallery(context, imageFiles, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageFiles[0].url,
                  height: 150,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => _buildImageError(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageGallery(context, imageFiles, 1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageFiles[1].url,
                  height: 150,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => _buildImageError(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMultipleImages(BuildContext context, List<MediaFile> imageFiles) {
    return SizedBox(
      height: 150,
      child: Row(
        children: [
          // First image (larger)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openImageGallery(context, imageFiles, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageFiles[0].url,
                  height: 150,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => _buildImageError(),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Right column with 2 images or more indicator
          Expanded(
            child: Column(
              children: [
                // Second image
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageGallery(context, imageFiles, 1),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: imageFiles[1].url,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => _buildImageError(),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Third image or more indicator
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageGallery(context, imageFiles, 2),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: imageFiles.length > 2 ? imageFiles[2].url : imageFiles[1].url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                            ),
                            errorWidget: (context, url, error) => _buildImageError(),
                          ),
                        ),
                        
                        // Overlay for more images indicator
                        if (imageFiles.length > 3)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '+${imageFiles.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentsList(BuildContext context, List<MediaFile> documentFiles) {
    return Column(
      children: documentFiles.map((doc) => _buildDocumentItem(context, doc)).toList(),
    );
  }
  
  Widget _buildDocumentItem(BuildContext context, MediaFile document) {
    final fileName = document.filename;
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    IconData fileIcon;
    Color iconColor;
    
    switch (fileExtension) {
      case 'pdf':
        fileIcon = LucideIcons.fileText;
        iconColor = Colors.red[600]!;
        break;
      case 'doc':
      case 'docx':
        fileIcon = LucideIcons.fileText;
        iconColor = Colors.blue[600]!;
        break;
      case 'ppt':
      case 'pptx':
        fileIcon = LucideIcons.presentation;
        iconColor = Colors.orange[600]!;
        break;
      case 'txt':
        fileIcon = LucideIcons.fileText;
        iconColor = Colors.grey[600]!;
        break;
      default:
        fileIcon = LucideIcons.file;
        iconColor = Colors.grey[600]!;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openDocument(document.url),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  fileIcon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fileExtension.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                LucideIcons.download,
                color: Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImageError() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.imageOff,
            size: 24,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            'Error',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  void _openImageGallery(BuildContext context, List<MediaFile> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageGalleryScreen(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
  
  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ImageGalleryScreen extends StatelessWidget {
  final List<MediaFile> images;
  final int initialIndex;
  
  const _ImageGalleryScreen({
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${initialIndex + 1} dari ${images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(images[index].url),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.imageOff,
                      size: 64,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Gagal memuat gambar',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        itemCount: images.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        pageController: PageController(initialPage: initialIndex),
      ),
    );
  }
}