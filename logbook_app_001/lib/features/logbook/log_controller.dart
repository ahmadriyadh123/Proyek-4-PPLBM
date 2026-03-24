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

  bool _isSyncing = false; // Mencegah 2 kali push yang membuat data ganda

  void _refreshUINotifiers() {
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
    
    // Sort descending
    localLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    logsNotifier.value = List.from(localLogs);
    filteredLogs.value = List.from(localLogs);
  }

  int _findLogIndex(LogModel target) {
    return _offlineLogsBox.values.toList().indexWhere(
      (l) => l.timestamp == target.timestamp,
    );
  }

  Future<void> addLog(
    String title,
    String desc,
    String category,
    bool isPrivate,
  ) async {
    debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Menambahkan data baru (lokal/offline). Akun: $username, Judul: $title');
    final newLog = LogModel(
      title: title,
      description: desc,
      timestamp: DateTime.now().toString(),
      category: category,
      teamId: teamId,
      authorId: username,
      isSynced: false, // Ditandai belum sinkron agar diurus oleh worker latar belakang
      isPrivate: isPrivate,
    );

    await LogHelper.writeLog(
      "AKSI PENGGUNA: Membuat catatan baru.\n"
      " -> Judul: '$title'\n"
      " -> Privasi: ${isPrivate ? 'Privat' : 'Publik'}\n"
      " -> Kategori: '$category'",
      level: 2,
    );
    
    await _offlineLogsBox.add(newLog);
    _refreshUINotifiers();
    syncUnsyncedLogs(); // Fire and forget
  }

  Future<void> updateLog(
    LogModel oldLog,
    String title,
    String desc,
    String category,
    bool isPrivate,
  ) async {
    debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Memperbarui data (lokal/offline). Akun: $username, Judul: $title');
    await LogHelper.writeLog(
      "AKSI PENGGUNA: Memperbarui Catatan (ID Asli: ${oldLog.id?.toHexString() ?? 'Offline Draft'}).\n"
      " -> Judul: '${oldLog.title}' diubah menjadi '$title'\n"
      " -> Kategori: '${oldLog.category}' diubah menjadi '$category'\n"
      " -> Privasi: ${oldLog.isPrivate ? 'Privat' : 'Publik'} diubah menjadi ${isPrivate ? 'Privat' : 'Publik'}",
      level: 2,
    );
    
    final newLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      timestamp: oldLog.timestamp, // Sangat penting: jangan diubah
      category: category,
      teamId: oldLog.teamId,
      authorId: oldLog.authorId,
      isSynced: false,
      isPrivate: isPrivate,
    );

    final index = _findLogIndex(oldLog);
    if (index != -1) {
      await _offlineLogsBox.putAt(index, newLog);
      _refreshUINotifiers();
      syncUnsyncedLogs(); // Fire and forget
    }
  }

  Future<void> removeLog(LogModel logToRemove, String role) async {
    debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Menghapus data (lokal/offline). Akun: $username, Judul: ${logToRemove.title}');
    if (!AccessControlService.canPerform(
      role,
      AccessControlService.actionDelete,
      isOwner: logToRemove.authorId == username,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt pada '${logToRemove.title}'",
        level: 1,
      );
      return;
    }

    await LogHelper.writeLog(
      "AKSI PENGGUNA: Menghapus catatan berjudul '${logToRemove.title}' (ID: ${logToRemove.id?.toHexString() ?? 'Offline Draft'})",
      level: 2,
    );

    final index = _findLogIndex(logToRemove);
    if (index != -1) {
      logToRemove.isDeleted = true;
      logToRemove.isSynced = false;
      await _offlineLogsBox.putAt(index, logToRemove);
      _refreshUINotifiers();
      syncUnsyncedLogs(); // Fire and forget
    }
  }

  Future<void> syncUnsyncedLogs() async {
    if (_isSyncing) return;
    _isSyncing = true;
    bool uiNeedsRefresh = false;

    debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Memulai proses sinkronisasi (cek status jaringan & data)...');

    try {
      final unsyncedLogs = _offlineLogsBox.values
          .where((log) => log.teamId == teamId && !log.isSynced)
          .toList();
      
      if (unsyncedLogs.isEmpty) {
        debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Tidak ada data tertunda untuk disinkronkan.');
        return;
      }

      debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Menemukan ${unsyncedLogs.length} data tertunda untuk disinkronkan. Mencoba koneksi ke cloud...');

      await LogHelper.writeLog(
        "Memulai sinkronisasi latar belakang untuk ${unsyncedLogs.length} catatan tertunda.",
        level: 2,
      );

      for (var i = 0; i < unsyncedLogs.length; i++) {
        var log = unsyncedLogs[i];
        try {
          if (log.isDeleted) {
            if (log.id != null) {
              debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Sinkronisasi: Menghapus data di cloud. Akun: ${log.authorId}, Judul: ${log.title}');
              await MongoService().deleteLog(log.id!);
              await LogHelper.writeLog(
                "=> Menghapus Batu Nisan Offline secara permanen dari Cloud: ${log.title}",
                level: 2,
              );
            }
            final index = _findLogIndex(log);
            if (index != -1) await _offlineLogsBox.deleteAt(index);
            uiNeedsRefresh = true;
            continue; 
          }

          if (log.id == null) {
            debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Sinkronisasi: Mendorong data baru ke cloud (dibuat offline). Akun: ${log.authorId}, Judul: ${log.title}');
            final insertedId = await MongoService().insertLog(log);
            log = LogModel(
              id: insertedId,
              title: log.title,
              description: log.description,
              timestamp: log.timestamp,
              category: log.category,
              teamId: log.teamId,
              authorId: log.authorId,
              isSynced: true,
              isPrivate: log.isPrivate,
              isDeleted: log.isDeleted,
            );
            await LogHelper.writeLog(
              "=> Mendorong Draft Offline ke Cloud: ${log.title}",
              level: 2,
            );
          } else {
            // Catatan lama yang di-edit saat Luring
            debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Sinkronisasi: Memperbarui data ke cloud (diedit offline). Akun: ${log.authorId}, Judul: ${log.title}');
            await MongoService().updateLog(log);
            log.isSynced = true;
            await LogHelper.writeLog(
              "=> Memperbarui Draft Tertunda ke Cloud: ${log.title}",
              level: 2,
            );
          }

          final index = _findLogIndex(log);
          if (index != -1) {
            await _offlineLogsBox.putAt(index, log);
            uiNeedsRefresh = true;
          }
        } catch (e, stacktrace) {
          debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Koneksi offline atau error saat sinkronisasi data "${log.title}": $e');
          await LogHelper.writeLog(
            "Gagal menyinkronkan cacatan tertunda: ${log.title}\nError: $e\n$stacktrace",
            level: 1,
          );
        }
      }
    } finally {
      _isSyncing = false;
      if (uiNeedsRefresh) {
        _refreshUINotifiers();
      }
    }
  }

  Future<void> loadLogs() async {
    await LogHelper.writeLog(
      "AKSI PENGGUNA: Membuka laman log & Meminta proses muat awal (Read).",
      level: 2,
    );
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
      debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Memeriksa koneksi jaringan. Mengambil data dari Cloud...');
      await LogHelper.writeLog(
        "Mencoba menarik daftar data terbaru dari MongoDB Cloud...",
        level: 3,
      );
      final List<LogModel> cloudLogs = await MongoService().getLogs(
        teamId,
        username,
        role,
      );
      debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Terhubung ke jaringan. Berhasil mengambil ${cloudLogs.length} data dari Cloud.');
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

      // Gabungkan cloud + pending dengan deduplikasi MURNI berdasarkan timestamp.
      final merged = <String, LogModel>{};
      for (final log in filteredCloudLogs) {
        merged[log.timestamp] = log;
      }
      // Agar catatan offline yang baru menetas mendapat suntikan _id dari Cloud, 
      // namun kita tetap mempertahankan isi versi lokalnya (yang mungkin baru diedit Offline)
      for (var log in pendingLogs) {
        final existingCloudLog = merged[log.timestamp];
        if (existingCloudLog != null && log.id == null) {
          // Jadikan 'update' bukannya 'insert' pada siklus sync worker selanjutnya
          log = LogModel(
            id: existingCloudLog.id, // Mewarisi ID
            title: log.title,
            description: log.description,
            timestamp: log.timestamp,
            category: log.category,
            teamId: log.teamId,
            authorId: log.authorId,
            isSynced: log.isSynced,
            isPrivate: log.isPrivate,
            isDeleted: log.isDeleted,
          );
          final hiveIndex = _findLogIndex(log);
          if (hiveIndex != -1) await _offlineLogsBox.putAt(hiveIndex, log);
        }
        merged[log.timestamp] = log;
      }
      
      final combinedLogs = merged.values.toList();

      // Update UI dengan data gabungan
      logsNotifier.value = combinedLogs;
      filteredLogs.value = combinedLogs;

      // Update penyimpanan lokal dengan state terbaru dari Cloud yang 100% tersinkron
      for (var log in cloudLogs) {
        log.isSynced = true;
      }

      // Upsert cloud ke Hive tanpa clear() agar tombstone lokal tidak hilang.
      for (final cloudLog in cloudLogs) {
        final index = _offlineLogsBox.values.toList().indexWhere(
          (local) =>
              (cloudLog.id != null &&
                  local.id != null &&
                  local.id == cloudLog.id) ||
              local.timestamp == cloudLog.timestamp,
        );

        if (index == -1) {
          await _offlineLogsBox.add(cloudLog);
          continue;
        }

        final local = _offlineLogsBox.getAt(index);
        if (local != null && local.isDeleted && !local.isSynced) {
          // Pertahankan tombstone lokal yang belum tersinkron.
          continue;
        }

        await _offlineLogsBox.putAt(index, cloudLog);
      }
    } catch (e, stacktrace) {
      debugPrint('[${DateTime.now().toIso8601String()}] [LogController] Offline atau jaringan terputus. Gagal mengambil data: $e. Memakai mode offline.');
      // Gagal ambil Cloud (Offline), tetap gunakan `localLogs`
      await LogHelper.writeLog(
        "Memuat log lokal menggunakan Hive sebagai Fallback. Tidak ada koneksi: $e\n$stacktrace",
        level: 3,
      );

      // Pastikan UI dipaksa untuk menampilkan set data lokal yang bebas batu nisan
      if (localLogs.isNotEmpty) {
        logsNotifier.value = List.from(localLogs);
        filteredLogs.value = List.from(localLogs);
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
