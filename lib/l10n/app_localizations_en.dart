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

  @override
  String get sessionResultTitle => 'How that went';

  @override
  String sessionResultLine(int rate, int correct, int total, String time) {
    return '$rate% correct · $correct of $total · $time';
  }

  @override
  String get sessionSeeReport => 'See the report';

  @override
  String get sessionSeeAnalysis => 'Go through the explanations';

  @override
  String get sessionMock => 'Timed mock exam';

  @override
  String sessionPracticeCount(int count) {
    return 'Practice · $count questions';
  }

  @override
  String get sessionDaily => 'Daily set';

  @override
  String sessionBlankLeft(int count) {
    return '$count still unanswered';
  }

  @override
  String get sessionSubmitWarn =>
      'Anything left blank counts as wrong once you hand in. Submit now?';

  @override
  String get sessionSubmitAnyway => 'Submit anyway';

  @override
  String get sessionQuitMock => 'Leave the mock exam?';

  @override
  String get sessionQuitPractice => 'End this set?';

  @override
  String get sessionQuitMockBody =>
      'Leaving early won\'t produce a score report, but what you\'ve answered still counts towards your practice history.';

  @override
  String sessionQuitPracticeBody(int count) {
    return 'The $count you\'ve answered are saved. Come back for another set whenever.';
  }

  @override
  String get commonQuit => 'Leave';

  @override
  String get sessionSavedHint => 'Saved — find it under You → Saved';

  @override
  String get sessionUnsaved => 'Removed from saved';

  @override
  String get sessionReportedHint =>
      'Noted — find it under You → Reported errors';

  @override
  String sessionAnalysisTime(String time) {
    return 'Explanations · $time';
  }

  @override
  String get sessionReview => 'Review';

  @override
  String get sessionScore => 'Score';

  @override
  String sessionQuestionNo(int n) {
    return 'Question $n';
  }

  @override
  String get sessionLastQuestion => 'Last question';

  @override
  String get sessionViewSingle => 'One at a time';

  @override
  String get sessionViewSingleHint =>
      'One question per screen — fewest distractions';

  @override
  String get sessionViewDual => 'Two up';

  @override
  String get sessionViewDualHint => 'Two per screen — good on a wide display';

  @override
  String get sessionViewScroll => 'Whole paper';

  @override
  String get sessionViewScrollHint => 'Scroll straight through, like paper';

  @override
  String get sessionLayout => 'Layout';

  @override
  String get sessionWasBlank => 'You left this one blank';

  @override
  String get sessionTipsChip => ' Method';

  @override
  String get sessionSeeFigure => 'see the figure above';

  @override
  String get sessionAnalysis => 'Explanation';

  @override
  String sessionCorrectAnswer(String answer) {
    return 'Answer: $answer';
  }

  @override
  String get sessionNext => 'Next';

  @override
  String get sessionMultiHint =>
      'Multiple answers — tap Confirm when you\'re done';

  @override
  String get commonConfirmShort => 'Confirm';

  @override
  String sessionConfirmPicked(int count) {
    return 'Confirm ($count selected)';
  }

  @override
  String get sessionHintAuto =>
      'Picking moves you on · long-press an option to rule it out · swipe to look back';

  @override
  String get sessionHintManual =>
      'Long-press an option to rule it out · swipe between questions · tap a figure to enlarge';

  @override
  String get sessionMyNote => 'My note';

  @override
  String get sessionSubmit => 'Hand in';

  @override
  String get whenToday => 'today';

  @override
  String get whenYesterday => 'yesterday';

  @override
  String whenDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get sessionMockScore => 'Mock result';

  @override
  String get sessionPracticeResult => 'Practice result';

  @override
  String get sessionGoodShape => 'Looking good';

  @override
  String get sessionKeepGoing => 'Keep it up';

  @override
  String get sessionAnotherSet => 'Another set';

  @override
  String sessionTimeUsed(String time) {
    return 'Took $time';
  }

  @override
  String get sessionPerQuestionNone => '— per question';

  @override
  String sessionUnanswered(int count) {
    return '$count unanswered';
  }

  @override
  String get sessionDoubtReview => 'Flagged for review';

  @override
  String sessionDoubtCount(int count) {
    return 'You flagged $count while working — tap to go through them';
  }

  @override
  String sessionSlowCount(int count) {
    return '$count took over 90 seconds — in a real exam you\'d skip those first';
  }

  @override
  String get sessionByType => 'Score by type';

  @override
  String get sessionWrongReview => 'Mistakes';

  @override
  String sessionWrongCount(int count) {
    return '$count · tap to see the question';
  }

  @override
  String get sessionAllCorrect => 'All correct';

  @override
  String get sessionAllCorrectBody =>
      'Nothing wrong in this set. Switch to another type and keep the rhythm.';

  @override
  String get sessionGoThrough => 'Go through them';

  @override
  String get commonDone => 'Done';

  @override
  String sessionRedoWrong(int count) {
    return 'Redo the $count wrong';
  }

  @override
  String get sessionNoteTitle => 'Note on this question';

  @override
  String get sessionNoteHint =>
      'Method, traps, formulas — shows up under the explanation when you review';

  @override
  String get commonDelete => 'Delete';

  @override
  String get sessionWhyWrong => 'Why did you miss it?';

  @override
  String get sessionTagged => 'Tagged — tap again to undo';

  @override
  String get sessionReportTitle => 'Something\'s wrong with this question';

  @override
  String get sessionReportHint =>
      'Kept on this device, visible under You, and included in backups';

  @override
  String get sessionReportNote => 'Add a line or two (optional)';

  @override
  String get sessionReportSubmit => 'Note it';

  @override
  String get sessionMaterial => 'Passage';

  @override
  String get fontSmall => 'Small';

  @override
  String get fontNormal => 'Normal';

  @override
  String get fontLarge => 'Large';

  @override
  String get fontHuge => 'Huge';

  @override
  String get sessionReading => 'Reading';

  @override
  String get sessionFontSize => 'Text size';

  @override
  String get sessionAutoNext => 'Auto-advance when correct';

  @override
  String get sessionAutoNextHint =>
      'Still stops on a wrong answer so you can read why';

  @override
  String get sessionCard => 'Answer sheet';

  @override
  String sessionAnsweredOf(int done, int total) {
    return '$done of $total answered';
  }

  @override
  String get sessionRight => 'right';

  @override
  String get sessionWrongShort => 'wrong';

  @override
  String get sessionAnswered => 'answered';

  @override
  String get sessionDoubt => 'flagged';

  @override
  String get sessionSubmitEarly => 'Hand in early';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get sessionDifficultyFor => 'For me this one is';

  @override
  String get sessionScratch => 'Scratchpad & calculator';

  @override
  String get sessionHasScratch => 'This one already has notes on it';

  @override
  String get sessionScratchHint => 'Handy for data-analysis arithmetic';

  @override
  String get sessionWriteNote => 'Write a note';

  @override
  String get sessionHasNote => 'This one already has a note';

  @override
  String get sessionNoteShort => 'Method and traps — shows up when you review';

  @override
  String get sessionLayoutHint => 'One up / two up / whole paper';

  @override
  String get sessionReadingHint => 'Text size and auto-advance';

  @override
  String get sessionUnsave => 'Remove from saved';

  @override
  String get sessionSave => 'Save this one';

  @override
  String get sessionSaveHint => 'Saved questions live under You → Saved';

  @override
  String get sessionReportShort => 'Report a problem';

  @override
  String get sessionReportShortHint =>
      'Wrong answer, unclear explanation — flag either';

  @override
  String get homeNoQuestionsHere => 'Nothing here yet';

  @override
  String get homeNoUnseen => 'No unseen questions left in this range';

  @override
  String get homeNoWrongHere => 'No mistakes here yet';

  @override
  String homeReciteSub(String name) {
    return '$name · flashcards';
  }

  @override
  String get homeRecite => 'Flashcards';

  @override
  String get homeHardTagged => 'Marked hard';

  @override
  String homeTimedSub(String name) {
    return '$name · timed';
  }

  @override
  String homeTimedCat(String name) {
    return '$name · timed drill';
  }

  @override
  String get homeEssay => 'Essay';

  @override
  String get homeManualTask => 'Tick it off when you\'re done';

  @override
  String get homeRedoWrong => 'Redo mistakes';

  @override
  String get homeWeakDrill => 'Weak-spot drill';

  @override
  String get homeDeleteTask => 'Delete this item';

  @override
  String homeDeleteTaskConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get homeResume => 'Pick up where you left off';

  @override
  String homeResumeLine(String title, int count) {
    return '$title · $count left';
  }

  @override
  String get homeDaily => 'Daily set';

  @override
  String get homeDailyHint => 'Today\'s fixed set';

  @override
  String homeProvincePapers(String name) {
    return '$name papers';
  }

  @override
  String homeProvinceHint(int count) {
    return '$count · the ones you\'re sitting';
  }

  @override
  String get homeWeakLocked => 'Finish one set to unlock';

  @override
  String get homeWeakHint => 'Weighted towards your weak modules';

  @override
  String get homeNoWrong => 'No mistakes yet';

  @override
  String homeWrongLeft(int count) {
    return '$count to clear';
  }

  @override
  String get homeEssayMark => 'Essay marking';

  @override
  String get homeEssayHint => 'Write one and let AI mark it';

  @override
  String get homeMock => 'Timed mock';

  @override
  String get homeMoreWays => 'More ways to practise';

  @override
  String homeStreak(int days) {
    return '$days-day streak';
  }

  @override
  String get homeDailyCheckin => 'Daily check-in';

  @override
  String homePerSet(int count) {
    return '$count per set';
  }

  @override
  String homeTotalInBank(int count) {
    return '$count in the bank';
  }

  @override
  String get homeDailyReview => 'Today\'s set — review';

  @override
  String homeCatchUp(String date) {
    return 'Catch up on $date';
  }

  @override
  String homeRegionPapers(String name) {
    return '$name papers';
  }

  @override
  String get homeTodayRoute => 'Today\'s route';

  @override
  String get homeArrange => 'Plan it';

  @override
  String homeAllTasks(int count) {
    return 'All $count';
  }

  @override
  String get homeAdjust => 'Adjust';

  @override
  String get homeIslands => 'The five islands';

  @override
  String homeHardCount(int count) {
    return '$count you marked hard';
  }

  @override
  String get homeGreetDone => 'Today\'s rowing is done';

  @override
  String get homeGreetMorning => 'Morning — time to set off';

  @override
  String get homeGreetKeep => 'Keep rowing';

  @override
  String get homeGreetFinish => 'Wrap up and pull in';

  @override
  String get homeNoRoute => 'No route planned for today';

  @override
  String get homeRouteHint =>
      'Templates are editable — drop what you won\'t do';

  @override
  String get homeGoPlan => 'Plan it';

  @override
  String get scopeAll => 'All questions';

  @override
  String get scopeUnseen => 'Unseen';

  @override
  String get scopeWrong => 'Missed before';

  @override
  String get scopeAllHint => 'Recent papers first, random within a year';

  @override
  String get scopeUnseenLong => 'Ones you haven\'t seen';

  @override
  String get scopeUnseenHint => 'Skips what you\'ve done · still recent-first';

  @override
  String get scopeWrongLong => 'Ones you got wrong';

  @override
  String get scopeWrongHint => 'Only questions you missed last time';

  @override
  String get scopeTitle => 'Where to draw from';

  @override
  String get scopeHint => 'Long-press the count to change set size';

  @override
  String scopeCount(int count) {
    return '$count questions';
  }

  @override
  String get yearAllHint => 'Everything in the bank, still recent-first';

  @override
  String yearLast3Hint(String from, String to) {
    return '$from–$to · closest to this year\'s structure';
  }

  @override
  String yearLast1Hint(String year) {
    return '$year only · the one to use for current-affairs questions';
  }

  @override
  String get yearRangeTitle => 'Year range';

  @override
  String get yearRangeHint =>
      'Half the general-knowledge questions quote speeches and policies from the year before the exam, so old answers have expired. Verbal, reasoning and data-analysis structures barely change — old papers are still fine there.';

  @override
  String yearRangeCount(int count) {
    return '$count questions';
  }

  @override
  String get homeDailyGoal => 'Daily goal';

  @override
  String get homeDailyGoalHint =>
      '20–30 a day if you\'re working; 60+ if you\'re studying full time';

  @override
  String countQuestions(int count) {
    return '$count questions';
  }

  @override
  String get homeSetSize => 'Questions per set';

  @override
  String get homeAboutBody =>
      'A local-first practice tool. The question bank, your answers and your statistics all stay on this device — nothing goes online, nothing is uploaded. Import your own questions from the Import page.';

  @override
  String get homeTimed => 'Timed';

  @override
  String homeExpandHint(int count) {
    return '$count · expand a type to start';
  }

  @override
  String get homeNoSubtypes => 'No sub-types';

  @override
  String get homeMixAll => 'Mix them all';

  @override
  String homeMixHint(int count, int minutes) {
    return '$count · about $minutes min at exam pace';
  }

  @override
  String homeSubCount(int count) {
    return '$count questions';
  }

  @override
  String get homePlain => 'Just practise';

  @override
  String homePlainHint(int count) {
    return '$count, untimed';
  }

  @override
  String get homeTimedDrill => 'Timed drill';

  @override
  String homeTimedDrillHint(int count, int minutes) {
    return '$count · about $minutes min at exam pace';
  }

  @override
  String get homeReciteHint =>
      'No answering — straight to the answer and explanation';
}
