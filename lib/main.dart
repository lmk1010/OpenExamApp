import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/app/app.dart';
import 'package:openexam_app/data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));
  // Warm local DB + seed on launch
  await AppDatabase.instance.database;
  runApp(const OpenExamApp());
}
