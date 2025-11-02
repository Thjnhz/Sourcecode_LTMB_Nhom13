import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart'; // Service quản lý đăng nhập/đăng ký
import 'home_controller.dart'; // Controller của màn hình Home để điều hướng tab

/// Controller quản lý màn hình tài khoản (Đăng nhập / Đăng ký)
class AccountController extends GetxController {
  // Service xác thực người dùng, được khởi tạo sẵn trong GetX
  final AuthService authService = Get.find<AuthService>();

  // -----------------------------
  // State chung
  // -----------------------------
  var isLoggingIn = false.obs; // Trạng thái đang đăng nhập
  var isRegistering = false.obs; // Trạng thái đang đăng ký

  // -----------------------------
  // State cho Form Đăng nhập
  // -----------------------------
  final loginUsernameController =
      TextEditingController(); // Controller cho input username
  final loginPasswordController =
      TextEditingController(); // Controller cho input password
  var isLoginPasswordHidden = true.obs; // Ẩn/hiện mật khẩu đăng nhập

  // -----------------------------
  // State cho Form Đăng ký
  // -----------------------------
  final registerUsernameController =
      TextEditingController(); // Controller username đăng ký
  final registerEmailController =
      TextEditingController(); // Controller email đăng ký
  final registerPasswordController =
      TextEditingController(); // Controller password đăng ký
  var isRegisterPasswordHidden = true.obs; // Ẩn/hiện mật khẩu đăng ký

  // -----------------------------
  // State Tab: 0 = Đăng nhập, 1 = Đăng ký
  // -----------------------------
  var selectedTabIndex = 0.obs;

  @override
  void onClose() {
    // Giải phóng bộ nhớ cho các TextEditingController khi controller bị hủy
    loginUsernameController.dispose();
    loginPasswordController.dispose();
    registerUsernameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    super.onClose();
  }

  // -----------------------------
  // Actions / Hàm xử lý sự kiện
  // -----------------------------

  /// Chuyển đổi giữa tab Đăng nhập và Đăng ký
  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  /// Ẩn hoặc hiện mật khẩu khi nhập trong form đăng nhập
  void toggleLoginPasswordVisibility() {
    isLoginPasswordHidden.toggle();
  }

  /// Ẩn hoặc hiện mật khẩu khi nhập trong form đăng ký
  void toggleRegisterPasswordVisibility() {
    isRegisterPasswordHidden.toggle();
  }

  /// Xử lý đăng nhập
  Future<void> handleLogin() async {
    final username = loginUsernameController.text.trim();
    final password = loginPasswordController.text.trim();

    // Kiểm tra dữ liệu nhập
    if (username.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập tên đăng nhập và mật khẩu.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoggingIn(true); // Bật trạng thái đang đăng nhập
    try {
      bool success = await authService.login(username, password);
      if (success) {
        // Nếu đăng nhập thành công, chuyển sang tab Khám phá trong HomeController
        try {
          final homeController = Get.find<HomeController>();
          homeController.changeTabIndex(1); // Tab giữa thường là Khám phá
        } catch (e) {
          print("Không tìm thấy HomeController: $e");
        }
      }
    } finally {
      isLoggingIn(false); // Tắt trạng thái đang đăng nhập
    }
  }

  /// Xử lý đăng ký
  Future<void> handleRegister() async {
    final username = registerUsernameController.text.trim();
    final email = registerEmailController.text.trim();
    final password = registerPasswordController.text.trim();

    // Kiểm tra dữ liệu nhập
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập đầy đủ thông tin.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Kiểm tra định dạng email hợp lệ
    if (!GetUtils.isEmail(email)) {
      Get.snackbar(
        'Lỗi',
        'Địa chỉ email không hợp lệ.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Kiểm tra độ dài mật khẩu
    if (password.length < 6) {
      Get.snackbar(
        'Lỗi',
        'Mật khẩu phải có ít nhất 6 ký tự.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isRegistering(true); // Bật trạng thái đang đăng ký
    try {
      bool success = await authService.register(username, email, password);
      if (success) {
        // Đăng ký thành công, chuyển người dùng về tab Đăng nhập
        changeTab(0);

        // Xóa dữ liệu trong form đăng ký
        registerUsernameController.clear();
        registerEmailController.clear();
        registerPasswordController.clear();
      }
    } finally {
      isRegistering(false); // Tắt trạng thái đang đăng ký
    }
  }

  /// Xử lý đăng xuất
  Future<void> handleLogout() async {
    await authService.logout();
    // Giao diện sẽ tự động cập nhật nhờ Obx
  }
}
