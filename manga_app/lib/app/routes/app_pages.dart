// lib/app/routes/app_pages.dart

import 'package:get/get.dart';

// -----------------------------
// Import Screens
// -----------------------------
import '../../screens/home_screen.dart';
import '../../screens/detail_screen.dart';
import '../../screens/reader_screen.dart';
import '../../screens/search_screen.dart';
import '../../screens/chat_screen.dart';
// -----------------------------
// Import Bindings
// -----------------------------
import '../bindings/home_binding.dart';
import '../bindings/detail_binding.dart';
import '../bindings/reader_binding.dart';
import '../bindings/search_binding.dart';
// -----------------------------
// Import App Routes Constants
// -----------------------------
import 'app_routes.dart';

/// Đây là danh sách tất cả các route của ứng dụng
/// Mỗi route được khai báo với:
/// - name: tên route (phải khớp với Routes.*)
/// - page: Widget trả về khi chuyển đến route
/// - binding: Binding liên kết Controller với route
class AppPages {
  static final routes = [
    // -----------------------------
    // Home Screen
    // -----------------------------
    GetPage(
      name: Routes.HOME,
      page: () => const HomeScreen(), // Widget HomeScreen
      binding: HomeBinding(), // Binding cho HomeController
    ),

    // -----------------------------
    // Detail Screen (Chi tiết manga)
    // -----------------------------
    GetPage(
      name: Routes.DETAIL,
      page: () => const DetailScreen(), // Widget DetailScreen
      binding: DetailBinding(), // Binding để inject DetailController
    ),

    // -----------------------------
    // Reader Screen (Đọc chapter)
    // -----------------------------
    GetPage(
      name: Routes.READER,
      page: () => const ReaderScreen(), // Widget ReaderScreen
      binding: ReaderBinding(), // Binding ReaderController
    ),

    // -----------------------------
    // Search Screen
    // -----------------------------
    GetPage(
      name: Routes.SEARCH,
      page: () => const SearchScreen(), // Widget SearchScreen
      binding: SearchBinding(), // Binding SearchController
    ),

    // -----------------------------
    // Chat Screen (nếu có)
    // -----------------------------
    GetPage(
      name: Routes.CHAT,
      page: () => const ChatScreen(), // Widget ChatScreen
      // Binding có thể thêm nếu cần ChatController
      // binding: ChatBinding(),
    ),
  ];
}
