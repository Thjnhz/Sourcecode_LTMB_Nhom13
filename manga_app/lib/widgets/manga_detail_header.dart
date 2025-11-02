// lib/widgets/manga_detail_header.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga.dart';

class MangaDetailHeader extends StatelessWidget {
  final Manga manga;
  final VoidCallback onReadNowPressed;
  final bool isFollowed;
  final bool isTogglingFollow;
  final VoidCallback onFollowPressed;

  const MangaDetailHeader({
    required this.manga,
    required this.onReadNowPressed,
    required this.isFollowed,
    required this.isTogglingFollow,
    required this.onFollowPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Ảnh bìa sử dụng CachedNetworkImage để cache và placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: manga.coverUrl,
              height: 180,
              width: 120,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180,
                width: 120,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 180,
                width: 120,
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  manga.title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                if (manga.status != null && manga.status!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Chip(
                      label: Text(
                        'Status: ${manga.status}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.secondaryContainer
                          .withOpacity(0.6),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: onReadNowPressed,
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Đọc ngay'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 38),
                  ),
                ),

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: isTogglingFollow ? null : onFollowPressed,
                  icon: isTogglingFollow
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          isFollowed
                              ? Icons.check_circle_outline
                              : Icons.add_circle_outline,
                          size: 20,
                        ),
                  label: Text(isFollowed ? 'Đang theo dõi' : 'Theo dõi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isFollowed
                        ? theme.colorScheme.primary
                        : null,
                    side: isFollowed
                        ? BorderSide(color: theme.colorScheme.primary)
                        : null,
                    minimumSize: const Size(double.infinity, 38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
