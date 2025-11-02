// lib/app/bindings/detail_binding.dart

import 'package:get/get.dart';
import '../controllers/detail_controller.dart';

class DetailBinding implements Bindings {
  @override
  void dependencies() {
    // Chỉ cần khởi tạo DetailController
    // MangaService đã được đăng ký ở HomeBinding (hoặc AppBinding)
    Get.lazyPut<DetailController>(() => DetailController());
  }
}
