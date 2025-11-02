import 'package:flutter/material.dart'; // Import for Colors
import 'package:get/get.dart';

// Import Models
import '../../models/manga.dart';
import '../../models/chapter.dart';

// Import Services
import '../../services/manga_service.dart'; // Import Service
import '../../services/auth_service.dart'; // Import AuthService

// Import Routes
import '../routes/app_routes.dart';

// Import LibraryController to refresh library data
import 'library_controller.dart';

/// Controller cho Màn hình Chi tiết.
/// Quản lý việc lấy chi tiết manga, chapter, trạng thái theo dõi, và các tương tác UI.
class DetailController extends GetxController {
  // --- Dependencies ---
  final MangaService _mangaService = Get.find<MangaService>();
  final AuthService _authService = Get.find<AuthService>();

  // --- State Variables ---
  var isLoading = true.obs;
  var manga = Rxn<Manga>();
  var chapters = <Chapter>[].obs;
  var isDescriptionExpanded = false.obs;
  var errorMessage = RxnString();
  late String mangaId;

  // --- Library/Follow State ---
  var isFollowed = false.obs; // Trạng thái đã theo dõi hay chưa
  var isTogglingFollow = false.obs; // Trạng thái đang xử lý nhấn nút theo dõi
  var libraryStatus = 'reading'.obs; // Trạng thái đọc (mặc định)

  // --- Lifecycle Methods ---
  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// Khởi tạo controller, lấy mangaId và bắt đầu fetch dữ liệu.
  void _initialize() {
    if (Get.arguments != null && Get.arguments is String) {
      mangaId = Get.arguments as String;
      fetchMangaDetailsAndChapters(); // Bắt đầu lấy dữ liệu
    } else {
      isLoading(false);
      errorMessage.value = "Error: Invalid Manga ID provided.";
      print("DetailController Error: Missing or invalid mangaId argument.");
      Get.snackbar(
        'Error',
        'Could not load manga details. Invalid ID.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // --- Data Fetching ---
  /// Lấy chi tiết manga và danh sách chapter (và kiểm tra trạng thái theo dõi)
  Future<void> fetchMangaDetailsAndChapters() async {
    try {
      isLoading(true);
      chapters.clear();
      isDescriptionExpanded(false);
      errorMessage.value = null;

      // Chạy song song 3 tác vụ: lấy chi tiết, lấy chapter, kiểm tra thư viện
      final results = await Future.wait([
        _mangaService.getMangaDetails(mangaId),
        _mangaService.getChapters(mangaId),
        _checkIfFollowed(), // Kiểm tra trạng thái theo dõi
      ]);

      // Gán kết quả
      manga.value = results[0] as Manga?;
      chapters.assignAll(results[1] as List<Chapter>);

      if (manga.value == null) {
        throw Exception("Failed to retrieve manga details data.");
      }
    } catch (e) {
      print('Error fetching details/chapters for $mangaId: $e');
      errorMessage.value = "Error loading data: ${e.toString()}";
      Get.snackbar(
        'Error',
        'Failed to load manga details: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // --- Library/Follow Actions ---

  /// Kiểm tra xem manga này đã có trong thư viện của user chưa
  Future<void> _checkIfFollowed() async {
    // Chỉ kiểm tra nếu đã đăng nhập
    if (!_authService.isAuthenticated.isTrue) {
      isFollowed.value = false;
      return;
    }
    try {
      final library = await _mangaService.getLibrary();

      // ⚠️ ĐÃ SỬA: Truy cập 'mangaId' (theo model bạn cung cấp)
      final libraryEntry = library.firstWhereOrNull(
        (libManga) => libManga.mangaId == mangaId,
      );

      if (libraryEntry != null) {
        isFollowed.value = true;
        // ⚠️ ĐÃ SỬA: Dùng 'userStatus' và xử lý null (theo model bạn cung cấp)
        libraryStatus.value = libraryEntry.userStatus ?? 'reading';
      } else {
        isFollowed.value = false;
      }
    } catch (e) {
      print("Error checking follow status: $e");
      isFollowed.value = false; // Mặc định là false nếu có lỗi
    }
  }

  /// Xử lý khi người dùng nhấn nút "Theo dõi" / "Bỏ theo dõi".
  ///
  /// - Kiểm tra trạng thái đăng nhập trước (yêu cầu đăng nhập để thay đổi thư viện).
  /// - Ngăn chặn nhấn liên tục bằng `isTogglingFollow`.
  /// - Gọi API qua `_mangaService.addToLibrary` / `.removeFromLibrary`.
  /// - Chỉ cập nhật trạng thái UI (`isFollowed`, `libraryStatus`) **sau khi API trả về thành công**.
  /// - Sau khi thành công, cố gắng làm mới `LibraryController` (nếu đang được register) bằng `fetchLibraryData()`
  ///   để giao diện Tủ truyện / Lịch sử tự động cập nhật.
  /// - Bắt và xử lý lỗi, hiển thị `Get.snackbar` khi cần, và luôn đặt `isTogglingFollow(false)` trong `finally`.
  Future<void> toggleFollowManga() async {
    // Yêu cầu đăng nhập trước khi thao tác
    if (!_authService.isAuthenticated.isTrue) {
      Get.snackbar(
        'Chưa đăng nhập',
        'Bạn cần đăng nhập để theo dõi truyện.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // Nếu đang trong tiến trình toggle, chặn thao tác tiếp
    if (isTogglingFollow.isTrue) return;

    try {
      // Đánh dấu đang xử lý (vô hiệu hóa nút)
      isTogglingFollow(true);

      if (isFollowed.isTrue) {
        // --- Trường hợp: hiện đang theo dõi -> Gọi API để bỏ theo dõi ---
        await _mangaService.removeFromLibrary(mangaId);

        // Nếu không có exception => thành công, cập nhật state cục bộ
        isFollowed.value = false;
        Get.snackbar(
          'Đã bỏ theo dõi',
          'Đã xóa "${manga.value?.title ?? 'truyện'}" khỏi thư viện.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        // --- Trường hợp: chưa theo dõi -> Gọi API để thêm vào thư viện ---
        const String newStatus = 'reading'; // trạng thái mặc định khi thêm
        await _mangaService.addToLibrary(mangaId, newStatus);

        // Nếu không có exception => thành công, cập nhật state cục bộ
        isFollowed.value = true;
        libraryStatus.value = newStatus;
        Get.snackbar(
          'Đã theo dõi',
          'Đã thêm "${manga.value?.title ?? 'truyện'}" vào thư viện.',
          snackPosition: SnackPosition.TOP,
        );
      }

      // --- Cố gắng làm mới LibraryController (nếu tồn tại) ---
      try {
        if (Get.isRegistered<LibraryController>()) {
          final libCtrl = Get.find<LibraryController>();
          // Gọi fetchLibraryData để update UI của Library (history / library)
          await libCtrl.fetchLibraryData();
          debugPrint(
            'LibraryController.fetchLibraryData() đã được gọi sau khi toggle follow.',
          );
        } else {
          debugPrint('LibraryController không được đăng ký — bỏ qua refresh.');
        }
      } catch (e) {
        // Không muốn làm app crash nếu không thể refresh; chỉ log để debug
        debugPrint('Lỗi khi refresh LibraryController: $e');
      }
    } catch (e, st) {
      // Ghi log để debug (bao gồm stacktrace)
      debugPrint('Error toggling follow for manga $mangaId: $e\n$st');

      // Hiển thị lỗi cho người dùng (thông báo thân thiện)
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật thư viện: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // Luôn bật lại nút (kết thúc trạng thái "đang xử lý")
      isTogglingFollow(false);
    }
  }

  // --- UI Actions ---
  /// Toggles the expanded state of the manga description text.
  void toggleDescriptionExpansion() {
    isDescriptionExpanded.toggle(); // Simple boolean toggle
  }

  /// Navigates to the ReaderScreen for the selected chapter.
  void onChapterTap(Chapter chapter) {
    print('Tapped Chapter: ${chapter.displayTitle} (ID: ${chapter.id})');
    // Cập nhật lịch sử (không cần await)
    _mangaService.updateReadingHistory(chapter.id);
    // Navigate using GetX, passing chapter ID as argument
    Get.toNamed(Routes.READER, arguments: chapter.id);
  }

  /// Finds the first chapter (logically chapter 1) and navigates to the ReaderScreen.
  /// Assumes the chapter list from the API is sorted DESCENDING by chapter number/date.
  void readFirstChapter() {
    if (chapters.isEmpty) {
      Get.snackbar(
        'Info',
        'This manga has no chapters yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return; // Stop if no chapters available
    }

    // Since the API returns chapters sorted DESC (newest first),
    // the actual "first" chapter (Chapter 1 or earliest) is the last in the list.
    Chapter firstChapter = chapters.last;

    print(
      'Reading First Chapter: ${firstChapter.displayTitle} (ID: ${firstChapter.id})',
    );
    // Cập nhật lịch sử (không cần await)
    _mangaService.updateReadingHistory(firstChapter.id);
    // Navigate to the reader screen with the first chapter's ID
    Get.toNamed(Routes.READER, arguments: firstChapter.id);
  }
}
