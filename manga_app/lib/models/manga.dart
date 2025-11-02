// lib/models/manga.dart

/// Model đại diện cho 1 Manga
class Manga {
  /// ID truyện
  final String id;

  /// Tiêu đề truyện
  final String title;

  /// URL ảnh bìa
  final String coverUrl;

  /// Mô tả truyện (có thể null)
  final String? description;

  /// Trạng thái truyện (ongoing, completed, v.v.)
  final String? status;

  /// Danh sách tag
  final List<String> tags;

  Manga({
    required this.id,
    required this.title,
    required this.coverUrl,
    this.description,
    this.status,
    this.tags = const [],
  });

  /// Factory để tạo Manga từ JSON data
  /// coverBaseUrl: Base URL cho ảnh bìa
  static Manga fromJsonData(Map<String, dynamic> data, String coverBaseUrl) {
    final mangaId = data['id'] ?? 'unknown-id';
    final coverFilename = data['cover_filename'];
    String coverUrl;

    // Xây dựng URL ảnh bìa
    if (mangaId != 'unknown-id' &&
        coverFilename != null &&
        coverFilename.isNotEmpty) {
      coverUrl = "$coverBaseUrl/$mangaId/$coverFilename.256.jpg";
    } else {
      // Placeholder nếu không có cover
      coverUrl = "https://placehold.co/256x362/png?text=No+Cover";
    }

    // Chuyển đổi tags từ JSON
    List<String> tagList = [];
    if (data['tags'] != null && data['tags'] is List) {
      tagList = List<String>.from(data['tags'].map((tag) => tag.toString()));
    }

    return Manga(
      id: mangaId,
      title: data['title'] ?? 'No Title',
      coverUrl: coverUrl,
      description: data['description'],
      status: data['status'],
      tags: tagList,
    );
  }

  /// Helper hiển thị tags dạng chuỗi, phân tách bằng ", "
  String get displayTags => tags.join(', ');
}
