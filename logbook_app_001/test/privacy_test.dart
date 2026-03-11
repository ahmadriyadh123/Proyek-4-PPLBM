import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() {
  setUpAll(() async {
    // Memuat .env dan menginisiasi koneksi sebelum _test_ dimulai
    await dotenv.load(fileName: ".env");
    await MongoService().connect();
  });

  test('RBAC Security Check: Private logs should NOT be visible to teammates', () async {
    // 1. Setup Data:
    // User A memiliki 2 catatan: 1 berstatus 'Private' dan 1 berstatus 'Public'.
    final mongoService = MongoService();
    const testTeam = "TEST_SECURITY_KLP";
    
    final logPrivate = LogModel(
      title: "Rahasia Negara",
      description: "Ini private draft dari User A",
      timestamp: "2026-03-09",
      category: "Pekerjaan",
      teamId: testTeam,
      authorId: "UserA",
      isSynced: true,
      isPrivate: true,
    );

    final logPublic = LogModel(
      title: "Laporan Terbuka",
      description: "Ini public final dari User A",
      timestamp: "2026-03-09",
      category: "Pekerjaan",
      teamId: testTeam,
      authorId: "UserA",
      isSynced: true,
      isPrivate: false,
    );
    
    // Simulasikan User A mengunggah datanya ke MongoDB Atlas
    await mongoService.insertLog(logPrivate);
    await mongoService.insertLog(logPublic);

    // 2. Action:
    // User B (rekan satu tim User A) melakukan fungsi fetchLogs() dengan role 'Ketua'.
    final fetchedLogs = await mongoService.getLogs(testTeam, "UserB", "Ketua");

    // Teardown / Cleanup: Bersihkan data uji keamanan dari MongoDB Atlas
    final dbUri = dotenv.env['MONGODB_URI'];
    final db = await Db.create(dbUri!);
    await db.open();
    final collection = db.collection('logs');
    await collection.remove(where.eq('teamId', testTeam));
    await db.close();

    // 3. Assert (Validasi):
    // Pastikan List data yang diterima User B hanya berisi 1 log (hanya yang Public).
    // Jika log Private muncul, maka sistem dinyatakan gagal (Vulnerable).
    
    expect(fetchedLogs.length, 1, reason: "Database bocor! User B dapat melihat jumlah catatan yang tidak wajar (Seharusnya hanya 1 log Publik).");
    expect(fetchedLogs.first.title, "Laporan Terbuka", reason: "Catatan yang didapat bukan catatan Public.");
    expect(fetchedLogs.any((log) => log.isPrivate == true), false, reason: "SECURITY VULNERABILITY: Catatan Private User A terekspos dan terlihat oleh User B.");
  });

  tearDownAll(() async {
    await MongoService().close();
  });
}
