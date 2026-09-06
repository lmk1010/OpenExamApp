import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/app/app.dart';
import 'package:openexam_app/data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 这两个平台调用发出去就算数，谁都不等它们的回执。
  //
  // setEnabledSystemUIMode 原来是 await 的：通道要等 Android 那边的 Activity
  // 起完才回话，首帧就白等了 ~600ms（iOS 上只有 ~40ms，是 Android 独有的坑）。
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));
  // 开库也不挡首帧：每个用库的地方本来就 await database，首启解包那几秒
  // 用户能先看到引导页，而不是一扇白窗。
  unawaited(AppDatabase.instance.database);
  runApp(const OpenExamApp());
}
