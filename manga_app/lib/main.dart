import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Import routing và binding
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/app_binding.dart';
import 'services/auth_service.dart'; // Cần cho hàm init
import 'services/manga_service.dart'; // Cần cho hàm init
import 'services/settings_service.dart'; // Cần cho hàm init

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. KHỞI TẠO GETSTORAGE & FIREBASE
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. ⚠️ GỌI HÀM KHỞI TẠO SERVICES TRỰC TIẾP Ở ĐÂY
  initServices();

  // 3. Chạy app
  runApp(const MyApp());
}

/// Khởi tạo TẤT CẢ các service toàn cục
void initServices() {
  print("Initializing services...");
  // ⚠️ Get.put (permanent: true) cho các service toàn cục
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<MangaService>(MangaService(), permanent: true);
  Get.put<SettingsService>(SettingsService(), permanent: true);
  print("Services initialized.");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. Tìm SettingsService (ĐÃ KHỞI TẠO trong initServices)
    final SettingsService settingsService = Get.find<SettingsService>();

    return GetMaterialApp(
      title: 'Manga Reader App',
      debugShowCheckedModeBanner: false,

      // --- Theme ---
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 5. Đặt themeMode ban đầu từ service
      themeMode: settingsService.initialTheme,

      // --- Routing ---
      initialRoute: Routes.HOME,
      getPages: AppPages.routes,
      // 6. ⚠️ initialBinding KHÔNG CẦN NỮA VÌ CÁC SERVICE ĐÃ ĐƯỢC PUT
      //    (Nhưng chúng ta vẫn cần đảm bảo các Controller khác được khởi tạo)
      //    Chúng ta cần tạo lại AppBinding để chỉ khởi tạo các Controllers còn lại
      initialBinding: AppBinding(),
    );
  }
}
