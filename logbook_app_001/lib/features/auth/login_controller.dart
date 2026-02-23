// login_controller.dart
enum LoginStatus { success, emptyInput, invalidCredentials, locked }

class AuthResult {
  final LoginStatus status;
  final String? message;

  AuthResult({required this.status, this.message});
}

class LoginController {
  // Database sederhana (Multiple Users)
  final Map<String, String> _users = {
    'admin1': '123',
    'admin2': 'pass',
    'admin3': 'password'
  };

  int _failedAttempts = 0;
  DateTime? _lockoutTime;

  // Fungsi pengecekan
  // Mengembalikan AuthResult
  AuthResult login(String username, String password) {
    // 1. Validasi Input Kosong
    if (username.isEmpty || password.isEmpty) {
      return AuthResult(
        status: LoginStatus.emptyInput,
        message: "Username dan Password tidak boleh kosong!",
      );
    }

    // 2. Cek Lockout
    if (_lockoutTime != null) {
      final difference = DateTime.now().difference(_lockoutTime!);
      if (difference.inSeconds < 10) {
        return AuthResult(
          status: LoginStatus.locked,
          message: "Akun terkunci. Coba lagi dalam ${10 - difference.inSeconds} detik.",
        );
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
      return AuthResult(status: LoginStatus.success);
    } else {
      // Login Gagal
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _lockoutTime = DateTime.now();
        return AuthResult(
          status: LoginStatus.locked,
          message: "Gagal 3 kali. Akun terkunci selama 10 detik.",
        );
      }
      return AuthResult(
        status: LoginStatus.invalidCredentials,
        message: "Username atau Password salah!",
      );
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
