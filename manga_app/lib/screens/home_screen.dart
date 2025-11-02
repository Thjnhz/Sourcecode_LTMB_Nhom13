import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/controllers/home_controller.dart';
import '../widgets/hot_manga_banner.dart';
import '../widgets/manga_card.dart';
import '../widgets/loading_indicator.dart';
import '../screens/account_screen.dart';
import '../screens/library_screen.dart';
import '../screens/chat_screen.dart';

/// Màn hình chính (HomeScreen) gồm 4 tab:
/// 0: Tủ truyện, 1: Khám phá, 2: Cộng đồng, 3: Tài khoản
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  /// Hàm xử lý refresh dữ liệu trang chủ
  Future<void> _handleRefresh() async {
    await controller.fetchHomePageData();
  }

  /// Widget hiển thị tab "Khám phá"
  Widget _buildHomeTab(BuildContext context) {
    return Obx(() {
      // Hiển thị loading nếu cả danh sách truyện hot và truyện mới đều rỗng
      if (controller.isLoading.isTrue &&
          controller.hotMangaList.isEmpty &&
          controller.latestMangaList.isEmpty) {
        return const LoadingIndicator(message: 'Đang tải trang chủ...');
      }

      // Luôn cho phép RefreshIndicator, kể cả khi đang loading
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner truyện hot
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: HotMangaBanner(
                    mangaList: controller.hotMangaList,
                    onTapManga: (id, title) => controller.onMangaTap(id, title),
                  ),
                ),

                // Tiêu đề danh sách truyện mới cập nhật
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Mới cập nhật',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // GridView hiển thị truyện mới
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.latestMangaList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final manga = controller.latestMangaList[index];
                    return MangaCard(
                      title: manga.title,
                      imageUrl: manga.coverUrl,
                      onTap: () => controller.onMangaTap(manga.id, manga.title),
                    );
                  },
                ),

                // Hiển thị loading indicator khi load thêm
                if (controller.isLoadingMore.isTrue)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                // Hiển thị thông báo khi đã xem hết truyện
                if (controller.hasMoreManga.isFalse &&
                    !controller.isLoading.isTrue)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: Text('Bạn đã xem hết truyện.')),
                  ),

                const SizedBox(height: 30), // Padding cuối để scroll thoải mái
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách các màn hình (tab) chính
    final List<Widget> screens = [
      // Tab 0: Tủ truyện (LibraryScreen đã có AppBar bên trong)
      const LibraryScreen(),

      // Tab 1: Khám phá
      Scaffold(
        appBar: AppBar(
          title: const Text('Khám phá'),
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: controller.navigateToSearch,
            ),
          ],
        ),
        body: _buildHomeTab(context),
      ),

      // Tab 2: Cộng đồng
      const SafeArea(child: ChatScreen()),

      // Tab 3: Tài khoản
      const SafeArea(child: AccountScreen()),
    ];

    return Scaffold(
      // IndexedStack giúp giữ trạng thái của các tab khi chuyển đổi
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: screens,
        ),
      ),

      // BottomNavigationBar cho phép chuyển tab
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTabIndex,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.collections_bookmark_outlined),
              activeIcon: Icon(Icons.collections_bookmark),
              label: 'Tủ truyện',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Cộng đồng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
