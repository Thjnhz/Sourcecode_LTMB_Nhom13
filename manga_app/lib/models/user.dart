/// Represents basic user information.
class User {
  final dynamic id; // ID có thể là int hoặc String tùy backend
  final String username;
  final String? email; // Email có thể null

  User({required this.id, required this.username, this.email});

  // Factory constructor để tạo User từ JSON (nhận từ API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'], // Lấy trực tiếp
      username: json['username'] ?? 'Unknown User', // Cung cấp giá trị mặc định
      email: json['email'], // Có thể null
    );
  }
}
