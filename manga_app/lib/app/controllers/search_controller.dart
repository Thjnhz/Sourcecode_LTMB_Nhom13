import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/manga.dart';
import '../../services/manga_service.dart';
import '../routes/app_routes.dart';

/// Controller quản lý màn hình Search
/// Bao gồm tìm kiếm theo từ khóa, tag, chế độ AND/OR
/// Lưu kết quả và điều hướng đến chi tiết manga
class SearchController extends GetxController {
  // -----------------------------
  // Dependencies
  // -----------------------------
  final MangaService _mangaService = Get.find<MangaService>();

  // -----------------------------
  // State Variables
  // -----------------------------
  var isLoading = false.obs; // Đang load kết quả
  var hasSearched = false.obs; // Đã tìm kiếm ít nhất 1 lần chưa
  var searchResults = <Manga>[].obs; // Kết quả tìm kiếm
  var allTags = <String>[].obs; // Observable để UI cập nhật tự động
  // -----------------------------
  // Tag Search State
  // -----------------------------
  var selectedTags = <String>{}.obs; // Các tag được chọn (Set để tránh trùng)
  var tagSearchMode = 'and'.obs; // 'and' = tất cả tag, 'or' = bất kỳ tag

  // Controller cho ô text search
  final TextEditingController textController = TextEditingController();
  @override
  void onInit() {
    super.onInit();
    fetchTagsFromDatabase();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  // -----------------------------
  // Search Methods
  // -----------------------------

  /// Thực hiện tìm kiếm
  /// Gửi query + tag + mode lên MangaService
  Future<void> fetchTagsFromDatabase() async {
    try {
      // Giả sử _mangaService.getAllTags() trả về List<String>
      final tags = await _mangaService.getAllTags();
      allTags.assignAll(tags); // Cập nhật observable
    } catch (e) {
      debugPrint('Lỗi lấy tags từ DB: $e');
    }
  }

  Future<void> performSearch() async {
    final query = textController.text.trim();

    // Nếu không có query và tag, xóa kết quả
    if (query.isEmpty && selectedTags.isEmpty) {
      clearSearch();
      return;
    }

    hasSearched.value = true;
    isLoading.value = true;
    searchResults.clear();

    try {
      final results = await _mangaService.searchManga(
        query: query,
        tags: selectedTags.toList(),
        mode: tagSearchMode.value,
      );
      searchResults.assignAll(results);
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể thực hiện tìm kiếm: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Xóa ô tìm kiếm và kết quả
  void clearSearch() {
    textController.clear();
    searchResults.clear();
    selectedTags.clear();
    hasSearched.value = false;
  }

  // -----------------------------
  // Tag Handling
  // -----------------------------

  /// Thêm hoặc bỏ tag khi chọn trong UI
  void onTagSelected(bool isSelected, String tag) {
    if (isSelected) {
      selectedTags.add(tag);
    } else {
      selectedTags.remove(tag);
    }
    // Tự động tìm kiếm lại khi tag thay đổi
    performSearch();
  }

  /// Thay đổi chế độ tìm kiếm AND/OR
  void onModeChanged(int index) {
    tagSearchMode.value = (index == 0) ? 'and' : 'or';
    // Nếu đã có tag, tự động tìm kiếm lại
    if (selectedTags.isNotEmpty) {
      performSearch();
    }
  }

  // -----------------------------
  // Navigation
  // -----------------------------
  /// Điều hướng đến DetailScreen của manga
  void onMangaTap(String mangaId, String title) {
    debugPrint('Navigate to manga: $title (ID: $mangaId)');
    Get.toNamed(Routes.DETAIL, arguments: mangaId);
  }
}
