import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';

import '../app/controllers/search_controller.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/manga_card.dart';

/// Màn hình tìm kiếm truyện theo tên và tag
class SearchScreen extends GetView<SearchController> {
  const SearchScreen({super.key});

  /// Danh sách tag mẫu (có thể lấy từ API)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Lấy màu text/icon cho AppBar dựa theo theme
    final Color appBarColor =
        theme.appBarTheme.iconTheme?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black);

    return Scaffold(
      appBar: AppBar(
        // TextField tìm kiếm
        title: TextField(
          controller: controller.textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm theo tên...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: appBarColor.withOpacity(0.7)),
          ),
          style: TextStyle(color: appBarColor),
          textInputAction: TextInputAction.search,
          // Khi nhấn enter, gọi hàm tìm kiếm từ controller
          onSubmitted: (_) => controller.performSearch(),
        ),
        actions: [
          // Nút xóa tìm kiếm nếu đã nhập hoặc chọn tag
          Obx(
            () =>
                (controller.textController.text.isEmpty &&
                    controller.selectedTags.isEmpty)
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: controller.clearSearch,
                  ),
          ),
        ],
        // Thanh chọn mode tìm kiếm AND/OR và danh sách tag
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn mode tìm kiếm (Tất cả / Bất kỳ)
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tìm theo tag:', style: theme.textTheme.titleSmall),
                      ToggleButtons(
                        isSelected: [
                          controller.tagSearchMode.value == 'and', // AND
                          controller.tagSearchMode.value == 'or', // OR
                        ],
                        onPressed: controller.onModeChanged,
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(
                          minHeight: 32,
                          minWidth: 60,
                        ),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Tất cả'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Bất kỳ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Danh sách tag dạng FilterChip
                Obx(() {
                  if (controller.allTags.isEmpty) {
                    return const SizedBox(
                      height: 36,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.allTags.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final tag = controller.allTags[index];
                        return Obx(
                          () => FilterChip(
                            label: Text(tag),
                            selected: controller.selectedTags.contains(tag),
                            onSelected: (isSelected) =>
                                controller.onTagSelected(isSelected, tag),
                            showCheckmark: false,
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        // Hiển thị loading khi đang tìm kiếm
        if (controller.isLoading.isTrue) {
          return const LoadingIndicator(message: 'Đang tìm kiếm...');
        }

        // Giao diện trước khi tìm kiếm
        if (!controller.hasSearched.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 80, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                  'Nhập tên hoặc chọn tag để tìm kiếm',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Giao diện khi không có kết quả
        if (controller.searchResults.isEmpty) {
          final query = controller.textController.text;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sentiment_dissatisfied,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    query.isNotEmpty
                        ? 'Không tìm thấy kết quả cho "$query"'
                        : 'Không tìm thấy kết quả cho các tag đã chọn',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }

        // Giao diện hiển thị kết quả tìm kiếm
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.searchResults.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 cột
            childAspectRatio: 0.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final manga = controller.searchResults[index];
            return MangaCard(
              title: manga.title,
              imageUrl: manga.coverUrl,
              onTap: () => controller.onMangaTap(manga.id, manga.title),
            );
          },
        );
      }),
    );
  }
}
