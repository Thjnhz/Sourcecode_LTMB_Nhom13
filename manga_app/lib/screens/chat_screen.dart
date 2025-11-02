import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Thư viện format thời gian
import '../app/controllers/chat_controller.dart';
import '../widgets/loading_indicator.dart';

/// Màn hình Chat Cộng đồng
/// Hiển thị:
/// - Danh sách tin nhắn realtime
/// - Ô nhập tin nhắn và nút gửi
class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Danh sách tin nhắn ---
            Expanded(
              child: Obx(() {
                // Nếu đang load và danh sách tin nhắn rỗng -> hiển thị loading
                if (controller.isLoading.isTrue &&
                    controller.messages.isEmpty) {
                  return const LoadingIndicator(
                    message: 'Đang tải tin nhắn...',
                  );
                }

                // Nếu danh sách tin nhắn rỗng -> thông báo chưa có tin nhắn
                if (controller.messages.isEmpty) {
                  return const Center(child: Text('Chưa có tin nhắn nào.'));
                }

                // Hiển thị danh sách tin nhắn
                return ListView.builder(
                  controller: controller.scrollController,
                  reverse: true, // Hiển thị tin nhắn mới ở dưới
                  itemCount: controller.messages.length,
                  padding: const EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    // Xác định tin nhắn của mình hay người khác
                    final isMe = controller.isMyMessage(
                      message['senderId'] ?? '',
                    );
                    return _buildMessageBubble(message, isMe, theme);
                  },
                );
              }),
            ),

            // --- Ô nhập tin nhắn ---
            _buildMessageInput(context, theme),
          ],
        ),
      ),
    );
  }

  /// Widget ô nhập tin nhắn + nút gửi
  Widget _buildMessageInput(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          // Ô nhập văn bản
          Expanded(
            child: TextField(
              controller: controller.messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => controller.sendMessage(),
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Nút gửi tin nhắn
          IconButton(
            icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
            onPressed: controller.sendMessage,
          ),
        ],
      ),
    );
  }

  /// Widget bong bóng tin nhắn
  /// isMe = true nếu là tin nhắn của người dùng hiện tại
  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isMe,
    ThemeData theme,
  ) {
    // Chuyển timestamp từ int sang DateTime
    DateTime? timestamp;
    if (message['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
    }

    // Format thời gian hiển thị HH:mm
    final timeString = timestamp != null
        ? DateFormat('HH:mm').format(timestamp)
        : '...';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Hiển thị tên người gửi nếu không phải tin nhắn của mình
          if (!isMe)
            Text(
              message['senderName'] ?? 'Anonymous',
              style: TextStyle(
                fontSize: 12,
                color: theme.hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (!isMe) const SizedBox(height: 2),
          // Bong bóng tin nhắn
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe
                    ? const Radius.circular(16)
                    : const Radius.circular(0),
                bottomRight: isMe
                    ? const Radius.circular(0)
                    : const Radius.circular(16),
              ),
            ),
            child: Text(
              message['text'] ?? '',
              style: TextStyle(
                color: isMe
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Thời gian gửi
          Text(
            timeString,
            style: TextStyle(fontSize: 10, color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
