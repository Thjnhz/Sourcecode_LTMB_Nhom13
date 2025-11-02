// lib/models/chapter.dart

class Chapter {
  final String id;
  final String? chapterNumber; // Có thể null
  final String? title; // Có thể null
  final String language;
  final DateTime? publishDate; // Có thể null

  Chapter({
    required this.id,
    this.chapterNumber,
    this.title,
    required this.language,
    this.publishDate,
  });

  // Hàm factory để parse JSON từ API cục bộ
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      chapterNumber: json['chapter_number'], // Tên cột trong DB
      title: json['title'], // Tên cột trong DB
      language: json['language'] ?? 'N/A', // Tên cột trong DB
      // Parse ngày tháng nếu tồn tại
      publishDate: json['publish_date'] != null
          ? DateTime.tryParse(json['publish_date'])
          : null,
    );
  }

  // Helper để hiển thị tên chương đẹp hơn
  String get displayTitle {
    String display = '';
    if (chapterNumber != null && chapterNumber!.isNotEmpty) {
      display += 'Chương $chapterNumber';
    }
    if (title != null && title!.isNotEmpty) {
      if (display.isNotEmpty) display += ': ';
      display += title!;
    }
    if (display.isEmpty) {
      display = 'Chapter ID: $id'; // Dự phòng nếu không có cả số và tiêu đề
    }
    return display;
  }
}
