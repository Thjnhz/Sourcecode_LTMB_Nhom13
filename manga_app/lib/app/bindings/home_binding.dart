import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/account_controller.dart'; // Import AccountController
import '../../services/manga_service.dart'; // Import MangaService
import '../controllers/library_controller.dart'; // Import LibraryController
import '../controllers/chat_controller.dart'; // Import ChatController
// AuthService is initialized globally by AppBinding

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    // Initialize MangaService if it's not globally initialized in AppBinding
    // If MangaService IS initialized in AppBinding, you can keep this line commented.
    Get.lazyPut<MangaService>(
      () => MangaService(),
    ); // <-- UNCOMMENTED THIS LINE

    // Initialize HomeController
    Get.lazyPut<HomeController>(() => HomeController());

    // Initialize AccountController here
    Get.lazyPut<AccountController>(() => AccountController());

    // Initialize LibraryController here if needed
    Get.lazyPut<LibraryController>(() => LibraryController());

    Get.lazyPut<ChatController>(() => ChatController());
  }
}
