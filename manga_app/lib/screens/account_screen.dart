import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/controllers/account_controller.dart';
import '../services/auth_service.dart';

/// Màn hình Tài khoản
/// Hiển thị giao diện:
/// - Nếu đã đăng nhập: thông tin người dùng + các tùy chọn cài đặt + nút đăng xuất
/// - Nếu chưa đăng nhập: Tab Đăng nhập / Đăng ký với form tương ứng
class AccountScreen extends GetView<AccountController> {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy AuthService toàn cục để quản lý trạng thái đăng nhập
    final AuthService authService = Get.find<AuthService>();
    final theme = Theme.of(context);

    return Scaffold(
      // SafeArea tránh bị che bởi thanh trạng thái
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

  /// Giao diện khi người dùng đã đăng nhập
  Widget _buildLoggedInView(
    BuildContext context,
    AuthService authService,
    AccountController controller,
  ) {
    final theme = Theme.of(context);

    // Quan sát thông tin user để cập nhật UI ngay khi thay đổi
    return Obx(() {
      final user = authService.currentUser.value;

      if (user == null) {
        // Nếu user null (vừa logout), hiển thị loading
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        children: [
          // Phần thông tin người dùng: avatar + tên + email
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

          // Phần cài đặt chung
          Text(
            'Cài đặt chung',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Các tùy chọn ví dụ
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Chỉnh sửa hồ sơ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              Get.snackbar('Thông báo', 'Tính năng đang phát triển.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Giao diện (Theme)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              Get.snackbar('Thông báo', 'Tính năng đang phát triển.');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Thông báo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              Get.snackbar('Thông báo', 'Tính năng đang phát triển.');
            },
          ),

          const Divider(height: 30),

          // Nút đăng xuất
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

  /// Giao diện khi người dùng chưa đăng nhập
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
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
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

  /// Widget nút Tab tùy chỉnh
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

  /// Form Đăng nhập
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
        // Username
        TextField(
          controller: controller.loginUsernameController,
          decoration: InputDecoration(
            labelText: 'Tên đăng nhập',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.3,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        // Password
        Obx(
          () => TextField(
            controller: controller.loginPasswordController,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.3,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isLoginPasswordHidden.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
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

  /// Form Đăng ký
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
          decoration: InputDecoration(
            labelText: 'Tên đăng nhập',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.3,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Email
        TextField(
          controller: controller.registerEmailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.3,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        // Password
        Obx(
          () => TextField(
            controller: controller.registerPasswordController,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.3,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isRegisterPasswordHidden.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
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
}
