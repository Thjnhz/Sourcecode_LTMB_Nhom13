import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Dùng kDebugMode kiểm tra debug
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

import '../models/user.dart';

/// Service quản lý xác thực người dùng (AuthService)
/// - Lưu JWT vào GetStorage
/// - Giữ state reactive cho currentUser và isAuthenticated
/// - Cung cấp các phương thức login, register, logout, fetchCurrentUser
class AuthService extends GetxService {
  /// URL API backend (tùy Android Emulator hoặc localhost)
  final String _baseUrl = GetPlatform.isAndroid
      ? "http://152.42.195.222:3000"
      : "http://localhost:3000";

  /// Key lưu token trong GetStorage
  final String _tokenKey = 'authToken';

  /// Instance GetStorage
  final _box = GetStorage();

  // --- Reactive state ---
  final Rxn<User> currentUser = Rxn<User>(); // User hiện tại
  final RxnString authToken = RxnString(); // JWT token
  final RxBool isAuthenticated = false.obs; // Trạng thái đã đăng nhập

  @override
  void onInit() {
    super.onInit();
    _loadAuthInfo(); // Tải token từ storage khi service khởi tạo
  }

  /// Load token từ storage và lấy thông tin user
  Future<void> _loadAuthInfo() async {
    final storedToken = _box.read<String>(_tokenKey);
    if (storedToken != null && storedToken.isNotEmpty) {
      authToken.value = storedToken;
      await fetchCurrentUser(); // Lấy user từ token
    } else {
      _clearAuthInfo(); // Xóa state nếu không có token
    }
    isAuthenticated.value = currentUser.value != null;
    if (kDebugMode) {
      print('AuthService initialized. Logged in: ${isAuthenticated.value}');
    }
  }

  /// Lưu token và thông tin user khi đăng nhập thành công
  void _saveAuthInfo(String token, User user) {
    authToken.value = token;
    currentUser.value = user;
    isAuthenticated.value = true;
    _box.write(_tokenKey, token); // Lưu token vào GetStorage
    if (kDebugMode) {
      print('Auth info saved. User: ${user.username}, Token: $token');
    }
  }

  /// Xóa token và thông tin user khi logout hoặc token hết hạn
  void _clearAuthInfo() {
    authToken.value = null;
    currentUser.value = null;
    isAuthenticated.value = false;
    _box.remove(_tokenKey);
    if (kDebugMode) {
      print('Auth info cleared.');
    }
  }

  // --- API calls ---

  /// Lấy thông tin user hiện tại từ API dựa trên token
  Future<void> fetchCurrentUser() async {
    if (authToken.value == null) {
      _clearAuthInfo();
      return;
    }
    final url = Uri.parse('$_baseUrl/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authToken.value}', // JWT trong header
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['result'] == 'ok' && jsonResponse['user'] != null) {
          currentUser.value = User.fromJson(jsonResponse['user']);
          isAuthenticated.value = true;
          if (kDebugMode) {
            print('Fetched current user: ${currentUser.value?.username}');
          }
          return;
        }
      }

      // Nếu token hết hạn hoặc lỗi server
      if (kDebugMode) {
        print(
          'Fetch current user failed (Status: ${response.statusCode}). Clearing auth info.',
        );
      }
      _clearAuthInfo();
    } catch (e) {
      if (kDebugMode) print('Error fetching current user: $e');
      _clearAuthInfo();
    }
  }

  /// Đăng nhập với username & password
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['result'] == 'ok') {
        final user = User.fromJson(jsonResponse['user']);
        final token = jsonResponse['token'] as String;
        _saveAuthInfo(token, user);
        return true;
      } else {
        _clearAuthInfo();
        Get.snackbar(
          'Đăng nhập thất bại',
          jsonResponse['message'] ?? 'Sai tên đăng nhập hoặc mật khẩu.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      _clearAuthInfo();
      Get.snackbar(
        'Lỗi',
        'Không thể kết nối đến máy chủ.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Đăng ký tài khoản mới
  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 201 && jsonResponse['result'] == 'ok') {
        Get.snackbar(
          'Thành công',
          jsonResponse['message'] ?? 'Đăng ký thành công! Vui lòng đăng nhập.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Đăng ký thất bại',
          jsonResponse['message'] ?? 'Có lỗi xảy ra.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể kết nối đến máy chủ.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Đăng xuất người dùng
  Future<void> logout() async {
    _clearAuthInfo(); // Xóa token, user, state
    Get.offAllNamed('/login'); // Reset navigation về màn hình login
    Get.snackbar(
      'Thông báo',
      'Bạn đã đăng xuất.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
