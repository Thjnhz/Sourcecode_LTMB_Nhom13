// lib/widgets/error_retry_widget.dart

import 'package:flutter/material.dart';

/// Widget hiển thị thông báo lỗi và nút "Thử lại".
/// Dùng trong các màn hình khi load dữ liệu thất bại (API lỗi, mạng chậm,...)
class ErrorRetryWidget extends StatelessWidget {
  /// Nội dung thông báo lỗi
  final String errorMessage;

  /// Callback khi người dùng nhấn nút "Thử lại"
  final VoidCallback onRetry;

  /// Constructor với các tham số bắt buộc
  const ErrorRetryWidget({
    required this.errorMessage,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Icon cảnh báo lỗi
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[600],
              size: 50,
            ),
            const SizedBox(height: 15),

            // Nội dung lỗi
            Text(
              'Đã xảy ra lỗi:\n$errorMessage',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),

            // Nút "Thử lại" với icon refresh
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
