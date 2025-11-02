// lib/models/library_manga.dart

/// Model đại diện cho 1 truyện trong "Thư viện / Theo dõi" của user
class LibraryManga {
  /// ID truyện
  final String mangaId;

  /// Tiêu đề truyện
  final String title;

  /// File cover (ảnh bìa)
  final String coverFilename;

  /// Trạng thái truyện: ongoing, completed, v.v. (có thể null)
  final String? mangaStatus;

  /// Trạng thái của user: reading, on_hold, dropped, v.v. (có thể null)
  final String? userStatus;

  /// Thời điểm cập nhật lần cuối
  final DateTime updatedAt;

  LibraryManga({
    required this.mangaId,
    required this.title,
    required this.coverFilename,
    this.mangaStatus,
    this.userStatus,
    required this.updatedAt,
  });

  /// Factory để tạo LibraryManga từ JSON
  factory LibraryManga.fromJson(Map<String, dynamic> json) {
    return LibraryManga(
      mangaId: json['id'],
      title: json['title'] ?? 'No Title',
      coverFilename: json['cover_filename'] ?? '',
      mangaStatus: json['manga_status'],
      userStatus: json['user_status'],
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Getter tiện ích hiển thị trạng thái người dùng
  String get displayUserStatus {
    switch (userStatus) {
      case 'reading':
        return 'Đang đọc';
      case 'on_hold':
        return 'Tạm dừng';
      case 'completed':
        return 'Đã hoàn thành';
      case 'dropped':
        return 'Bỏ';
      default:
        return 'Chưa xác định';
    }
  }

  /// Getter hiển thị trạng thái truyện
  String get displayMangaStatus {
    switch (mangaStatus) {
      case 'ongoing':
        return 'Đang tiến hành';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Chưa xác định';
    }
  }
}
