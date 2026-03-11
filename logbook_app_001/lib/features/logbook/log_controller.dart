import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_001/services/access_policy.dart';

class LogController {
  final Box<LogModel> _offlineLogsBox = Hive.box<LogModel>('offline_logs');
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final String username;
  final String teamId;
  final String role;

  LogController(this.username, this.teamId, this.role);

  Future<void> addLog(
    String title,
    String desc,
    String category,
    bool isPrivate,
  ) async {
    final newLog = LogModel(
      title: title,
      description: desc,
      timestamp: DateTime.now().toString(),
      category: category,
      teamId: teamId,
      authorId: username,
      isSynced: false, // Default to false until cloud push succeeds
      isPrivate: isPrivate,
    );

    await LogHelper.writeLog(
      "Mendaftarkan Catatan Baru: '${newLog.title}'",
      level: 3,
    );
    // Save locally first (Instant UI / Offline Support)
    await _offlineLogsBox.add(newLog);

    // Refresh ValueNotifier instan setelah mutasi storage Lokal
    var localLogs = _offlineLogsBox.values
        .where((log) => log.teamId == teamId)
        .toList();
    if (role != 'Ketua') {
      localLogs = localLogs.where((log) => log.authorId == username).toList();
    } else {
      localLogs = localLogs
          .where((log) => !log.isPrivate || log.authorId == username)
          .toList();
    }
    logsNotifier.value = localLogs;
    filteredLogs.value = localLogs;

    try {
      if (newLog.id != null) {
        // Assume ObjectId will be generated locally first time via toMap()
      }
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        "SINKRONISASI CLOUD BERHASIL: Catatan '${newLog.title}' tersimpan di MongoDB.",
        level: 2,
      );

      // Update local storage again to set isSynced = true
      final index = _offlineLogsBox.values.toList().indexWhere(
        (l) => l.timestamp == newLog.timestamp,
      );
      if (index != -1) {
        newLog.isSynced = true;
        await _offlineLogsBox.putAt(index, newLog);

        // Memastikan UI menggunakan objek yang sudah tersinkronisasi
        final updatedLocal = _offlineLogsBox.values
            .where((log) => log.teamId == teamId)
            .toList();
        if (role != 'Ketua') {
          logsNotifier.value = updatedLocal
              .where((log) => log.authorId == username)
              .toList();
        } else {
          logsNotifier.value = updatedLocal
              .where((log) => !log.isPrivate || log.authorId == username)
              .toList();
        }
        filteredLogs.value = logsNotifier.value;
      }
    } catch (e) {
      await LogHelper.writeLog(
        "SINKRONISASI CLOUD GAGAL (Add): Disimpan murni sebagai Offline Draft.",
        level: 1,
      );
    }
  }

  Future<void> updateLog(
    LogModel oldLog,
    String title,
    String desc,
    String category,
    bool isPrivate,
  ) async {
    await LogHelper.writeLog(
      "Mengubah Catatan Lama: '${oldLog.title}' -> '$title'",
      level: 3,
    );
    final newLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      timestamp: oldLog.timestamp, // Pertahankan timestamp asli
      category: category,
      teamId: oldLog.teamId, // Pertahankan team asli
      authorId: oldLog.authorId, // Pertahankan author asli
      isSynced: false,
      isPrivate: isPrivate,
    );

    // Save locally for instant UI response and resilient logging
    final index = _offlineLogsBox.values.toList().indexWhere(
      (l) => l.timestamp == oldLog.timestamp,
    );
    if (index != -1) {
      await _offlineLogsBox.putAt(index, newLog);
    }

    // Refresh ValueNotifier instan setelah mutasi storage Lokal
    var localLogs = _offlineLogsBox.values
        .where((log) => log.teamId == teamId)
        .toList();
    if (role != 'Ketua') {
      localLogs = localLogs.where((log) => log.authorId == username).toList();
    } else {
      localLogs = localLogs
          .where((log) => !log.isPrivate || log.authorId == username)
          .toList();
    }
    logsNotifier.value = localLogs;
    filteredLogs.value = localLogs;

    try {
      if (newLog.id != null) {
        await MongoService().updateLog(newLog);
        await LogHelper.writeLog(
          "SINKRONISASI CLOUD BERHASIL: Pemutakhiran '$title' tersimpan di MongoDB.",
          level: 2,
        );

        // Mark as synced if DB call succeeds
        newLog.isSynced = true;
        if (index != -1) {
          await _offlineLogsBox.putAt(index, newLog);

          final updatedLocal = _offlineLogsBox.values
              .where((log) => log.teamId == teamId)
              .toList();
          if (role != 'Ketua') {
            logsNotifier.value = updatedLocal
                .where((log) => log.authorId == username)
                .toList();
          } else {
            logsNotifier.value = updatedLocal
                .where((log) => !log.isPrivate || log.authorId == username)
                .toList();
          }
          filteredLogs.value = logsNotifier.value;
        }
      }
    } catch (e) {
      await LogHelper.writeLog(
        "Mongo Failed to Update. Changes saved locally.",
        level: 1,
      );
    }
  }

  Future<void> removeLog(LogModel logToRemove, String role) async {
    if (!AccessControlService.canPerform(
      role,
      AccessControlService.actionDelete,
      isOwner: logToRemove.authorId == username,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt",
        level: 1,
      );
      return;
    }

    // Hapus lokal dulu agar UI instant dan tangguh offline
    // TOMBSTONE: Jangan panggil deleteAt() langsung. Ubah flag agar bisa disinkronisasi nanti.
    final index = _offlineLogsBox.values.toList().indexWhere(
      (l) => l.id == logToRemove.id || l.timestamp == logToRemove.timestamp,
    );
    if (index != -1) {
      logToRemove.isDeleted = true;
      logToRemove.isSynced = false;
      await _offlineLogsBox.putAt(index, logToRemove);
    }

    // Refresh ValueNotifier instan setelah mutasi storage Lokal
    // Ambil SEMUA elemen KECUALI yang isDeleted == true
    var localLogs = _offlineLogsBox.values
        .where((log) => log.teamId == teamId && !log.isDeleted)
        .toList();
    if (role != 'Ketua') {
      localLogs = localLogs.where((log) => log.authorId == username).toList();
    } else {
      localLogs = localLogs
          .where((log) => !log.isPrivate || log.authorId == username)
          .toList();
    }

    // Perbarui UI secara sinkron dengan array BARU agar Flutter ValueNotifier bereaksi
    logsNotifier.value = [...localLogs];
    filteredLogs.value = [...localLogs];

    try {
      if (logToRemove.id != null) {
        await MongoService().deleteLog(logToRemove.id!);
        await LogHelper.writeLog(
          "SINKRONISASI CLOUD BERHASIL: Catatan terhapus dari MongoDB.",
          level: 2,
        );

        // Hapus pusaka permanen dari Hive jika Cloud sudah konfirmasi terhapus
        if (index != -1) {
          await _offlineLogsBox.deleteAt(index);
        }
      } else {
        // Jika ID Null, berarti catatannya dibuat offline lalu dihapus offline juga.
        // Hapus permanen tanpa membebani cloud.
        if (index != -1) await _offlineLogsBox.deleteAt(index);
      }
    } catch (e) {
      await LogHelper.writeLog(
        "SINKRONISASI CLOUD GAGAL (Delete Offline): Catatan ditandai dengan Batu Nisan (Tombstone).",
        level: 1,
      );
    }
  }

  Future<void> syncUnsyncedLogs() async {
    final unsyncedLogs = _offlineLogsBox.values
        .where((log) => log.teamId == teamId && !log.isSynced)
        .toList();
    if (unsyncedLogs.isEmpty) return;

    await LogHelper.writeLog(
      "Memulai sinkronisasi latar belakang untuk ${unsyncedLogs.length} catatan tertunda.",
      level: 2,
    );

    for (var i = 0; i < unsyncedLogs.length; i++) {
      var log = unsyncedLogs[i];
      try {
        // Asumsi sederhana kalau punya valid _id maka di update, kalau tidak ada id/draft, maka insert.
        if (log.isDeleted) {
          if (log.id != null) {
            await MongoService().deleteLog(log.id!);
            await LogHelper.writeLog(
              "=> Menghapus Batu Nisan Offline secara permanen dari Cloud: ${log.title}",
              level: 2,
            );
          }
          // Sukses hapus di cloud, hapus permanen di hive.
          final index = _offlineLogsBox.values.toList().indexWhere(
            (l) => l.timestamp == log.timestamp,
          );
          if (index != -1) await _offlineLogsBox.deleteAt(index);
          continue; // Lanjut ke antrian berikut
        }

        if (log.id == null) {
          await MongoService().insertLog(log);
          await LogHelper.writeLog(
            "=> Mendorong Draft Offline ke Cloud: ${log.title}",
            level: 2,
          );
        } else {
          final exists = await MongoService().getLogs(teamId, username, role);
          if (exists.any((c) => c.timestamp == log.timestamp)) {
            await MongoService().updateLog(log);
            await LogHelper.writeLog(
              "=> Memperbarui Draft Tertunda ke Cloud: ${log.title}",
              level: 2,
            );
          } else {
            await MongoService().insertLog(log);
            await LogHelper.writeLog(
              "=> Mendorong Draft Lama ke Cloud: ${log.title}",
              level: 2,
            );
          }
        }

        final index = _offlineLogsBox.values.toList().indexWhere(
          (l) => l.timestamp == log.timestamp,
        );
        if (index != -1) {
          log.isSynced = true;
          await _offlineLogsBox.putAt(index, log);
        }
      } catch (e) {
        await LogHelper.writeLog(
          "Gagal menyinkronkan cacatan tertunda: ${log.title}",
          level: 1,
        );
      }
    }
  }

  Future<void> loadLogs() async {
    // 0. SINKRONISASI PINTAR Latar Belakang
    await syncUnsyncedLogs();

    // 1. INSTANT UI: Load dari Hive memori lokal terlebih dahulu. Jangan tampilkan batu nisan.
    var localLogs = _offlineLogsBox.values
        .where((log) => log.teamId == teamId && !log.isDeleted)
        .toList();
    if (role != 'Ketua') {
      localLogs = localLogs.where((log) => log.authorId == username).toList();
    } else {
      localLogs = localLogs
          .where((log) => !log.isPrivate || log.authorId == username)
          .toList();
    }

    if (localLogs.isNotEmpty) {
      // Prioritaskan sinkronisasi UI lokal terlebih dulu karena asalkan tidak dihapus (isDeleted == false), harusnya valid.
      logsNotifier.value = localLogs;
      filteredLogs.value = localLogs;
    }

    // 2. SINKRONISASI: Coba ambil dari Cloud. Jika berhasil, timpa data Hive (Resilient Logger)
    try {
      await LogHelper.writeLog(
        "Mencoba menarik daftar data terbaru dari MongoDB Cloud...",
        level: 3,
      );
      final List<LogModel> cloudLogs = await MongoService().getLogs(
        teamId,
        username,
        role,
      );
      await LogHelper.writeLog(
        "TARIKAN CLOUD BERHASIL: Ditemukan ${cloudLogs.length} catatan total untuk tim $teamId. (Role: $role)",
        level: 2,
      );

      // Ambil yang masih pending (baik edit/tambah/hapus) agar statenya tidak ditimpa
      var pendingLogs = _offlineLogsBox.values
          .where((log) => !log.isSynced && log.teamId == teamId)
          .toList();

      // Filter pendingLogs sesuai role dan buang yang batu nisan.
      if (role != 'Ketua') {
        pendingLogs = pendingLogs
            .where((log) => log.authorId == username && !log.isDeleted)
            .toList();
      } else {
        pendingLogs = pendingLogs
            .where(
              (log) =>
                  (!log.isPrivate || log.authorId == username) &&
                  !log.isDeleted,
            )
            .toList();
      }

      // Pastikan data awan tidak menampilkan record yang sedang menunggu untuk dihapus offline
      final List<LogModel> filteredCloudLogs = cloudLogs.where((cloud) {
        final correspondingPending = _offlineLogsBox.values.where(
          (pLog) => pLog.id == cloud.id && pLog.isDeleted,
        );
        return correspondingPending
            .isEmpty; // Tampilkan hanya bila id awan tidak disandi nisan lokal
      }).toList();

      // Gabungkan cloudLogs bersih dan pendingLogs hidup
      final combinedLogs = [...filteredCloudLogs, ...pendingLogs];

      // Update UI dengan data gabungan
      logsNotifier.value = combinedLogs;
      filteredLogs.value = combinedLogs;

      // Update penyimpanan lokal dengan state terbaru dari Cloud yang 100% tersinkron
      for (var log in cloudLogs) {
        log.isSynced = true;
      }

      // Ambil semua pending bawaan (termasuk tim lain jika ada) untuk di pass ke Hive
      final allPending = _offlineLogsBox.values
          .where((log) => !log.isSynced)
          .toList();

      await _offlineLogsBox.clear();
      await _offlineLogsBox.addAll(cloudLogs);
      await _offlineLogsBox.addAll(allPending);
    } catch (e) {
      // Gagal ambil Cloud (Offline), tetap gunakan `localLogs`
      await LogHelper.writeLog(
        "Memuat log lokal menggunakan Hive sebagai Fallback. Tidak ada koneksi.",
        level: 3,
      );

      // Pastikan UI dipaksa untuk menampilkan set data lokal yang bebas batu nisan
      if (localLogs.isNotEmpty) {
        logsNotifier.value = [...localLogs];
        filteredLogs.value = [...localLogs];
      } else {
        logsNotifier.value = [];
        filteredLogs.value = [];
      }
    }
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(query.toLowerCase()) ||
                log.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }
}
