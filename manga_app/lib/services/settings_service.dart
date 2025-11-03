import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Quản lý và lưu trữ cài đặt ứng dụng, ví dụ như Theme.
class SettingsService extends GetxService {
  final _box = GetStorage(); // Instance của GetStorage
  final _key = 'theme_mode'; // Key để lưu trong storage

  /// Trả về ThemeMode đã lưu
  /// Mặc định là ThemeMode.system
  ThemeMode get initialTheme {
    return _loadThemeFromStorage();
  }

  /// Tải ThemeMode từ GetStorage
  ThemeMode _loadThemeFromStorage() {
    final themeString = _box.read<String>(_key);
    switch (themeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
      default: // Mặc định là hệ thống
        return ThemeMode.system;
    }
  }

  /// Lưu và chuyển đổi ThemeMode
  void switchTheme(ThemeMode newMode) {
    // 1. Cập nhật theme trong GetX
    Get.changeThemeMode(newMode);

    // 2. Lưu lựa chọn vào GetStorage
    _box.write(_key, newMode.toString());

    print("Theme changed to: ${newMode.toString()}");
  }
}
