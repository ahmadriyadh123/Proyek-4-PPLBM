import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id;
  final String title;
  final String timestamp;
  final String description;
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.timestamp,
    required this.description,
    this.category = 'Pekerjaan',
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      timestamp: map['timestamp'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pekerjaan', 
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
    };
  }
}
