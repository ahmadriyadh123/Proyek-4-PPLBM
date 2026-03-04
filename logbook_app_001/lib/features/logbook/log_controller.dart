import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final String username;

  LogController(this.username);

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(title: title, description: desc, timestamp: DateTime.now().toString(), category: category);
    await MongoService().insertLog(newLog);
  }

  Future<void> updateLog(LogModel oldLog, String title, String desc, String category) async {
    final newLog = LogModel(id: oldLog.id, title: title, description: desc, timestamp: DateTime.now().toString(), category: category);
    await MongoService().updateLog(newLog);
  }

  Future<void> removeLog(LogModel logToRemove) async {
    if (logToRemove.id != null) {
      await MongoService().deleteLog(logToRemove.id!);
    }
  }

  Future<void> loadLogs() async {
    final List<LogModel> cloudLogs = await MongoService().getLogs();
    logsNotifier.value = cloudLogs;
    filteredLogs.value = cloudLogs;
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}
