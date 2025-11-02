import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/controllers/detail_controller.dart';
import '../../models/chapter.dart';

/// Màn hình chi tiết truyện
/// Hiển thị:
/// - Cover truyện + tiêu đề
/// - Thông tin tổng quan (status, view, description)
/// - Danh sách chương
/// - Nút hành động: đọc ngay, xem chương mới
class DetailScreen extends GetView<DetailController> {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        // Hiển thị loading nếu đang lấy dữ liệu
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final manga = controller.manga.value;
        final chapters = controller.chapters;

        // Nếu không tìm thấy truyện
        if (manga == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'Không tìm thấy truyện',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          );
        }

        // RefreshIndicator để hỗ trợ kéo xuống refresh
        return RefreshIndicator(
          onRefresh: () async => controller.fetchMangaDetailsAndChapters(),
          child: CustomScrollView(
            slivers: [
              // --- Cover và tiêu đề ---
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.black87),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: _buildTitleOverlay(manga.title),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover truyện
                      if (manga.coverUrl != null && manga.coverUrl!.isNotEmpty)
                        Image.network(
                          manga.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coverPlaceholder(),
                        )
                      else
                        _coverPlaceholder(),
                      // Gradient để chữ tiêu đề đọc được trên cover
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      // TODO: Toggle favorite (cần implement)
                      Get.snackbar('Tính năng', 'Đã lưu tạm (chưa implement)');
                    },
                    icon: const Icon(Icons.favorite_border),
                  ),
                ],
              ),

              // --- Card tổng quan truyện ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: _OverviewCard(
                    mangaDescription: manga.description ?? '',
                    manga: manga,
                  ),
                ),
              ),

              // --- Nút hành động: đọc ngay / xem chương mới ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (controller.chapters.isNotEmpty) {
                              controller.onChapterTap(
                                controller.chapters.first,
                              );
                            } else {
                              Get.snackbar(
                                'Thông báo',
                                'Chưa có chương để đọc.',
                              );
                            }
                          },
                          icon: const Icon(Icons.chrome_reader_mode_outlined),
                          label: const Text('Đọc ngay'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          if (controller.chapters.isNotEmpty) {
                            controller.onChapterTap(controller.chapters.first);
                          }
                        },
                        tooltip: 'Xem chương mới nhất',
                        icon: const Icon(Icons.arrow_downward),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Header danh sách chương ---
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeader(title: 'Danh sách chương', height: 56),
              ),

              // --- Danh sách chương ---
              if (chapters.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.list_alt_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chưa có chương nào',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final Chapter ch = chapters[index];
                    return ChapterListTile(
                      chapter: ch,
                      index: index + 1,
                      onTap: () => controller.onChapterTap(ch),
                    );
                  }, childCount: chapters.length),
                ),

              // Padding cuối trang
              SliverToBoxAdapter(child: SizedBox(height: 36)),
            ],
          ),
        );
      }),
    );
  }

  /// Placeholder cover nếu truyện không có ảnh
  Widget _coverPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 84,
          color: Colors.white70,
        ),
      ),
    );
  }

  /// Overlay tiêu đề trên cover
  Widget _buildTitleOverlay(String? title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title ?? 'Không có tiêu đề',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ---------------- Widget nhỏ ----------------

/// Card hiển thị tổng quan truyện: status, view, description
class _OverviewCard extends StatelessWidget {
  final String mangaDescription;
  final dynamic manga;

  const _OverviewCard({
    required this.mangaDescription,
    required this.manga,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manga.title ?? 'Không tên',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(label: Text(manga.status ?? '---')),
                    const SizedBox(height: 6),
                    Text('${manga.viewCount ?? "0"} lượt xem'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mở rộng/thu gọn description nếu quá dài
            AnimatedCrossFade(
              firstChild: Text(
                mangaDescription,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(mangaDescription),
              crossFadeState: mangaDescription.length > 200
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}

/// ListTile cho từng chapter
class ChapterListTile extends StatelessWidget {
  final Chapter chapter;
  final int index;
  final VoidCallback? onTap;

  const ChapterListTile({
    required this.chapter,
    required this.index,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(
                  index.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  chapter.displayTitle ?? chapter.title ?? 'Chương $index',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header cố định cho danh sách chương
class _SliverHeader extends SliverPersistentHeaderDelegate {
  final String title;
  final double height;

  _SliverHeader({required this.title, this.height = 56});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _SliverHeader oldDelegate) {
    return oldDelegate.title != title || oldDelegate.height != height;
  }
}
