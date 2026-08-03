import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/app/app.dart';
import 'package:openexam_app/data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Warm local DB + seed on launch
  await AppDatabase.instance.database;
  runApp(const OpenExamApp());
}
