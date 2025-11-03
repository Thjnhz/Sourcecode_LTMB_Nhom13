import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/manga.dart';
import '../models/chapter.dart';
import '../models/library_manga.dart';
import '../models/history_manga.dart';
import 'auth_service.dart';

/// Service quản lý dữ liệu manga
/// - Lấy danh sách manga, chi tiết manga, chapters, pages
/// - Quản lý thư viện và lịch sử đọc
/// - Thực hiện tìm kiếm với query và tags
/// - Dùng JWT từ AuthService để xác thực
class MangaService extends GetxService {
  /// Base URL backend cục bộ
  final String _localBaseUrl = GetPlatform.isAndroid
      ? "http://152.42.195.222:3000"
      : "http://localhost:3000";

  /// Base URL để lấy cover từ Mangadex
  final String _mangadexCoverBaseUrl = "https://uploads.mangadex.org/covers";

  /// Giới hạn số manga trả về cho một lần fetch
  static const int mangaLimit = 21;

  /// Lấy AuthService để gửi token
  AuthService get _authService => Get.find<AuthService>();

  /// Cache URL từng trang của chapter
  final Map<String, List<String>> _chapterPageCache = {};

  // -----------------------------
  // PRIVATE UTILS
  // -----------------------------

  /// Tạo header chứa JWT nếu đã đăng nhập
  Map<String, String> _getAuthHeaders() {
    final token = _authService.authToken.value;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Chuyển dữ liệu JSON từ API thành object Manga
  Manga _mapMangaData(Map<String, dynamic> data) {
    final mangaId = data['id'] ?? 'unknown-id';
    final coverFilename = data['cover_filename'] ?? '';
    final coverUrl = (mangaId != 'unknown-id' && coverFilename.isNotEmpty)
        ? "$_mangadexCoverBaseUrl/$mangaId/$coverFilename.256.jpg"
        : "https://placehold.co/256x362/png?text=No+Cover";

    List<String> tags = [];
    if (data['tags'] is List) {
      // Ép kiểu từng phần tử sang String
      tags = (data['tags'] as List).map((e) => e.toString()).toList();
    }

    return Manga(
      id: mangaId,
      title: data['title'] ?? 'No Title',
      coverUrl: coverUrl,
      description: data['description'],
      status: data['status'],
      tags: tags,
    );
  }

  /// Build URL cover fallback
  String buildCoverUrl(String mangaId, String coverFilename) {
    if (mangaId.isEmpty || coverFilename.isEmpty) {
      return "https://placehold.co/256x362/png?text=No+Cover";
    }
    return "$_mangadexCoverBaseUrl/$mangaId/$coverFilename.256.jpg";
  }

  /// Xóa toàn bộ cache chapter pages
  void clearCache() {
    _chapterPageCache.clear();
  }
  // -----------------------------
  // TAGS
  // -----------------------------

  /// Lấy danh sách tất cả tag từ backend
  Future<List<String>> getAllTags() async {
    final url = Uri.parse('$_localBaseUrl/tags'); // endpoint trả về tags
    try {
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch tags: ${response.statusCode}');
      }

      final body = json.decode(response.body);
      if (body['result'] == 'ok' && body['data'] is List) {
        // Ép kiểu từng phần tử sang String
        return (body['data'] as List).map((e) => e.toString()).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) print('Error fetching tags: $e');
      throw Exception('Error fetching tags: $e');
    }
  }
  // -----------------------------
  // MANGA LISTING
  // -----------------------------

  /// Lấy danh sách manga mới nhất với offset
  Future<List<Manga>> getLatestManga({int offset = 0}) async {
    final url = Uri.parse(
      '$_localBaseUrl/manga?limit=$mangaLimit&offset=$offset',
    );
    try {
      final response = await http.get(url, headers: _getAuthHeaders());
      if (response.statusCode != 200) {
        throw Exception('Failed to load manga: ${response.statusCode}');
      }
      final body = json.decode(response.body);
      if (body['result'] == 'ok' && body['data'] is List) {
        return (body['data'] as List).map((e) => _mapMangaData(e)).toList();
      }
      throw Exception('Invalid data format from /manga');
    } catch (e) {
      throw Exception('Error fetching latest manga: $e');
    }
  }

  /// Lấy danh sách manga "hot"
  Future<List<Manga>> getHotManga() async {
    final url = Uri.parse('$_localBaseUrl/manga/hot');
    try {
      final response = await http.get(url, headers: _getAuthHeaders());
      if (response.statusCode != 200) {
        throw Exception('Failed to load hot manga: ${response.statusCode}');
      }
      final body = json.decode(response.body);
      if (body['result'] == 'ok' && body['data'] is List) {
        return (body['data'] as List).map((e) => _mapMangaData(e)).toList();
      }
      throw Exception('Invalid data format from /manga/hot');
    } catch (e) {
      throw Exception('Error fetching hot manga: $e');
    }
  }

  // -----------------------------
  // MANGA DETAILS
  // -----------------------------

  /// Lấy chi tiết manga theo mangaId
  Future<Manga> getMangaDetails(String mangaId) async {
    final url = Uri.parse('$_localBaseUrl/manga/$mangaId');
    try {
      final response = await http.get(url, headers: _getAuthHeaders());
      if (response.statusCode != 200) {
        throw Exception('Failed to load manga details: ${response.statusCode}');
      }
      final body = json.decode(response.body);
      if (body['result'] == 'ok' && body['data'] is Map) {
        return _mapMangaData(body['data']);
      }
      throw Exception('Invalid data format from /manga/$mangaId');
    } catch (e) {
      throw Exception('Error fetching manga details: $e');
    }
  }

  // -----------------------------
  // CHAPTERS & PAGES
  // -----------------------------

  /// Lấy danh sách chapter của manga
  Future<List<Chapter>> getChapters(String mangaId) async {
    final url = Uri.parse('$_localBaseUrl/manga/$mangaId/chapters');
    try {
      final response = await http.get(url, headers: _getAuthHeaders());
      if (response.statusCode != 200) {
        throw Exception('Failed to load chapters: ${response.statusCode}');
      }
      final body = json.decode(response.body);
      if (body['result'] == 'ok' && body['data'] is List) {
        return (body['data'] as List).map((e) => Chapter.fromJson(e)).toList();
      }
      throw Exception('Invalid data format from /chapters');
    } catch (e) {
      throw Exception('Error fetching chapters: $e');
    }
  }

  /// Lấy URL các trang của chapter (có cache & retry)
  Future<List<String>> getChapterPages(
    String chapterId, {
    int retryCount = 0,
  }) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 3);

    if (_chapterPageCache.containsKey(chapterId)) {
      return _chapterPageCache[chapterId]!;
    }

    final url = Uri.parse('$_localBaseUrl/chapters/$chapterId/pages');
    try {
      if (kDebugMode) print('Fetching pages for $chapterId');
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['result'] == 'ok' && jsonResponse['data'] is List) {
          final urls = List<String>.from(jsonResponse['data']);
          _chapterPageCache[chapterId] = urls;
          return urls;
        }
        throw Exception('Invalid data format from pages API');
      } else if (response.statusCode >= 500 && retryCount < maxRetries) {
        await Future.delayed(retryDelay);
        return getChapterPages(chapterId, retryCount: retryCount + 1);
      }
      throw Exception('Failed to get chapter pages (${response.statusCode})');
    } catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(retryDelay);
        return getChapterPages(chapterId, retryCount: retryCount + 1);
      }
      throw Exception('Error fetching chapter pages: $e');
    }
  }

  /// Xóa cache của chapter cụ thể
  void clearChapterCache(String chapterId) {
    _chapterPageCache.remove(chapterId);
  }

  // -----------------------------
  // READING HISTORY
  // -----------------------------

  /// Cập nhật lịch sử đọc chapter
  Future<void> updateReadingHistory(String chapterId) async {
    if (!_authService.isAuthenticated.isTrue) {
      if (kDebugMode) print('User not logged in, skip history update');
      return;
    }
    final url = Uri.parse('$_localBaseUrl/history/read');
    try {
      await http.post(
        url,
        headers: _getAuthHeaders(),
        body: json.encode({'chapterId': chapterId}),
      );
    } catch (e) {
      if (kDebugMode) print('Error updating history: $e');
    }
  }

  // -----------------------------
  // LIBRARY MANAGEMENT
  // -----------------------------

  Future<List<LibraryManga>> getLibrary() async {
    if (!_authService.isAuthenticated.isTrue) return [];
    final url = Uri.parse('$_localBaseUrl/library');
    try {
      final response = await http.get(url, headers: _getAuthHeaders());
      if (response.statusCode == 401 || response.statusCode == 403) {
        _authService.logout();
        return [];
      }
      if (response.statusCode != 200) {
        throw Exception('Failed to load library: ${response.statusCode}');
      }
      final body = json.decode(response.body);
      if (body['result'] == 'ok' && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => LibraryManga.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching library: $e');
    }
  }

  Future<void> addToLibrary(String mangaId, String status) async {
    final url = Uri.parse('$_localBaseUrl/library/add');
    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: json.encode({'mangaId': mangaId, 'status': status}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to add to library: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding to library: $e');
    }
  }

  Future<void> removeFromLibrary(String mangaId) async {
    final url = Uri.parse('$_localBaseUrl/library/remove');
    try {
      final response = await http.post(
        url,
        headers: _getAuthHeaders(),
        body: json.encode({'mangaId': mangaId}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to remove from library: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error removing from library: $e');
    }
  }

  // -----------------------------
  // READING HISTORY LIST
  // -----------------------------

  Future<List<HistoryManga>> getReadingHistory() async {
    if (!_authService.isAuthenticated.isTrue) return [];
    final url = Uri.parse('$_localBaseUrl/history');
    try {
      final response = await http.get(url, headers: _getAuthHeaders());
      if (response.statusCode != 200) {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
      final body = json.decode(response.body);
      if (body['result'] == 'ok' && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => HistoryManga.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  // -----------------------------
  // SEARCH MANGA
  // -----------------------------

  /// Tìm kiếm manga theo tên, tag và mode
  Future<List<Manga>> searchManga({
    String query = '',
    List<String> tags = const [],
    String mode = 'and', // 'and' hoặc 'or'
  }) async {
    if (query.isEmpty && tags.isEmpty) return [];

    final Map<String, String> queryParams = {
      'limit': '30',
      'offset': '0',
      'mode': mode,
    };
    if (query.isNotEmpty) queryParams['q'] = query;
    if (tags.isNotEmpty) queryParams['tags'] = tags.join(',');

    final url = Uri.parse(
      '$_localBaseUrl/search',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url, headers: _getAuthHeaders());
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['result'] == 'ok' && jsonResponse['data'] is List) {
          return (jsonResponse['data'] as List)
              .map((e) => _mapMangaData(e))
              .toList();
        }
        throw Exception('Invalid data format from /search');
      }
      throw Exception('Failed to search manga (Code: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error searching manga: $e');
    }
  }
}
