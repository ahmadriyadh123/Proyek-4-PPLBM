import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown", // Menandakan file/proses asal
    int level = 2,
  }) async {
    // 1. Filter Konfigurasi (ENV)
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (muteList.split(',').contains(source)) return;

    try {
      // 2. Format Waktu untuk Konsol
      String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      String label = _getLabel(level);
      String color = _getColor(level);

      // 3. Output Debug Console (Non-blocking)
      dev.log(message, name: source, time: DateTime.now(), level: level * 100);

      // Format: [14:30:05] [INFO] [log_view.dart] -> Database Terhubung
      // Menggunakan print() murni kita sendiri karena debugPrint bawaan flutter sudah dimatikan
      // ignore: avoid_print
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      // 5. Tulis ke File Fisik (Audit Trail)
      if (!kIsWeb) { 
        _writeToFile('[$timestamp][$label][$source] -> $message');
      }
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static Future<void> _writeToFile(String logLine) async {
    try {
      final String dateString = DateFormat('dd-MM-yyyy').format(DateTime.now());
      Directory logDir;

      // 1. CEK PLATFORM: Hibrida agar bisa jalan di Windows DAN HP
      if (Platform.isAndroid || Platform.isIOS) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        logDir = Directory('${appDocDir.path}/logs');
      } else {
        // Ekspektasi default untuk Desktop/Windows (sejajar dengan pubspec.yaml)
        logDir = Directory('logs'); 
      }
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final File logFile = File('${logDir.path}/$dateString.log');
      await logFile.writeAsString('$logLine\n', mode: FileMode.append);

      if (await logFile.length() < 100) {
        dev.log("INFO: File Log TERSIMPAN di: ${logFile.path}", name: "SYSTEM");
      }
    } catch (e) {
      dev.log("Gagal menulis ke file log fisik: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}
