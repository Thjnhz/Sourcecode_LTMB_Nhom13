import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../app/controllers/library_controller.dart';
import '../app/controllers/home_controller.dart'; // Dùng để chuyển tab khi chưa đăng nhập
import '../services/manga_service.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/manga_card.dart';
import '../models/history_manga.dart';
import '../models/library_manga.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LibraryScreen extends GetView<LibraryController> {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final MangaService mangaService = Get.find<MangaService>();

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          // Nếu người dùng chưa đăng nhập → hiển thị giao diện yêu cầu đăng nhập
          if (!controller.isAuthenticated.isTrue) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 60, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text('Vui lòng đăng nhập', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Đăng nhập để xem Tủ truyện và Lịch sử đọc.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        // Chuyển sang tab Tài khoản nếu có HomeController
                        final homeController = Get.find<HomeController>();
                        homeController.changeTabIndex(3);
                      } catch (e) {
                        debugPrint("Lỗi khi chuyển tab: $e");
                      }
                    },
                    child: const Text('Đi đến trang Đăng nhập'),
                  ),
                ],
              ),
            );
          }

          // Nếu người dùng đã đăng nhập → hiển thị Tab "Lịch sử" và "Theo dõi"
          return Column(
            children: [
              // Thanh Tab điều hướng giữa "Lịch sử" và "Theo dõi"
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 0.5),
                  ),
                ),
                child: TabBar(
                  controller: controller.tabController,
                  tabs: const [
                    Tab(text: 'Lịch sử'),
                    Tab(text: 'Theo dõi'),
                  ],
                  labelColor:
                      theme.textTheme.bodyLarge?.color ??
                      theme.colorScheme.onSurface,
                  unselectedLabelColor: theme.hintColor,
                  indicatorColor: theme.colorScheme.primary,
                ),
              ),

              // Nội dung của từng tab
              Expanded(
                child: TabBarView(
                  controller: controller.tabController,
                  children: [
                    _buildHistoryList(mangaService),
                    _buildLibraryList(mangaService),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// ---------------- TAB 1: LỊCH SỬ ----------------
  ///
  /// Hiển thị danh sách truyện mà người dùng đã đọc gần đây
  Widget _buildHistoryList(MangaService mangaService) {
    return Obx(() {
      // Đang tải dữ liệu → hiển thị vòng tròn loading
      if (controller.isLoading.isTrue) {
        return const LoadingIndicator(message: 'Đang tải lịch sử...');
      }

      // Nếu có lỗi và danh sách rỗng → hiển thị widget báo lỗi + nút thử lại
      if (controller.errorMessage.value != null &&
          controller.historyList.isEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorRetryWidget(
            errorMessage: controller.errorMessage.value!,
            onRetry: () => controller.fetchLibraryData(),
          ),
        );
      }

      // Hiển thị danh sách lịch sử, có thể kéo để làm mới
      return RefreshIndicator(
        onRefresh: () => controller.fetchLibraryData(),
        child: Obx(() {
          // Nếu danh sách rỗng → hiển thị thông báo "Không có lịch sử"
          if (controller.historyList.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: Get.height * 0.5,
                  child: const Center(child: Text('Không có lịch sử đọc.')),
                ),
              ],
            );
          }

          // Có dữ liệu → hiển thị danh sách truyện đã đọc
          return ListView.builder(
            itemCount: controller.historyList.length,
            itemBuilder: (context, index) {
              final HistoryManga item = controller.historyList[index];
              final coverUrl = mangaService.buildCoverUrl(
                item.mangaId,
                item.coverFilename,
              );

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (c, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (c, url, err) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey[400]),
                    ),
                  ),
                ),
                title: Text(
                  item.mangaTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.displayChapterTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  DateFormat('dd/MM').format(item.lastReadAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => controller.onChapterTap(item.chapterId),
              );
            },
          );
        }),
      );
    });
  }

  /// ---------------- TAB 2: THEO DÕI ----------------
  ///
  /// Hiển thị danh sách các truyện mà người dùng đã theo dõi
  Widget _buildLibraryList(MangaService mangaService) {
    return Obx(() {
      // Đang tải dữ liệu → hiển thị vòng tròn loading
      if (controller.isLoading.isTrue) {
        return const LoadingIndicator(message: 'Đang tải truyện theo dõi...');
      }

      // Nếu có lỗi và danh sách rỗng → hiển thị widget báo lỗi + nút thử lại
      if (controller.errorMessage.value != null &&
          controller.libraryList.isEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ErrorRetryWidget(
            errorMessage: controller.errorMessage.value!,
            onRetry: () => controller.fetchLibraryData(),
          ),
        );
      }

      // Hiển thị danh sách truyện theo dõi (dạng lưới)
      return RefreshIndicator(
        onRefresh: () => controller.fetchLibraryData(),
        child: Obx(() {
          // Nếu danh sách rỗng → hiển thị thông báo
          if (controller.libraryList.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: Get.height * 0.5,
                  child: const Center(
                    child: Text('Bạn chưa theo dõi truyện nào.'),
                  ),
                ),
              ],
            );
          }

          // Có dữ liệu → hiển thị dạng GridView
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: controller.libraryList.length,
            itemBuilder: (context, index) {
              final LibraryManga item = controller.libraryList[index];
              final coverUrl = mangaService.buildCoverUrl(
                item.mangaId,
                item.coverFilename,
              );

              return MangaCard(
                title: item.title,
                imageUrl: coverUrl,
                onTap: () => controller.onMangaTap(item.mangaId),
              );
            },
          );
        }),
      );
    });
  }
}
