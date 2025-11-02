// lib/app/controllers/reader_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/chapter.dart';
import '../../services/manga_service.dart';
import 'detail_controller.dart';

/// ReaderController - quản lý trạng thái màn hình đọc truyện.
/// Bản đã cập nhật: khi đọc chương N sẽ background fetch chương N+1.
class ReaderController extends GetxController {
  // ----- Services & other controllers -----
  final MangaService _mangaService = Get.find<MangaService>();
  late final DetailController _detailController;

  // ----- Reactive state -----
  var isLoading = true.obs;
  var pageUrls = <String>[].obs; // list URL hoặc file://...
  var errorMessage = RxnString();
  var isOverlayVisible = false.obs;
  var currentPageIndex = 0.obs;
  var totalPages = 0.obs;

  // ----- Controllers/Timers -----
  final ScrollController scrollController = ScrollController();
  Timer? _overlayTimer;
  late String chapterId;

  late List<Chapter> _chapterList;
  final _currentChapterIndex = 0.obs;

  // Flag để tránh update slider gây vòng lặp
  bool _isSliderDragging = false;

  // ----- Prefetch control -----
  // Set các chapterId đang được prefetch để tránh chạy trùng lặp
  final Set<String> _prefetchingChapterIds = <String>{};

  // Khi còn ít hơn N trang, trigger prefetch (tuneable)
  final int _prefetchWhenRemainingPages = 3;

  @override
  void onInit() {
    super.onInit();
    _initializeChapter();
    scrollController.addListener(_updateCurrentPageFromScroll);

    // Khi overlay visible thay đổi có thể cần thay đổi system UI (nếu cần)
    ever(isOverlayVisible, (bool isVisible) {
      if (isVisible) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.bottom],
        );
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.bottom],
        );
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  }

  @override
  void onClose() {
    _overlayTimer?.cancel();
    scrollController.removeListener(_updateCurrentPageFromScroll);
    scrollController.dispose();
    // đảm bảo bật lại system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.onClose();
  }

  /// Cuộn tới vị trí trang hiện tại an toàn.
  /// - Nếu controller chưa có clients thì sẽ delay 50ms và thử lại một lần.
  /// - Tính toán vị trí dựa trên chiều cao trung bình mỗi trang.
  void _scrollToBottom() {
    // Thực hiện sau 1 microtask để đảm bảo layout đã ổn (nếu được gọi ngay khi setState)
    Future.microtask(() {
      if (!scrollController.hasClients) {
        // Nếu chưa có clients (ListView chưa mount), thử delay ngắn rồi thử lại một lần
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!scrollController.hasClients) return;
          _performScrollToCurrentPage();
        });
        return;
      }
      _performScrollToCurrentPage();
    });
  }

  /// Thao tác cuộn thực tế: tính vị trí dựa trên chiều cao trung bình và animate -> jump nếu lỗi
  void _performScrollToCurrentPage() {
    try {
      final pageHeight = _calculateAveragePageHeight();
      final target = (currentPageIndex.value * pageHeight).clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      );

      // Dùng animateTo để có cảm giác mượt; nếu animate fail (ví dụ race condition) fallback về jumpTo
      scrollController
          .animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .catchError((_) {
            try {
              scrollController.jumpTo(target);
            } catch (e) {
              debugPrint(
                '_performScrollToCurrentPage fallback jumpTo failed: $e',
              );
            }
          });
    } catch (e) {
      debugPrint('_performScrollToCurrentPage error: $e');
    }
  }

  // --- Initialization: lấy chapterId từ args, tìm chapter list trong DetailController ---
  void _initializeChapter() {
    try {
      final arguments = Get.arguments;
      if (arguments is! String || (arguments as String).isEmpty) {
        throw ArgumentError('Invalid chapter ID');
      }
      chapterId = arguments;
      // Lấy danh sách chương từ DetailController nếu có
      try {
        _detailController = Get.find<DetailController>();
        _chapterList = _detailController.chapters;
        _currentChapterIndex.value = _chapterList.indexWhere(
          (c) => c.id == chapterId,
        );
        if (_currentChapterIndex.value == -1) {
          // Nếu không tìm thấy, vẫn tạo list một chương duy nhất
          _chapterList = [
            Chapter(
              id: chapterId,
              chapterNumber: '?',
              title: '',
              language: 'vi',
              publishDate: null,
            ),
          ];
          _currentChapterIndex.value = 0;
        }
      } catch (e) {
        // Nếu không có DetailController, fallback đơn giản
        _chapterList = [
          Chapter(
            id: chapterId,
            chapterNumber: '?',
            title: '',
            language: 'vi',
            publishDate: null,
          ),
        ];
        _currentChapterIndex.value = 0;
      }
      _updateReadingHistory(chapterId);
      fetchPages(chapterId);
    } catch (e) {
      _handleError('Không tìm thấy ID chương hợp lệ: $e');
    }
  }

  // --- Fetch pages cho 1 chương ---
  Future<void> fetchPages(String chapId) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      pageUrls.clear();
      totalPages.value = 0;
      currentPageIndex.value = 0;

      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }

      // Lấy danh sách URL (thông thường là http(s) URLs)
      final List<String> urls = await _mangaService.getChapterPages(chapId);

      if (urls.isEmpty) {
        throw Exception('Chapter có 0 trang');
      }

      // Hiển thị ngay URL mạng để UI mượt, rồi bắt đầu background prefetch
      pageUrls.assignAll(urls);
      totalPages.value = urls.length;

      // Sau khi đã set pages cho chương hiện tại, trigger prefetch chương tiếp theo
      _startPrefetchNextChapter();

      // Scroll/sync UI
      _scrollToBottom();
    } catch (e) {
      _handleError('Lỗi tải trang: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Cập nhật lịch sử đọc (non-blocking)
  Future<void> _updateReadingHistory(String chapId) async {
    try {
      await _mangaService.updateReadingHistory(chapId);
    } catch (e) {
      // Không cần crash nếu update history thất bại
      debugPrint('Lỗi cập nhật lịch sử đọc: $e');
    }
  }

  // --- Scroll -> ước lượng trang hiện tại ---
  void _updateCurrentPageFromScroll() {
    if (_isSliderDragging) return;
    if (!scrollController.hasClients || totalPages.value <= 0) return;

    final pageHeight = _calculateAveragePageHeight();
    if (pageHeight <= 0) return;

    final estimatedIndex = (scrollController.offset / pageHeight).round();
    final clamped = estimatedIndex.clamp(0, totalPages.value - 1);
    currentPageIndex.value = clamped;

    // Khi user cuộn đến gần cuối chương (ví dụ còn <= _prefetchWhenRemainingPages),
    // trigger prefetch chương tiếp theo
    final remaining = totalPages.value - 1 - currentPageIndex.value;
    if (remaining <= _prefetchWhenRemainingPages) {
      _startPrefetchNextChapter();
    }
  }

  double _calculateAveragePageHeight() {
    if (totalPages.value <= 0) return Get.height;
    if (totalPages.value == 1) return Get.height;
    if (scrollController.position.maxScrollExtent <= 0) {
      return scrollController.position.viewportDimension > 0
          ? scrollController.position.viewportDimension
          : Get.height;
    }
    final totalContentHeight =
        scrollController.position.maxScrollExtent +
        scrollController.position.viewportDimension;
    return totalContentHeight / totalPages.value;
  }

  // --- Overlay controls (unchanged) ---
  void toggleOverlay() {
    isOverlayVisible.value = !isOverlayVisible.value;
    if (isOverlayVisible.value) {
      _startOverlayTimer();
    } else {
      _cancelOverlayTimer();
    }
  }

  void _startOverlayTimer() {
    _cancelOverlayTimer();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      isOverlayVisible.value = false;
    });
  }

  void _cancelOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
  }

  // --- Slider handlers (unchanged) ---
  void onSliderChanging(double value) {
    _isSliderDragging = true;
    _cancelOverlayTimer();
    final newIndex = value.toInt().clamp(0, totalPages.value - 1);
    if (newIndex != currentPageIndex.value) {
      currentPageIndex.value = newIndex;
    }
  }

  void onSliderChanged(double value) {
    _isSliderDragging = false;
    final pageIndex = value.toInt().clamp(0, totalPages.value - 1);
    _scrollToPage(pageIndex);
    _startOverlayTimer();
  }

  void _scrollToPage(int pageIndex) {
    if (!scrollController.hasClients || totalPages.value <= 0) return;
    final pageHeight = _calculateAveragePageHeight();
    final targetPosition = (pageIndex * pageHeight).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );
    scrollController.jumpTo(targetPosition);
  }

  // --- Navigation between chapters (unchanged) ---
  bool get canGoPreviousChapter => _currentChapterIndex.value > 0;
  bool get canGoNextChapter =>
      _chapterList.isNotEmpty &&
      _currentChapterIndex.value < _chapterList.length - 1;

  void goToPreviousChapter() {
    if (!canGoPreviousChapter) return;
    _currentChapterIndex.value--;
    final prevChapter = _chapterList[_currentChapterIndex.value];
    chapterId = prevChapter.id;
    _updateReadingHistory(chapterId);
    fetchPages(chapterId);
  }

  void goToNextChapter() {
    if (!canGoNextChapter) return;
    _currentChapterIndex.value++;
    final nextChapter = _chapterList[_currentChapterIndex.value];
    chapterId = nextChapter.id;
    _updateReadingHistory(chapterId);
    fetchPages(chapterId);
  }

  void jumpToChapter(Chapter chapter) {
    final newIndex = _chapterList.indexWhere((c) => c.id == chapter.id);
    if (newIndex == -1 || newIndex == _currentChapterIndex.value) {
      isOverlayVisible.value = false;
      return;
    }
    _currentChapterIndex.value = newIndex;
    chapterId = chapter.id;
    _updateReadingHistory(chapterId);
    fetchPages(chapterId);
    isOverlayVisible.value = false;
  }

  // --- Error handling util ---
  void _handleError(String message) {
    errorMessage.value = message;
    totalPages.value = 0;
    currentPageIndex.value = 0;
    debugPrint('ReaderController Error: $message');
  }

  // --- Prefetch logic: background fetch chương kế tiếp ---
  /// Bắt đầu prefetch chương kế tiếp (non-blocking).
  /// - Lấy next chapter id từ _chapterList
  /// - Nếu đang prefetch cho chapter đó thì skip
  /// - Gọi MangaService.getChapterPages(nextId) để lấy URLs
  /// - Dùng precacheImage(CachedNetworkImageProvider) để tiền tải ảnh
  void _startPrefetchNextChapter() {
    try {
      // Xác định next chapter id
      final currentIdx = _chapterList.indexWhere((c) => c.id == chapterId);
      if (currentIdx == -1) return;
      final nextIdx = currentIdx + 1;
      if (nextIdx < 0 || nextIdx >= _chapterList.length) return;
      final nextId = _chapterList[nextIdx].id;

      // Nếu đã đang prefetch hoặc nextId trùng với current -> skip
      if (_prefetchingChapterIds.contains(nextId) || nextId == chapterId)
        return;

      // Thêm vào set để tránh prefetch lặp lại
      _prefetchingChapterIds.add(nextId);

      // Chạy async without awaiting to không block UI
      _doPrefetchNext(nextId).whenComplete(() {
        // Sau khi xong (thành công hoặc lỗi) remove khỏi set
        _prefetchingChapterIds.remove(nextId);
      });
    } catch (e) {
      debugPrint('_startPrefetchNextChapter error: $e');
    }
  }

  /// Thực hiện prefetch (internal)
  Future<void> _doPrefetchNext(String nextChapterId) async {
    try {
      // 1) Lấy danh sách URLs của chương kế tiếp
      final List<String> nextUrls = await _mangaService.getChapterPages(
        nextChapterId,
      );
      if (nextUrls.isEmpty) return;

      // 2) Lấy context để precache images.
      //    Lưu ý: Get.context có thể null (ví dụ background). Nếu null, skip prefetching images.
      final BuildContext? ctx = Get.context;
      if (ctx == null) {
        // Không có context hiện tại: vẫn đã gọi API (warming server cache),
        // nhưng không thể gọi precacheImage. Kết thúc.
        debugPrint(
          'Prefetch: no BuildContext available, images not precached.',
        );
        return;
      }

      // 3) Tiền tải từng ảnh (thực hiện tuần tự để tránh quá tải)
      //    Nếu muốn nhanh hơn, có thể chạy nhiều parallel nhưng cần throttle.
      for (final url in nextUrls) {
        try {
          final provider = CachedNetworkImageProvider(url);
          // precacheImage là Future, nhưng ta await từng cái để hạn chế concurrent requests
          await precacheImage(provider, ctx);
        } catch (e) {
          // Không cần throw, chỉ log
          debugPrint('Prefetch image failed for $url : $e');
        }
      }

      debugPrint(
        'Prefetch complete for chapter $nextChapterId (images precached).',
      );
    } catch (e) {
      debugPrint('Prefetch next chapter error: $e');
    }
  }

  // --- Utility getters ---

  // Public getter UI có thể đọc danh sách chương
  List<Chapter> get chapterList => _chapterList;

  bool get hasError => errorMessage.value != null;
  bool get hasPages => pageUrls.isNotEmpty;
}
