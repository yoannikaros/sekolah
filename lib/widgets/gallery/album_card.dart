import 'package:flutter/material.dart';
import '../../models/album.dart';
import '../../utils/app_colors.dart';

class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AlbumCard({
    Key? key,
    required this.album,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primary,
                    ],
                  ),
                ),
                child: album.coverPhoto != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          album.coverPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultCover();
                          },
                        ),
                      )
                    : _buildDefaultCover(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (album.description != null) ...[
                      Text(
                        album.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.photo,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${album.photoCount} foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          album.isPublic ? Icons.public : Icons.lock,
                          size: 14,
                          color: album.isPublic ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.photo_album,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }
}