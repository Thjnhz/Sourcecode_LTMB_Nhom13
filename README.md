# Ứng Dụng Đọc Manga

Ứng dụng Flutter hiện đại để đọc và quản lý bộ sưu tập manga

## Tính Năng

- 📚 Duyệt và tìm kiếm bộ sưu tập manga
- 📖 Đọc các chương manga với trải nghiệm mượt mà
- 🔖 Theo dõi lịch sử đọc và đánh dấu
- 📱 Hỗ trợ đa nền tảng (iOS, Android, Web, Desktop)
- 🌙 Quản lý thư viện manga yêu thích
- 💬 Chức năng trò chuyện cho cộng đồng
- 🔐 Xác thực người dùng và quản lý hồ sơ

## Công Nghệ Sử Dụng

- **Frontend:** Flutter
- **Backend:** Node.js
- **Cơ sở dữ liệu:** SQL
- **Xác thực:** Firebase
- **Quản lý State:** GetX

## Bắt Đầu

### Yêu Cầu Hệ Thống

- Flutter SDK (phiên bản mới nhất)
- Node.js
- MySQL/PostgreSQL
- Tài khoản Firebase và cấu hình

### Cài Đặt

1. Clone repository:
```bash
git clone https://github.com/Thjnhz/Sourcecode_LTMB_Nhom13.git
```

2. Cài đặt các dependencies Flutter:
```bash
flutter pub get
```

3. Thiết lập Firebase:
   - Thêm file `google-services.json` vào thư mục `android/app/`
   - Thêm cấu hình Firebase vào `ios/Runner/`
   - Cấu hình file `lib/firebase_options.dart`

4. Thiết lập máy chủ backend:
```bash
cd manga_server
npm install
```

5. Cấu hình cơ sở dữ liệu:
   - Import schema từ file `SQL/Manga-APP.sql`
   - Cập nhật cài đặt kết nối database trong cấu hình máy chủ

### Chạy Ứng Dụng

- Chạy ứng dụng Flutter:
```bash
flutter run
```

- Khởi động máy chủ backend:
```bash
cd manga_server
npm start
```

## Cấu Trúc Dự Án

```
lib/
├── app/          # Cấu hình và bindings
├── models/       # Các model dữ liệu
├── screens/      # Các màn hình UI
├── services/     # Logic nghiệp vụ và API services
└── widgets/      # Các component UI có thể tái sử dụng
```

## Chi Tiết Tính Năng

- **Màn Hình Chính (`lib/screens/home_screen.dart`):**
  - Duyệt manga thịnh hành và mới nhất
  - Banner manga nổi bật
  - Truy cập nhanh để tiếp tục đọc

- **Thư Viện (`lib/screens/library_screen.dart`):**
  - Quản lý manga yêu thích
  - Theo dõi tiến độ đọc
  - Lịch sử đọc

- **Trình Đọc (`lib/screens/reader_screen.dart`):**
  - Điều hướng chương mượt mà
  - Nhiều chế độ đọc
  - Đồng bộ hóa tiến độ

- **Tìm Kiếm (`lib/screens/search_screen.dart`):**
  - Tìm kiếm manga nâng cao
  - Bộ lọc và danh mục

## Lời Cảm Ơn

- Cảm ơn tất cả những người đóng góp
- Các nhà cung cấp dữ liệu mangadex
- Cộng đồng Flutter và Firebase
