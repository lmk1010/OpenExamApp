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

  @override
  String importScanDone(int count) {
    return 'Imported $count questions';
  }

  @override
  String get importUnreadable => 'Can\'t read that file — try another one';

  @override
  String get importNoQuestions =>
      'No questions found in that file — see the format notes below';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get importWayScanTitle => 'Photo / PDF';

  @override
  String get importWayScanDesc =>
      'Exam papers, screenshots, a PDF you bought — AI reads them page by page';

  @override
  String get importWayDocTitle => 'Word / Excel / text';

  @override
  String get importWayDocDesc =>
      'docx, xlsx, csv, txt — AI reads the text directly';

  @override
  String get importWayFileTitle => 'Question file';

  @override
  String get importWayFileDesc => 'JSON or CSV; zip it up if it has images';

  @override
  String get profileDefaultName => 'Studying';

  @override
  String get profileClearTitle => 'Clear practice history';

  @override
  String get profileClearBody =>
      'Answers, accuracy, the mistake book, score reports, mistake tags, streaks, your own difficulty ratings, review plans and badges are all wiped — back to a fresh install.\n\nBookmarks, notes, saved words and essay drafts are kept, and so is the question bank itself. This can\'t be undone — export from Backup & restore first if you want a way back.';

  @override
  String get profileClearConfirm => 'Clear it';

  @override
  String get profileClearDone => 'Practice history cleared';

  @override
  String profileAboutTitle(int count) {
    return 'About OpenExam · $count questions';
  }

  @override
  String get profileAboutBody =>
      'A local-first practice tool, sharing its engine with OpenExam for desktop.\n\nBring your own question bank and make sure you have the right to use it — the app never scrapes third-party paid content.';

  @override
  String get profileReplayOnboarding => 'Replay the intro';

  @override
  String get profileClearHint =>
      'Wipes answers, the mistake book and score reports';

  @override
  String profileDaysLeft(int days) {
    return '$days days to go';
  }

  @override
  String get profileToday => 'Today\'s the day';

  @override
  String get profileTab => 'You';

  @override
  String get profileBadges => 'Badges';

  @override
  String get profileVocab => 'Words';

  @override
  String get profileNotes => 'Notes';

  @override
  String get profileMarks => 'Saved';

  @override
  String get profileReports => 'Reports';

  @override
  String get profileStats => 'Stats';

  @override
  String get profileTips => 'Method';

  @override
  String get profileFeedback => 'Report an error';

  @override
  String get profileSectionExam => 'Exam';

  @override
  String get profileFeatures => 'Modules';

  @override
  String profileFeaturesOn(int count) {
    return '$count on';
  }

  @override
  String get profilePlan => 'Study plan';

  @override
  String get profilePrefs => 'Practice settings';

  @override
  String profileDailyGoalValue(int count) {
    return '$count a day';
  }

  @override
  String get profileSectionBank => 'Question bank';

  @override
  String get profileImport => 'Import questions';

  @override
  String profileImportedCount(int count) {
    return '$count questions';
  }

  @override
  String get profileBankManage => 'Manage bank';

  @override
  String get profileBankHealth => 'Bank check-up';

  @override
  String get profileBackup => 'Backup & restore';

  @override
  String get profileSectionApp => 'App';

  @override
  String get profileAiSettings => 'AI settings';

  @override
  String get profileConfigured => 'Configured';

  @override
  String get profileAiUsage => 'AI usage';

  @override
  String get profilePrivacy => 'Data & privacy';

  @override
  String get profilePrivacyBody =>
      'The question bank, your answers, statistics and mistake book all live in a SQLite database on this device. Nothing is uploaded, nothing is tracked, there are no accounts.\n\nThe only feature that goes online is AI (essay marking, photo-to-question): it fires only when you ask it to, goes straight to the provider you configured, and your API key stays on this device. Leave it unconfigured and the app is fully offline.';

  @override
  String get profileAbout => 'About';

  @override
  String get profileNoStatsYet =>
      'Nothing recorded yet — finish one set and numbers show up';

  @override
  String profileStatsLine(int rate, int count) {
    return '$rate% correct · $count this week';
  }

  @override
  String get profileThemeAuto => 'Auto';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';

  @override
  String get profileTheme => 'Theme';

  @override
  String get profileRename => 'Change your name';

  @override
  String get profileRenameHint => 'e.g. Countdown';

  @override
  String get commonSave => 'Save';

  @override
  String get profileRegion => 'Region';

  @override
  String get profileRegionHint =>
      'Used to surface papers from that region first';

  @override
  String get profileDailyGoal => 'Daily goal';

  @override
  String get profileDailyGoalHint =>
      '20–30 a day if you\'re working; 60+ if you\'re studying full time';

  @override
  String get profileSetSize => 'Questions per set';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get profilePickExamDate => 'Pick your exam date';

  @override
  String get profileMockCount => 'Mock length';

  @override
  String get profileMockMinutes => 'Mock time limit';

  @override
  String get commonConfirm => 'OK';

  @override
  String get profileSetSizeShort => 'Per set';

  @override
  String get profileExamDate => 'Exam date';

  @override
  String profileDaysRemaining(int days) {
    return '$days days left';
  }

  @override
  String get profileMock => 'Timed mock exam';

  @override
  String get profileMockHint => 'Set it to your own exam\'s pace';

  @override
  String get profileMockCountShort => 'Questions';

  @override
  String get profileMockMinutesShort => 'Time';

  @override
  String get wrongRemoved => 'Removed from the mistake book';

  @override
  String get wrongSaved => 'Saved';

  @override
  String get wrongExportHeading => '# Mistake book';

  @override
  String wrongExportedAt(String at) {
    return 'Exported: $at';
  }

  @override
  String wrongExportTotal(int count) {
    return '$count questions in total';
  }

  @override
  String get wrongExportHasImage =>
      '(this question has a figure; the export doesn\'t include images)';

  @override
  String get wrongExportImageOption => '(image option)';

  @override
  String wrongExportAnalysis(String text) {
    return 'Explanation: $text';
  }

  @override
  String wrongExportNote(String text) {
    return 'My note: $text';
  }

  @override
  String wrongExportSavedDocs(String name) {
    return 'Saved to the app\'s documents folder: $name';
  }

  @override
  String wrongExportSaved(String name) {
    return 'Exported $name';
  }

  @override
  String wrongExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get wrongQuickLook => 'Quick look';

  @override
  String get diagnosisTitle => 'Weak spots';

  @override
  String get wrongDiagnosisHint =>
      'Measures your pace and accuracy against real-paper benchmarks';

  @override
  String get wrongTodayReview => 'Today\'s review';

  @override
  String wrongRepeatFirst(int count) {
    return 'Start with the $count you\'ve missed twice or more';
  }

  @override
  String get commonStart => 'Start';

  @override
  String get wrongBrowseAnalysis => 'Skim the explanations';

  @override
  String wrongUntagged(int count) {
    return '$count still have no reason tagged — tag them and you\'ll know whether it was carelessness or a gap';
  }

  @override
  String get wrongRepeating => 'Still repeating';

  @override
  String get wrongLongPressHint =>
      'Long-press a group to start a four-day drill';

  @override
  String get wrongNoReason => 'Untagged';

  @override
  String get wrongByType => 'By type';

  @override
  String get commonAllArrow => 'All ›';

  @override
  String wrongViewAll(int count) {
    return 'Go through all $count one by one';
  }

  @override
  String get wrongNoPaper => 'Not part of a paper';

  @override
  String get wrongBookTitle => 'Mistake book';

  @override
  String wrongToClear(int count) {
    return '$count left to clear';
  }

  @override
  String get wrongAll => 'All mistakes';

  @override
  String wrongFiltered(int count) {
    return '$count after filters';
  }

  @override
  String get wrongRedoFiltered => 'Redo the filtered questions';

  @override
  String get wrongExportMarkdown => 'Export this list as Markdown';

  @override
  String get wrongEmptyHint =>
      'Anything you get wrong lands here automatically';

  @override
  String wrongCountWithHint(int count) {
    return '$count · long-press to tag a reason';
  }
}
