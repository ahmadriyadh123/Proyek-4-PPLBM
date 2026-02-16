// login_controller.dart
class LoginController {
  // Database sederhana (Multiple Users)
  final Map<String, String> _users = {
    'admin': '123',
    'student': 'pass',
    'student1': 'password'
  };

  int _failedAttempts = 0;
  DateTime? _lockoutTime;

  // Fungsi pengecekan
  // Mengembalikan pesan error jika gagal, atau null jika berhasil
  String? login(String username, String password) {
    // 1. Validasi Input Kosong
    if (username.isEmpty || password.isEmpty) {
      return "Username dan Password tidak boleh kosong!";
    }

    // 2. Cek Lockout
    if (_lockoutTime != null) {
      final difference = DateTime.now().difference(_lockoutTime!);
      if (difference.inSeconds < 10) {
        return "Akun terkunci. Coba lagi dalam ${10 - difference.inSeconds} detik.";
      } else {
        // Reset lockout jika sudah lewat 10 detik
        _lockoutTime = null;
        _failedAttempts = 0;
      }
    }

    // 3. Cek Kredensial
    if (_users.containsKey(username) && _users[username] == password) {
      // Login Berhasil -> Reset percobaan gagal
      _failedAttempts = 0;
      return null;
    } else {
      // Login Gagal
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _lockoutTime = DateTime.now();
        return "Gagal 3 kali. Akun terkunci selama 10 detik.";
      }
      return "Username atau Password salah!";
    }
  }

  // Helper untuk mengecek status terkunci (untuk UI)
  bool get isLocked {
    if (_lockoutTime != null) {
      final difference = DateTime.now().difference(_lockoutTime!);
      return difference.inSeconds < 10;
    }
    return false;
  }
}
