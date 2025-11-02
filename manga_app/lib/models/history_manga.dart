// lib/models/history_manga.dart

/// Model đại diện cho 1 entry trong "Lịch sử đọc" của user
class HistoryManga {
  /// ID truyện
  final String mangaId;

  /// Tiêu đề truyện
  final String mangaTitle;

  /// File cover (ảnh bìa)
  final String coverFilename;

  /// ID chương đang đọc
  final String chapterId;

  /// Số chương (có thể null)
  final String? chapterNumber;

  /// Tiêu đề chương (có thể null)
  final String? chapterTitle;

  /// Thời điểm lần cuối đọc
  final DateTime lastReadAt;

  HistoryManga({
    required this.mangaId,
    required this.mangaTitle,
    required this.coverFilename,
    required this.chapterId,
    this.chapterNumber,
    this.chapterTitle,
    required this.lastReadAt,
  });

  /// Factory để tạo HistoryManga từ JSON
  factory HistoryManga.fromJson(Map<String, dynamic> json) {
    return HistoryManga(
      mangaId: json['manga_id'],
      mangaTitle: json['manga_title'] ?? 'No Title',
      coverFilename: json['cover_filename'] ?? '',
      chapterId: json['chapter_id'],
      chapterNumber: json['chapter_number'],
      chapterTitle: json['chapter_title'],
      lastReadAt:
          DateTime.tryParse(json['last_read_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Getter tiện ích hiển thị tên chapter: "Ch. X: Tiêu đề" hoặc fallback
  String get displayChapterTitle {
    final num = chapterNumber ?? '';
    final title = chapterTitle ?? '';
    if (num.isNotEmpty) return 'Ch. $num: $title';
    if (title.isNotEmpty) return title;
    return 'Chapter $chapterId';
  }
}
