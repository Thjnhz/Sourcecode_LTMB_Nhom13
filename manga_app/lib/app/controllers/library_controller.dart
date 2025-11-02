import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/history_manga.dart';
import '../../models/library_manga.dart';
import '../../services/auth_service.dart';
import '../../services/manga_service.dart';
import '../routes/app_routes.dart';

/// Controller quản lý màn hình Thư viện và Lịch sử đọc
/// Bao gồm: TabController, load dữ liệu history và library, navigation.
class LibraryController extends GetxController
    with GetTickerProviderStateMixin {
  // -----------------------------
  // Dependencies / Services
  // -----------------------------
  final AuthService _authService = Get.find<AuthService>();
  final MangaService _mangaService = Get.find<MangaService>();

  // -----------------------------
  // TabController
  // -----------------------------
  late TabController
  tabController; // Quản lý TabBar (0 = Lịch sử, 1 = Thư viện)

  // -----------------------------
  // State Variables
  // -----------------------------
  var isLoading = true.obs; // Trạng thái đang load dữ liệu
  var errorMessage = RxnString(); // Lưu lỗi nếu có
  var historyList = <HistoryManga>[].obs; // Danh sách lịch sử đọc
  var libraryList = <LibraryManga>[].obs; // Danh sách truyện đã follow

  // Lấy trực tiếp trạng thái đăng nhập từ AuthService
  RxBool get isAuthenticated => _authService.isAuthenticated;

  // -----------------------------
  // Lifecycle Methods
  // -----------------------------
  @override
  void onInit() {
    super.onInit();
    // Khởi tạo TabController cho 2 tab
    tabController = TabController(length: 2, vsync: this);

    // Lắng nghe thay đổi trạng thái đăng nhập để tự động load/xóa dữ liệu
    ever(_authService.isAuthenticated, _onAuthStateChanged);

    // Nếu đã đăng nhập, tải dữ liệu lần đầu
    if (_authService.isAuthenticated.isTrue) {
      fetchLibraryData();
    } else {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    tabController.dispose(); // Giải phóng TabController
    super.onClose();
  }

  // -----------------------------
  // Auth State Listener
  // -----------------------------
  /// Hàm được gọi khi trạng thái đăng nhập thay đổi
  void _onAuthStateChanged(bool isLoggedIn) {
    if (isLoggedIn) {
      fetchLibraryData(); // Load dữ liệu khi vừa đăng nhập
    } else {
      // Xóa dữ liệu khi vừa đăng xuất
      isLoading(false);
      historyList.clear();
      libraryList.clear();
      errorMessage.value = null;
    }
  }

  // -----------------------------
  // Data Fetching
  // -----------------------------
  /// Tải đồng thời dữ liệu lịch sử đọc và thư viện
  Future<void> fetchLibraryData() async {
    try {
      isLoading(true);
      errorMessage.value = null;

      // Gọi API song song: lấy lịch sử đọc và thư viện
      final results = await Future.wait([
        _mangaService.getReadingHistory(),
        _mangaService.getLibrary(),
      ]);

      // Gán dữ liệu vào state
      historyList.assignAll(results[0] as List<HistoryManga>);
      libraryList.assignAll(results[1] as List<LibraryManga>);
    } catch (e) {
      print("Lỗi tải Library/History: $e");
      errorMessage.value = "Không thể tải dữ liệu: ${e.toString()}";
      Get.snackbar(
        'Lỗi',
        errorMessage.value ?? 'Lỗi không xác định',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  // -----------------------------
  // Navigation / UI Actions
  // -----------------------------
  /// Khi nhấn vào một manga, điều hướng tới DetailScreen
  void onMangaTap(String mangaId) {
    Get.toNamed(Routes.DETAIL, arguments: mangaId);
  }

  /// Khi nhấn vào một chapter trong lịch sử đọc, điều hướng tới ReaderScreen
  void onChapterTap(String chapterId) {
    Get.toNamed(Routes.READER, arguments: chapterId);
  }
}
