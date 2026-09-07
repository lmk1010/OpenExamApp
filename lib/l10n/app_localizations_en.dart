// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLEn extends AppL {
  AppLEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OpenExam';

  @override
  String get onboardTitle => 'Practice\nis how you get there';

  @override
  String onboardBodyWithBank(int count) {
    return '$count questions, right here on your phone\nNo account, no connection needed';
  }

  @override
  String get onboardBodyNoBank =>
      'The question bank is separate from the app\nImport one and you\'re ready — no account, works offline';

  @override
  String get onboardBodyLoading => 'No account, no connection needed';

  @override
  String get onboardWrongTitle => 'Your mistakes\nkeep track of themselves';

  @override
  String get onboardWrongBody =>
      'Miss one and it lands in your mistake book; get it right and it leaves\nAdd a note or tag why you missed it, if you like';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get onboardStart => 'Start';

  @override
  String get noBankTitle => 'No question bank yet';

  @override
  String get noBankBody =>
      'This build ships without questions — the bank is separate from the app, so whichever bank you install decides which exam you\'re practising for. Import one and you\'re ready: practice, timed mock exams, mistake review and pace diagnostics all work offline.';

  @override
  String get noBankImport => 'Import a bank';

  @override
  String get noBankHint =>
      'You can also drop a bank file into the OpenExam folder in the Files app, or use Scan paper to turn a printed exam into questions.';

  @override
  String get bankTitle => 'Question bank';

  @override
  String get bankExportTitle => 'Export bank';

  @override
  String get bankExportBody =>
      'Exports a zip with the questions and their images. Anyone can load it with Import — it\'s the same format Import reads.';

  @override
  String get bankExportWholeBank => 'Entire bank';

  @override
  String bankExportWholeBankHint(int count) {
    return '$count questions · large file';
  }

  @override
  String bankExportCount(int count) {
    return '$count questions';
  }

  @override
  String get bankExportEmpty => 'Nothing to export in that range';

  @override
  String get bankExportCancelled => 'Cancelled';

  @override
  String bankExportDone(int count, String name) {
    return 'Exported $count questions: $name';
  }

  @override
  String bankExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Match system';

  @override
  String get settingsLanguageSystemHint => 'Follows your phone\'s language';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardFinish => 'Let\'s go';
}
