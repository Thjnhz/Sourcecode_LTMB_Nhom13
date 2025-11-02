// 1. IMPORT FIREBASE VÀ CÁC THƯ VIỆN CẦN THIẾT
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Import routing và binding
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/app_binding.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding sẵn sàng trước khi gọi async code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. KHỞI TẠO FIREBASE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. KHỞI TẠO GetStorage để AuthService có thể đọc/ghi token
  await GetStorage.init();

  // 4. Chạy app với MyApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      themeMode: ThemeMode.system,

      // --- Routing ---
      initialRoute: Routes.HOME, // Route bắt đầu
      getPages: AppPages.routes, // Danh sách các trang
      // --- INITIAL BINDING ---
      initialBinding: AppBinding(), // Kích hoạt AppBinding để init services
    );
  }
}
