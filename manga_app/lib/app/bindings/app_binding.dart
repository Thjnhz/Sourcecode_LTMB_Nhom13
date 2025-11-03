import 'package:get/get.dart';
import '../../services/auth_service.dart'; // Đảm bảo import đúng
import '../../services/settings_service.dart'; // 1. Import SettingsService
import '../../services/connectivity_service.dart'; // 2. Import ConnectivityService

class AppBinding implements Bindings {
  @override
  void dependencies() {
    print("Initializing services via AppBinding...");
    Get.put<AuthService>(AuthService(), permanent: true);
    print("AppBinding dependencies initialized.");
    Get.put<SettingsService>(SettingsService(), permanent: true);

    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
  }
}
