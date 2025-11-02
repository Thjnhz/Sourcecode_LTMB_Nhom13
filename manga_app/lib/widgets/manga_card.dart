// lib/widgets/manga_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Thẻ hiển thị 1 manga trong grid/list.
/// - Dùng CachedNetworkImage để cache ảnh, giảm tải mạng và tăng hiệu năng.
/// - Hiển thị placeholder khi tải và icon khi lỗi.
class MangaCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const MangaCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Dùng SizedBox để giới hạn kích thước hình ảnh
    return SizedBox(
      width: 120,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Ảnh bìa được cache tự động
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 160,
                width: 120,
                fit: BoxFit.cover,
                // Hiển thị widget khi đang tải
                placeholder: (context, url) => Container(
                  height: 160,
                  width: 120,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                // Widget khi tải lỗi
                errorWidget: (context, url, error) => Container(
                  height: 160,
                  width: 120,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, color: Colors.grey[400]),
                ),
                // Optional: đặt max width/height cho cache (tùy backend)
                // memCacheWidth: 256,
                // memCacheHeight: 362,
              ),
            ),

            const SizedBox(height: 8),

            // Tiêu đề truyện
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
