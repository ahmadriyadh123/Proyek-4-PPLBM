import 'package:flutter/material.dart';
import '../auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  void _nextStep() {
    setState(() {
      step++;
    });

    if (step > 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  String _getStepContent(int step) {
    switch (step) {
      case 1:
        return "Selamat datang!";
      case 2:
        return "Hadir untuk membantu anda mencatat setiap progres.";
      case 3:
        return "Siap untuk memulai? Tekan tombol di bawah!";
      default:
        return "";
    }
  }

  String _getStepImage(int step) {
    switch (step) {
      case 1:
        return "assets/gambar_1.png";
      case 2:
        return "assets/gambar_2.png";
      case 3:
        return "assets/gambar_3.png";
      default:
        return "assets/gambar_1.png";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Step Indicator
              Text(
                "Step $step",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              // Image Asset
              Image.asset(
                _getStepImage(step),
                height: 250, // Perkecil skala agar muat di layar
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              
              // Dynamic Content
              Text(
                _getStepContent(step),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              
              const SizedBox(height: 50),
              
              // Navigation Button
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(step >= 3 ? "Mulai Sekarang" : "Lanjut"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
