import 'dart:async'; // Dùng cho StreamSubscription
import 'package:connectivity_plus/connectivity_plus.dart'; // Import thư viện
import 'package:flutter/material.dart'; // Dùng cho Colors
import 'package:get/get.dart';

/// Service này chạy toàn cục để lắng nghe trạng thái kết nối mạng
/// và tự động hiển thị SnackBar khi mất/có mạng.
class ConnectivityService extends GetxService {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final Rx<ConnectivityResult> _connectionStatus = ConnectivityResult.none.obs;

  bool _hasShownOfflineSnackbar = false;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    checkInitialConnection();
  }

  /// Kiểm tra kết nối ban đầu
  Future<void> checkInitialConnection() async {
    final List<ConnectivityResult> result = await Connectivity()
        .checkConnectivity();
    _updateConnectionStatus(result);
  }

  /// Hàm được gọi mỗi khi trạng thái mạng thay đổi
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Lấy 1 trạng thái đại diện (ví dụ: cái đầu tiên, hoặc 'none' nếu list rỗng)
    final representativeStatus = results.isNotEmpty
        ? results.first
        : ConnectivityResult.none;
    _connectionStatus.value = representativeStatus; // Cập nhật trạng thái

    // Coi là offline nếu list rỗng HOẶC nếu nó CHỈ chứa 'none'
    bool isOffline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);

    if (isOffline) {
      // --- Mất mạng ---
      if (!_hasShownOfflineSnackbar) {
        Get.snackbar(
          'Mất kết nối mạng',
          'Bạn đang offline. Vui lòng kiểm tra lại kết nối.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[700],
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          isDismissible: false,
        );
        _hasShownOfflineSnackbar = true;
      }
    } else {
      // --- Có mạng trở lại ---
      if (_hasShownOfflineSnackbar) {
        Get.snackbar(
          'Đã có kết nối trở lại',
          'Bạn đã online.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[600],
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        _hasShownOfflineSnackbar = false;
      }
    }
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
