import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/theme_controller.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/features/onboarding/onboarding_page.dart';
import 'package:openexam_app/features/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenExamApp extends StatefulWidget {
  const OpenExamApp({super.key});

  @override
  State<OpenExamApp> createState() => _OpenExamAppState();
}

class _OpenExamAppState extends State<OpenExamApp> {
  /// null while we read the flag — showing the shell first and then swapping in
  /// onboarding would flash the wrong screen.
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    ThemeController.instance.load();
    _readOnboarded();
  }

  Future<void> _readOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _onboarded = prefs.getBool(Prefs.onboarded) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'OpenExam',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeController.instance.mode,
          // System font scaling is honoured, but capped: on phones with display
          // zoom turned up the layout would otherwise overflow.
          builder: (context, child) {
            final scale = MediaQuery.textScalerOf(context).clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.1,
            );
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: scale),
              // One ambient backdrop behind every route, so frosted panels
              // always have something to blur.
              child: AmbientBackground(child: child ?? const SizedBox.shrink()),
            );
          },
          home: _onboarded == null
              ? const SizedBox.shrink()
              : (_onboarded!
                  ? const AppShell()
                  : OnboardingPage(
                      onDone: () => setState(() => _onboarded = true),
                    )),
        );
      },
    );
  }
}
