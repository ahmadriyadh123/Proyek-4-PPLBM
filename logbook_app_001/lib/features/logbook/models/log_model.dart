class LogModel {
  final String title;
  final String timestamp;
  final String description;

  LogModel({
    required this.title,
    required this.timestamp,
    required this.description,
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      timestamp: map['timestamp'],
      description: map['description'],
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'timestamp': timestamp,
      'description': description,
    };
  }
}
