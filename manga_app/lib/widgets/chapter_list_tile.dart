// lib/widgets/chapter_list_tile.dart

import 'package:flutter/material.dart';

class ChapterListTile extends StatelessWidget {
  /// Tiêu đề của chương (vd: "Trận chiến cuối cùng")
  final String chapterTitle;

  /// Ngày đăng (vd: "2 ngày trước")
  final String publishDate;

  /// Hành động khi nhấn vào
  final VoidCallback onTap;

  const ChapterListTile({
    required this.chapterTitle,
    required this.publishDate,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(chapterTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(publishDate),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[600],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      dense: true, // Làm cho ListTile mỏng hơn
    );
  }
}
