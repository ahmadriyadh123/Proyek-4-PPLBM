import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'log_model.g.dart'; //Generated file untuk Hive Adapter

@HiveType(typeId: 0) //ID unik untuk setiap model Hive
class LogModel {
  @HiveField(0)
  final ObjectId? id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String timestamp;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String category;
  @HiveField(5)
  final String authorId;
  @HiveField(6)
  final String teamId; // Contoh : "MEKTRA_KLP_01"
  @HiveField(7, defaultValue: true)
  bool isSynced; // Status sinkronisasi Offline-to-Cloud
  @HiveField(8, defaultValue: true)
  bool isPrivate; // Hak privasi penglihatan catatan
  @HiveField(9, defaultValue: false)
  bool isDeleted; // Tombstone flag untuk sinkronisasi hapus saat offline

  LogModel({
    this.id,
    required this.title,
    required this.timestamp,
    required this.description,
    this.category = 'Pekerjaan',
    required this.teamId,
    required this.authorId,
    this.isSynced = true, // Default sinkron karena diasumsikan berhasil
    this.isPrivate = true, // Catatan Privat secara bawaan (HOTS)
    this.isDeleted = false, // Secara default tidak dihapus
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      timestamp: map['timestamp'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pekerjaan',
      teamId: map['teamId'] ?? '',
      authorId: map['authorId'] ?? '',
      isSynced: map['isSynced'] ?? true,
      isPrivate: map['isPrivate'] ?? true,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'timestamp': timestamp,
      'description': description,
      'category': category,
      'teamId': teamId,
      'authorId': authorId,
      'isSynced': isSynced,
      'isPrivate': isPrivate,
      'isDeleted': isDeleted,
    };
  }
}
