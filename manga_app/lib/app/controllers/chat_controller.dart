import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/auth_service.dart';

/// Controller quản lý chat realtime với Firebase
class ChatController extends GetxController {
  // Service quản lý xác thực người dùng
  final AuthService _authService = Get.find<AuthService>();

  // Firebase
  FirebaseDatabase?
  _db; // Instance FirebaseDatabase, nullable để reset khi logout
  DatabaseReference? _chatRef; // Reference tới chat room

  // -----------------------------
  // State
  // -----------------------------
  var isLoading = true.obs; // Trạng thái đang load tin nhắn
  var messages = <Map<String, dynamic>>[].obs; // Danh sách tin nhắn hiển thị
  var isNotAuthenticated = false.obs; // Người dùng chưa đăng nhập

  // -----------------------------
  // Controllers
  // -----------------------------
  final TextEditingController messageController =
      TextEditingController(); // Controller input tin nhắn
  final ScrollController scrollController =
      ScrollController(); // Controller scroll chat

  // -----------------------------
  // Thông tin người dùng
  // -----------------------------
  String? _userId; // ID người dùng hiện tại
  String? _username; // Tên người dùng hiện tại

  // -----------------------------
  // Subscription Firebase
  // -----------------------------
  StreamSubscription<DatabaseEvent>? _chatSubscription;

  @override
  void onInit() {
    super.onInit();

    // Lắng nghe sự thay đổi user từ AuthService
    ever(_authService.currentUser, (user) {
      if (user != null) {
        // Nếu user login
        _userId = user.id.toString();
        _username = user.username;
        isNotAuthenticated.value = false;
        _initFirebase();
      } else {
        // Nếu user logout
        isNotAuthenticated.value = true;
        isLoading.value = false;
        _resetChat();
      }
    });

    // Kiểm tra nếu user đã login trước đó
    final user = _authService.currentUser.value;
    if (user != null) {
      _userId = user.id.toString();
      _username = user.username;
      isNotAuthenticated.value = false;
      _initFirebase();
    } else {
      isNotAuthenticated.value = true;
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Hủy subscription, giải phóng controller khi dispose
    _resetChat();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // -----------------------------
  // Hàm khởi tạo Firebase và lắng nghe tin nhắn
  // -----------------------------
  void _initFirebase() {
    // Chỉ khởi tạo nếu chưa có instance
    _db ??= FirebaseDatabase.instance;
    _chatRef ??= _db!.ref('public_chat_room');

    _listenForMessages();
  }

  // -----------------------------
  // Reset chat khi logout hoặc dispose
  // -----------------------------
  void _resetChat() {
    _chatSubscription?.cancel();
    _chatSubscription = null;

    _db = null;
    _chatRef = null;

    messages.clear();
    _userId = null;
    _username = null;
    isLoading.value = false;
  }

  // -----------------------------
  // Lắng nghe tin nhắn realtime
  // -----------------------------
  void _listenForMessages() {
    if (_chatRef == null) return;

    isLoading.value = true;

    _chatSubscription = _chatRef!
        .orderByChild('timestamp') // Sắp xếp theo thời gian
        .limitToLast(50) // Lấy 50 tin nhắn gần nhất
        .onValue
        .listen(
          (DatabaseEvent event) {
            final snapshotValue = event.snapshot.value;

            if (snapshotValue != null && snapshotValue is Map) {
              try {
                // Chuyển dữ liệu Firebase thành Map<String, dynamic>
                final data = Map<String, dynamic>.from(snapshotValue);

                // Tạo danh sách tin nhắn
                final messageList = data.entries
                    .map((entry) {
                      final val = entry.value;
                      if (val is Map) {
                        return Map<String, dynamic>.from(val);
                      }
                      return <String, dynamic>{};
                    })
                    .where((m) => m.isNotEmpty)
                    .toList();

                // Sắp xếp tin nhắn theo timestamp tăng dần
                messageList.sort(
                  (a, b) =>
                      (a['timestamp'] as int).compareTo(b['timestamp'] as int),
                );

                // Đảo ngược để tin mới nhất lên trên cùng
                messages.value = messageList.reversed.toList();
              } catch (e) {
                print('Lỗi khi parse tin nhắn: $e');
                messages.value = [];
              }
            } else {
              messages.value = [];
            }

            isLoading.value = false;
            _scrollToBottom();
          },
          onError: (error) {
            isLoading.value = false;
            messages.value = [];
            Get.snackbar('Lỗi', 'Không thể tải tin nhắn: $error');
            print('Chat listen error: $error');
          },
        );
  }

  // -----------------------------
  // Gửi tin nhắn
  // -----------------------------
  Future<void> sendMessage() async {
    if (isNotAuthenticated.isTrue || _chatRef == null) {
      Get.snackbar('Cảnh báo', 'Vui lòng đăng nhập để gửi tin nhắn.');
      messageController.clear();
      return;
    }

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();

    try {
      await _chatRef!.push().set({
        'text': text, // Nội dung tin nhắn
        'senderId': _userId, // ID người gửi
        'senderName': _username, // Tên người gửi
        'timestamp': ServerValue.timestamp, // Thời gian gửi
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể gửi tin nhắn: $e');
      messageController.text = text; // Khôi phục nội dung nếu gửi thất bại
    }
  }

  // -----------------------------
  // Cuộn xuống cuối danh sách chat
  // -----------------------------
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients && messages.isNotEmpty) {
        scrollController.animateTo(
          0.0, // Tin mới nhất đã reversed, nên scroll về đầu
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // -----------------------------
  // Kiểm tra tin nhắn có phải của người dùng hiện tại
  // -----------------------------
  bool isMyMessage(String? senderId) {
    if (_userId == null || senderId == null) return false;
    return senderId == _userId;
  }
}
