import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_001/features/models/log_model.dart';
import 'package:logbook_app_001/features/models/objectid_adapter.dart';

void main() async {
  // Wajib untuk operasi async sebelum runApp, seperti load env dan inisialisasi Hive
  WidgetsFlutterBinding.ensureInitialized();

  //Load env
  await dotenv.load(fileName: ".env");

  // Inisialisasi format tanggal (inti) untuk bahasa Indonesia
  await initializeDateFormatting('id_ID', null);
  
  // Inisialisasi Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ObjectIdAdapter()); // Daftarkan Adapter untuk ObjectId MongoDB
  Hive.registerAdapter(LogModelAdapter()); // Generasi otomatis dari hive_generator
  await Hive.openBox<LogModel>('offline_logs'); // Buka box untuk menyimpan log offline
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const OnboardingView(),
    );
  }
}
