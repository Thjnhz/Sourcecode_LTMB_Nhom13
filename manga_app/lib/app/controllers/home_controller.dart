import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/manga.dart';
import '../../services/manga_service.dart';
import '../routes/app_routes.dart';

/// Controller quản lý màn hình Home.
/// Bao gồm: load dữ liệu hot manga, latest manga, phân trang, scroll listener và navigation.
class HomeController extends GetxController {
  // -----------------------------
  // Dependencies / Services
  // -----------------------------
  final MangaService _mangaService = Get.find<MangaService>();

  // -----------------------------
  // State Variables
  // -----------------------------
  var isLoading = true.obs; // Trạng thái đang load dữ liệu trang chủ
  var hotMangaList = <Manga>[].obs; // Danh sách truyện hot hiển thị banner
  var latestMangaList = <Manga>[].obs; // Danh sách truyện mới hiển thị grid

  var scrollController = ScrollController(); // Controller scroll để load thêm
  var isLoadingMore = false.obs; // Trạng thái đang load thêm
  var hasMoreManga = true.obs; // Còn dữ liệu để load thêm không
  var page = 1; // Trang hiện tại
  var selectedIndex = 1.obs; // Tab hiện tại (1 = Home)

  // -----------------------------
  // Lifecycle Methods
  // -----------------------------
  @override
  void onInit() {
    super.onInit();
    fetchHomePageData(); // Load dữ liệu trang chủ
    scrollController.addListener(
      _scrollListener,
    ); // Lắng nghe scroll để load thêm
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose(); // Giải phóng bộ nhớ controller
    super.onClose();
  }

  /// Thay đổi tab hiện tại
  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }

  // -----------------------------
  // Scroll Listener
  // -----------------------------
  /// Hàm lắng nghe scroll để load thêm khi scroll gần cuối
  void _scrollListener() {
    if (isLoadingMore.isTrue || !hasMoreManga.isTrue) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent * 0.8) {
      loadMoreManga();
    }
  }

  // -----------------------------
  // Data Fetching
  // -----------------------------
  /// Tải dữ liệu ban đầu cho trang Home
  Future<void> fetchHomePageData() async {
    try {
      isLoading(true);
      page = 1;
      hasMoreManga(true);

      // Chạy song song 2 tác vụ: load hot manga và latest manga
      final results = await Future.wait([
        _mangaService.getHotManga(),
        _mangaService.getLatestManga(offset: 0),
      ]);

      final hotManga = results[0] as List<Manga>;
      final latestManga = results[1] as List<Manga>;

      // Gán dữ liệu vào state
      hotMangaList.assignAll(hotManga);
      latestMangaList.assignAll(latestManga);

      // Kiểm tra xem còn dữ liệu để load thêm không
      if (latestManga.length < MangaService.mangaLimit) {
        hasMoreManga(false);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải dữ liệu trang chủ: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  /// Tải thêm truyện khi scroll gần cuối
  void loadMoreManga() async {
    if (isLoadingMore.isTrue || !hasMoreManga.isTrue) return;
    try {
      isLoadingMore(true);
      page++;
      int nextOffset = (page - 1) * MangaService.mangaLimit;

      final newMangaList = await _mangaService.getLatestManga(
        offset: nextOffset,
      );

      if (newMangaList.isEmpty ||
          newMangaList.length < MangaService.mangaLimit) {
        hasMoreManga(false);
      }

      if (newMangaList.isNotEmpty) {
        latestMangaList.addAll(newMangaList);
      }
    } catch (e) {
      print('Lỗi khi tải thêm truyện: $e');
    } finally {
      isLoadingMore(false);
    }
  }

  // -----------------------------
  // Navigation / UI Actions
  // -----------------------------
  /// Xử lý khi nhấn vào một manga card hoặc banner item
  void onMangaTap(String mangaId, String title) {
    debugPrint('Điều hướng tới manga: $title (ID: $mangaId)');
    Get.toNamed(Routes.DETAIL, arguments: mangaId);
  }

  /// Điều hướng đến trang Tìm kiếm
  void navigateToSearch() {
    debugPrint('Điều hướng tới màn hình Search');
    Get.toNamed(Routes.SEARCH);
  }
}
