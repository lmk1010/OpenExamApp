import 'package:flutter/material.dart';
import 'package:openexam_app/features/home/presentation/pages/home_page.dart';

class AppRouter {
  static const home = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      default:
        return MaterialPageRoute<void>(builder: (_) => const HomePage());
    }
  }
}
