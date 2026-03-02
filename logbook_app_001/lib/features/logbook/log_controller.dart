import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final String username;
  String get _storageKey => 'user_logs_data_$username';

  LogController(this.username) { loadLogs(); }

  void addLog(String title, String desc, String category) {
    final newLog = LogModel(title: title, description: desc, timestamp: DateTime.now().toString(), category: category);
    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value;
    saveToDisk();
  }

  void updateLog(int index, String title, String desc, String category) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = LogModel(title: title, description: desc, timestamp: DateTime.now().toString(), category: category);
    logsNotifier.value = currentLogs;
    filteredLogs.value = currentLogs;
    saveToDisk();
  }

  void removeLog(int index) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    filteredLogs.value = currentLogs;
    saveToDisk();
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(logsNotifier.value.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    String? rawJson = prefs.getString(_storageKey); // Menggunakan _storageKey untuk multi-user
    
    if (rawJson != null) {
      // 1. Decode String ke List<Map>
      Iterable decoded = jsonDecode(rawJson);
      
      // 2. Map kembali ke List<LogModel>
      logsNotifier.value = decoded.map((item) => LogModel.fromMap(item)).toList();
      filteredLogs.value = logsNotifier.value;
    }
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
