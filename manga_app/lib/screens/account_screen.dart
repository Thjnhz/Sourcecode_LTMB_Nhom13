import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/controllers/account_controller.dart';
import '../services/auth_service.dart'; // Import AuthService để truy cập state
import '../services/settings_service.dart'; // Import SettingsService

/// Màn hình Tài khoản
/// Hiển thị giao diện: Đã đăng nhập (Cài đặt) / Chưa đăng nhập (Tab Login/Register)
class AccountScreen extends GetView<AccountController> {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy AuthService toàn cục
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
      // Không có AppBar riêng, vì nó là một tab
      body: SafeArea(
        child: Obx(() {
          // Quan sát trạng thái đăng nhập
          return authService.isAuthenticated.isTrue
              ? _buildLoggedInView(context, authService, controller)
              : _buildLoggedOutView(context, controller);
        }),
      ),
    );
  }

  // --- 1. Giao diện khi ĐÃ Đăng nhập (Kiểu Settings) ---
  Widget _buildLoggedInView(
    BuildContext context,
    AuthService authService,
    AccountController controller,
  ) {
    final theme = Theme.of(context);
    final SettingsService settingsService = Get.find<SettingsService>();

    return Obx(() {
      // Quan sát thông tin user
      final user = authService.currentUser.value;

      if (user == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // --- Thông tin User (Avatar + Tên) ---
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.5),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.email != null && user.email!.isNotEmpty)
                      Text(
                        user.email!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 40),

          // --- Cài đặt chung ---
          Text(
            'Cài đặt chung',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Chỉnh sửa hồ sơ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () =>
                Get.snackbar('Thông báo', 'Tính năng đang phát triển.'),
          ),

          // --- Cài đặt Theme ---
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Giao diện (Theme)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () => _showThemeDialog(
              context,
              settingsService,
            ), // Gọi hàm chọn theme
          ),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Thông báo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () =>
                Get.snackbar('Thông báo', 'Tính năng đang phát triển.'),
          ),

          const Divider(height: 30),

          // --- Nút đăng xuất ---
          Center(
            child: TextButton(
              onPressed: controller.handleLogout,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    });
  }

  // --- 2. Giao diện khi CHƯA Đăng nhập (Thiết kế lại với Tab) ---
  Widget _buildLoggedOutView(
    BuildContext context,
    AccountController controller,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Thanh Tab Đăng nhập / Đăng ký
        Obx(
          () => Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildTabButton(context, "Đăng nhập", 0, controller),
                _buildTabButton(context, "Đăng ký", 1, controller),
              ],
            ),
          ),
        ),

        // Form đăng nhập / đăng ký theo tab
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            child: Obx(
              () => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                // Chuyển đổi Form giữa Login (key=login) và Register (key=register)
                child: controller.selectedTabIndex.value == 0
                    ? _buildLoginForm(
                        context,
                        controller,
                        key: const ValueKey('login'),
                      )
                    : _buildRegisterForm(
                        context,
                        controller,
                        key: const ValueKey('register'),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. Helper: Widget Nút Tab tùy chỉnh ---
  Widget _buildTabButton(
    BuildContext context,
    String title,
    int index,
    AccountController controller,
  ) {
    final theme = Theme.of(context);
    final bool isSelected = controller.selectedTabIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  // --- 4. Helper: Form Đăng nhập ---
  Widget _buildLoginForm(
    BuildContext context,
    AccountController controller, {
    Key? key,
  }) {
    final theme = Theme.of(context);

    return Column(
      key: key,
      children: [
        const SizedBox(height: 10),
        TextField(
          controller: controller.loginUsernameController,
          decoration: _getInputDecoration(
            theme,
            'Tên đăng nhập',
            Icons.person_outline,
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        Obx(
          () => TextField(
            controller: controller.loginPasswordController,
            decoration:
                _getInputDecoration(
                  theme,
                  'Mật khẩu',
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isLoginPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: theme.hintColor,
                    ),
                    onPressed: controller.toggleLoginPasswordVisibility,
                  ),
                ),
            obscureText: controller.isLoginPasswordHidden.value,
          ),
        ),
        const SizedBox(height: 25),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isLoggingIn.isTrue
                ? null
                : controller.handleLogin,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: controller.isLoggingIn.isTrue
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // --- 5. Helper: Form Đăng ký ---
  Widget _buildRegisterForm(
    BuildContext context,
    AccountController controller, {
    Key? key,
  }) {
    final theme = Theme.of(context);

    return Column(
      key: key,
      children: [
        const SizedBox(height: 10),
        // Username
        TextField(
          controller: controller.registerUsernameController,
          decoration: _getInputDecoration(
            theme,
            'Tên đăng nhập',
            Icons.person_outline,
          ),
        ),
        const SizedBox(height: 16),
        // Email
        TextField(
          controller: controller.registerEmailController,
          decoration: _getInputDecoration(theme, 'Email', Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        // Password
        Obx(
          () => TextField(
            controller: controller.registerPasswordController,
            decoration:
                _getInputDecoration(
                  theme,
                  'Mật khẩu (ít nhất 6 ký tự)',
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isRegisterPasswordHidden.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: theme.hintColor,
                    ),
                    onPressed: controller.toggleRegisterPasswordVisibility,
                  ),
                ),
            obscureText: controller.isRegisterPasswordHidden.value,
          ),
        ),
        const SizedBox(height: 25),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isRegistering.isTrue
                ? null
                : controller.handleRegister,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: controller.isRegistering.isTrue
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Đăng ký', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // --- 6. Helper: Input Decoration chung ---
  InputDecoration _getInputDecoration(
    ThemeData theme,
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
    );
  }

  // --- 7. Helper: BottomSheet chọn Theme ---
  void _showThemeDialog(BuildContext context, SettingsService settingsService) {
    final theme = Theme.of(context);

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Wrap(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Text('Chọn giao diện', style: theme.textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_5_outlined),
              title: const Text('Sáng'),
              onTap: () {
                settingsService.switchTheme(ThemeMode.light);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_2_outlined),
              title: const Text('Tối'),
              onTap: () {
                settingsService.switchTheme(ThemeMode.dark);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto_outlined),
              title: const Text('Theo hệ thống'),
              onTap: () {
                settingsService.switchTheme(ThemeMode.system);
                Get.back();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
