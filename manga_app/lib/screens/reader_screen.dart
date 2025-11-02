import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../app/controllers/reader_controller.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/keep_alive_page.dart';
import '../widgets/error_retry_widget.dart';
import '../models/chapter.dart';

/// Màn hình đọc truyện (trình đọc ảnh theo chương)
/// Giao diện nền đen, hỗ trợ ẩn/hiện thanh công cụ bằng chạm, cuộn, và hiển thị danh sách chương.
class ReaderScreen extends GetView<ReaderController> {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Thiết lập giao diện hệ thống (status bar & navigation bar)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: WillPopScope(
        // Khi người dùng bấm nút Back → bật lại giao diện hệ thống
        onWillPop: () async {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
          return true;
        },
        // Toàn bộ màn hình có thể chạm để ẩn/hiện overlay
        child: GestureDetector(
          onTap: controller.toggleOverlay,
          child: Stack(
            children: [
              // Khu vực hiển thị ảnh truyện
              Obx(() {
                if (controller.isLoading.isTrue) {
                  return const LoadingIndicator(message: 'Đang tải chương...');
                }

                if (controller.hasError) {
                  return ErrorRetryWidget(
                    errorMessage: controller.errorMessage.value!,
                    onRetry: () => controller.fetchPages(controller.chapterId),
                  );
                }

                if (!controller.hasPages) {
                  return const Center(
                    child: Text(
                      'Không tìm thấy trang trong chương này.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Danh sách các trang ảnh của chương
                return ListView.builder(
                  controller: controller.scrollController,
                  addAutomaticKeepAlives: true,
                  itemCount: controller.pageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = controller.pageUrls[index];
                    return KeepAlivePage(
                      key: ValueKey(imageUrl),
                      imageUrl: imageUrl,
                    );
                  },
                );
              }),

              // Giao diện điều khiển (Overlay)
              _buildOverlayUI(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị lớp Overlay (ẩn/hiện bằng chạm)
  Widget _buildOverlayUI(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final bool isVisible = controller.isOverlayVisible.value;
      final int currentPage = controller.currentPageIndex.value;
      final int totalPages = controller.totalPages.value;
      final bool canPrev = controller.canGoPreviousChapter;
      final bool canNext = controller.canGoNextChapter;

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: isVisible
            ? Stack(
                key: const ValueKey('overlay-visible'),
                children: [
                  // Thanh điều khiển dưới cùng
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(
                      context,
                      theme,
                      currentPage,
                      totalPages,
                      canPrev,
                      canNext,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(key: ValueKey('overlay-hidden')),
      );
    });
  }

  /// Thanh điều khiển phía dưới gồm:
  /// - Slider chọn trang
  /// - Nút chuyển chương trước / sau
  /// - Nút mở danh sách chương
  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    int currentPage,
    int totalPages,
    bool canPrev,
    bool canNext,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh trượt điều khiển trang đọc
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${currentPage + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: currentPage.toDouble().clamp(
                      0.0,
                      (totalPages - 1).toDouble(),
                    ),
                    min: 0,
                    max: (totalPages - 1).toDouble().clamp(
                      0.0,
                      double.infinity,
                    ),
                    divisions: totalPages > 1 ? totalPages - 1 : 1,
                    activeColor: theme.colorScheme.primary,
                    inactiveColor: Colors.white.withOpacity(0.3),
                    onChanged: totalPages > 1
                        ? controller.onSliderChanging
                        : null,
                    onChangeEnd: totalPages > 1
                        ? controller.onSliderChanged
                        : null,
                  ),
                ),
                Text(
                  '$totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Hàng nút điều khiển chương
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: canPrev ? controller.goToPreviousChapter : null,
                ),
                IconButton(
                  icon: const Icon(Icons.list_rounded),
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: () => _showChapterList(context, controller, theme),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  color: Colors.white,
                  iconSize: 28,
                  onPressed: canNext ? controller.goToNextChapter : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị danh sách chapter trong Bottom Sheet
  /// Người dùng có thể chọn chương khác để đọc
  void _showChapterList(
    BuildContext context,
    ReaderController controller,
    ThemeData theme,
  ) {
    controller.isOverlayVisible.value = false;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo nhỏ phía trên (handle)
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Danh sách chương', style: theme.textTheme.titleLarge),
            const Divider(height: 10),

            // Danh sách các chapter
            Expanded(
              child: Obx(() {
                final List<Chapter> chapters = controller.chapterList;
                return ListView.builder(
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    final bool isCurrent = controller.chapterId == chapter.id;

                    String title = "Ch. ${chapter.chapterNumber}";
                    if (chapter.title != null && chapter.title!.isNotEmpty) {
                      title += ": ${chapter.title}";
                    }

                    return ListTile(
                      title: Text(
                        title,
                        style: TextStyle(
                          color: isCurrent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Get.back();
                        controller.jumpToChapter(chapter);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
