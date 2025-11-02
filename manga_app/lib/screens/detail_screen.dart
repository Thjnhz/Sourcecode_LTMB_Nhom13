import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../app/controllers/detail_controller.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/manga_detail_header.dart';
import '../widgets/chapter_list_tile.dart';
import '../models/chapter.dart';

/// Màn hình hiển thị chi tiết truyện, bao gồm header, tag, mô tả và danh sách chương.
class DetailScreen extends GetView<DetailController> {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Formatter để hiển thị ngày (dd/MM/yyyy)
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          // --- Trạng thái đang tải dữ liệu ---
          if (controller.isLoading.isTrue) {
            return const LoadingIndicator(
              message: 'Đang tải chi tiết truyện...',
            );
          }

          // --- Trạng thái lỗi hoặc dữ liệu null ---
          if (controller.manga.value == null ||
              controller.errorMessage.value != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.errorMessage.value ??
                        'Không thể tải thông tin truyện.',
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: controller.fetchMangaDetailsAndChapters,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          // --- Trạng thái hiển thị dữ liệu ---
          final manga = controller.manga.value!;
          final chapters = controller.chapters;

          return CustomScrollView(
            slivers: [
              // 1. Header của truyện (cover, title, follow, đọc ngay)
              SliverToBoxAdapter(
                child: MangaDetailHeader(
                  manga: manga,
                  onReadNowPressed: controller.readFirstChapter,
                  isFollowed: controller.isFollowed.value,
                  isTogglingFollow: controller.isTogglingFollow.value,
                  onFollowPressed: controller.toggleFollowManga,
                ),
              ),

              // 2. Phần tag/genre
              if (manga.tags.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thể loại',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: manga.tags.map((tagName) {
                            return InkWell(
                              onTap: () {
                                // Bắt sự kiện click vào tag
                                Get.snackbar('Tag', tagName);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withOpacity(0.6),
                                  border: Border.all(
                                    color: theme.dividerColor.withOpacity(0.5),
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tagName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Phần mô tả truyện
              if (manga.description != null && manga.description!.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mô tả',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          manga.description!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                          maxLines: controller.isDescriptionExpanded.value
                              ? null
                              : 3,
                          overflow: TextOverflow.fade,
                        ),
                        InkWell(
                          onTap: controller.toggleDescriptionExpansion,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              controller.isDescriptionExpanded.value
                                  ? 'Thu gọn'
                                  : 'Xem thêm',
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Divider trước danh sách chương
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Divider(height: 25, thickness: 1),
                ),
              ),

              // 5. Header danh sách chương
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Danh sách chương (${chapters.length})',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 6. Danh sách chương
              if (chapters.isEmpty && !controller.isLoading.isTrue)
                const SliverFillRemaining(
                  child: Center(child: Text('Chưa có chương nào')),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final chapter = chapters[index];
                    final formattedDate = chapter.publishDate != null
                        ? dateFormatter.format(chapter.publishDate!)
                        : 'Chưa xác định';

                    return Column(
                      children: [
                        ChapterListTile(
                          chapterTitle: chapter.displayTitle,
                          publishDate: formattedDate,
                          onTap: () => controller.onChapterTap(chapter),
                        ),
                        if (index < chapters.length - 1)
                          const Divider(
                            height: 0,
                            indent: 16,
                            endIndent: 16,
                            thickness: 0.5,
                          ),
                      ],
                    );
                  }, childCount: chapters.length),
                ),

              // Padding cuối cùng
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        }),
      ),
    );
  }
}
