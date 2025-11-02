import 'package:flutter/material.dart';

/// Widget hiển thị loading với vòng tròn và thông báo (tùy chọn)
/// Có thể dùng khi chờ dữ liệu từ API hoặc chờ xử lý async
class LoadingIndicator extends StatelessWidget {
  /// Tin nhắn hiển thị bên dưới vòng tròn loading
  /// Mặc định: "Đang tải..."
  final String? message;

  const LoadingIndicator({this.message = 'Đang tải...', super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Vòng tròn loading
          const CircularProgressIndicator(),
          // Khoảng cách nếu có message
          if (message != null) const SizedBox(height: 15),
          // Hiển thị message màu xám nếu có
          if (message != null)
            Text(message!, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
