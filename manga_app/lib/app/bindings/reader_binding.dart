// lib/app/bindings/reader_binding.dart

import 'package:get/get.dart';
import '../controllers/reader_controller.dart';

class ReaderBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReaderController>(() => ReaderController());
  }
}
