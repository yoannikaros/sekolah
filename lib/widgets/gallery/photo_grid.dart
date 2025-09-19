import 'package:flutter/material.dart';
import '../../models/photo.dart';

class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  final Function(Photo, List<Photo>) onPhotoTap;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;

  const PhotoGrid({
    super.key,
    required this.photos,
    required this.onPhotoTap,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada foto',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return PhotoGridItem(
            photo: photo,
            onTap: () => onPhotoTap(photo, photos),
          );
        },
      ),
    );
  }
}

class PhotoGridItem extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;

  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'photo_${photo.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 32,
                      ),
                    );
                  },
                ),
                // Overlay with photo info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (photo.caption != null)
                          Expanded(
                            child: Text(
                              photo.caption!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (photo.likes != null && photo.likes!.isNotEmpty) ...[
                              const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${photo.likes!.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            if (photo.views > 0) ...[
                              if (photo.likes != null && photo.likes!.isNotEmpty) const SizedBox(width: 8),
                              const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${photo.views}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}