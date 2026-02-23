// login_view.dart
import 'package:flutter/material.dart';
// Import Controller milik sendiri (masih satu folder)
import 'package:logbook_app_001/features/auth/login_controller.dart';
// Import View dari fitur lain (Logbook) untuk navigasi
import 'package:logbook_app_001/features/logbook/counter_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  // State untuk visibilitas password
  bool _isObscure = true;

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    // Panggil logika login dari controller
    AuthResult result = _controller.login(user, pass);

    if (result.status == LoginStatus.success) {
      // Login Berhasil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Di sini kita kirimkan variabel 'user' ke parameter 'username' di CounterView
          builder: (context) => CounterView(username: user),
        ),
      );
    } else {
      // Login Gagal -> Tentukan warna dan pesan
      Color snackColor = Colors.red;
      IconData icon = Icons.error_outline;

      if (result.status == LoginStatus.emptyInput) {
        snackColor = Colors.orange; // Warna peringatan
        icon = Icons.warning_amber_rounded;
      } 
      
      // Sembunyikan snackbar sebelumnya jika ada, agar yang baru langsung muncul
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(result.message ?? "Terjadi kesalahan")),
            ],
          ),
          backgroundColor: snackColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Update UI jika terkunci agar tombol bisa disabled (opsional, perlu setState)
      setState(() {}); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: "Username",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passController,
              obscureText: _isObscure, // Gunakan state _isObscure
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              // Disable tombol jika akun terkunci
              onPressed: _controller.isLocked ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Tombol lebar penuh
              ),
              child: Text(_controller.isLocked ? "Terkunci (Tunggu...)" : "Masuk"),
            ),
          ],
        ),
      ),
    );
  }
}
