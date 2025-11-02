import 'package:get/get.dart';
import '../../services/auth_service.dart'; // Đảm bảo import đúng

class AppBinding implements Bindings {
  @override
  void dependencies() {
    print("Initializing services via AppBinding..."); // Thêm log để kiểm tra
    Get.put<AuthService>(AuthService(), permanent: true);
    print("AppBinding dependencies initialized."); // Thêm log
  }
}
