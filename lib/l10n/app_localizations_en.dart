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
  String get noBankImport => 'Import a bank';

  @override
  String get noBankHint =>
      'Or drop a file into the OpenExam folder in Files, or scan a printed paper.';

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
  String get settingsLanguageSystem => 'Auto';

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
  String get importWayFileTitle => 'Bank file';

  @override
  String get importWayFileDesc =>
      'A pack from the site, or a zip / JSON / CSV someone sent you';

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

  @override
  String get dxScopeAll => 'All practice history';

  @override
  String dxThinSample(int count) {
    return 'Only $count answers so far — the conclusions aren\'t stable yet. Come back after 100.';
  }

  @override
  String dxSlowTitle(String name) {
    return '$name is slow enough to sink the whole paper';
  }

  @override
  String dxSlowEvidence(int secs, int bench, int pct) {
    return '${secs}s per question against a ${bench}s benchmark — $pct% slower';
  }

  @override
  String dxSlowOverrun(int mins) {
    return '; at that pace a full paper costs you $mins extra minutes';
  }

  @override
  String dxSlightlySlowTitle(String name) {
    return '$name is a little slower than the benchmark';
  }

  @override
  String dxPaceEvidence(int secs, int bench) {
    return '${secs}s per question, benchmark ${bench}s';
  }

  @override
  String dxSlightlySlowAction(int bench) {
    return 'Still manageable, but time yourself at ${bench}s in drills so it doesn\'t creep further.';
  }

  @override
  String dxFastSteadyTitle(String name) {
    return '$name is quick and steady';
  }

  @override
  String dxFastSteadyEvidence(int secs, int bench, String rate) {
    return '${secs}s per question (benchmark ${bench}s), $rate correct';
  }

  @override
  String get dxFastSteadyAction =>
      'No more time needed here — spend those minutes on the weak modules.';

  @override
  String dxRushTitle(String name) {
    return '$name: you\'re missing these by rushing, not by not knowing';
  }

  @override
  String dxRushEvidence(
    int secs,
    int bench,
    int pct,
    String rate,
    String target,
  ) {
    return '${secs}s per question — $pct% faster than the ${bench}s benchmark — but only $rate correct (target $target)';
  }

  @override
  String dxRushAction(int bench, String target, String how) {
    return 'Slow back down to ${bench}s a question and get to $target before speeding up again. The minutes you save don\'t buy back the marks you drop — $how';
  }

  @override
  String dxAccuracyGapTitle(String name) {
    return '$name is well short of its target accuracy';
  }

  @override
  String dxAccuracyGapEvidence(
    String rate,
    int correct,
    int attempts,
    String target,
  ) {
    return '$rate ($correct/$attempts), target $target';
  }

  @override
  String dxAlmostTitle(String name) {
    return '$name is nearly at target';
  }

  @override
  String dxAlmostEvidence(String rate, String target) {
    return '$rate, target $target';
  }

  @override
  String get dxAlmostAction =>
      'Go through this module\'s mistakes by reason and see whether it\'s the same trap repeating or scattered slips.';

  @override
  String get dxTimeSinkTitle => 'Quantitative is eating too much of your time';

  @override
  String dxTimeSinkEvidence(String share, String paper) {
    return 'It takes $share of your practice time but is only $paper of the paper';
  }

  @override
  String get dxOverthinkTitle => 'You\'re agonising over general knowledge';

  @override
  String get dxThinPracticeTitle => 'You\'ve barely practised data analysis';

  @override
  String dxThinPracticeEvidence(String share, String paper) {
    return 'Only $share of your practice, but $paper of the paper';
  }

  @override
  String get dxRepeatTitle => 'You\'re repeating mistakes, not making new ones';

  @override
  String dxRepeatEvidence(int total, int repeat, String pct) {
    return '$repeat of the $total in your mistake book have been missed twice or more ($pct)';
  }

  @override
  String get dxRepeatAction =>
      'Repeating means the first review never found the cause. Take the few you miss most and write down why you picked what you picked — worth more than ten fresh questions.';

  @override
  String get dxUntaggedTitle => 'Most of your mistakes have no reason tagged';

  @override
  String dxUntaggedEvidence(int total, int tagged) {
    return 'Only $tagged of $total are tagged';
  }

  @override
  String get dxUntaggedAction =>
      'Tagging is the only lever review has. Didn\'t know it, misread it, miscalculated, ran out of time — the four need completely different fixes, and without separating them all you can do is redo the whole book.';

  @override
  String get dxTrendUpTitle => 'The last two weeks are trending up';

  @override
  String get dxTrendDownTitle => 'The last two weeks went the other way';

  @override
  String dxTrendEvidence(String recent, String earlier) {
    return 'Last two weeks $recent, before that $earlier';
  }

  @override
  String get dxTrendUpAction => 'Keep doing exactly what you\'re doing.';

  @override
  String get dxTrendDownAction =>
      'Usually one of two things: you started timing yourself, or you moved to a harder module. Work out which — the first is normal, the second means slow down.';

  @override
  String get dxTailBlankTitle =>
      'You didn\'t finish data analysis — the time went missing earlier';

  @override
  String dxBlankTitle(int count) {
    return '$count left unanswered';
  }

  @override
  String dxBlankWithTail(int total, int tail) {
    return '$total blank in all, $tail of them in data analysis';
  }

  @override
  String dxBlankOnly(int total) {
    return '$total left blank';
  }

  @override
  String get dxTailBlankAction =>
      'Data analysis is the one module you can score full marks on with practice — never leave it to whatever time is left. Next time do it right after reasoning and put quantitative last.';

  @override
  String get dxBlankAction =>
      'Fill in the blanks anyway — pick one letter and use it for all of them; every option sits around 25%.';

  @override
  String get dxOvertimeTitle => 'Over time on the whole paper';

  @override
  String dxOvertimeEvidence(int actual, int budget) {
    return '$actual minutes against a $budget-minute benchmark for these questions';
  }

  @override
  String get dxOvertimeAction =>
      'Overruns usually come from one or two modules. See which one is flagged slow above and time that one first.';

  @override
  String get dxUnderTimeTitle => 'You\'re ahead of the benchmark pace';

  @override
  String dxUnderTimeEvidence(int actual, int budget) {
    return '$actual minutes, benchmark $budget';
  }

  @override
  String get dxUnderTimeAction =>
      'If accuracy is on target too, spend the saved minutes picking off a couple more quantitative questions.';

  @override
  String get dxNoRecords => 'No answers recorded yet';

  @override
  String dxHeadlineClean(int count, String rate) {
    return '$count questions, $rate correct — no obvious weak spot';
  }

  @override
  String dxHeadlineWorst(int count, String rate, String what) {
    return '$count questions, $rate correct — fix $what first';
  }

  @override
  String get dxPageTitle => 'Weak spots';

  @override
  String get dxEmptyTitle => 'No answers recorded yet';

  @override
  String get dxEmptyBody =>
      'Finish a set and come back — this runs on your own answers, not somebody else\'s advice.';

  @override
  String get dxFootnote =>
      'Benchmarks come from counting 161 real papers question by question; the per-question seconds are derived from those counts and match the ones on the Method page.';

  @override
  String get dxModuleTable => 'By module · measured against benchmark';

  @override
  String get dxColQuestions => 'Qs';

  @override
  String get dxColAccuracy => 'Correct';

  @override
  String get dxColSeconds => 's/q';

  @override
  String get dxColBench => 'Bench';

  @override
  String get dxFindings => 'What it says';

  @override
  String dxFindingsCount(int count) {
    return '$count of them';
  }

  @override
  String get dxNoWeakSpot =>
      'Pace and accuracy sit near the benchmark across the board — nothing worth singling out. Carry on as you are.';

  @override
  String get dxNoBenchmark =>
      'This bank\'s categories don\'t line up with the benchmarked modules, so there\'s nothing to compare against. The totals above are still your real numbers, but there\'s no basis for saying how many seconds a question should take or where accuracy should sit.';

  @override
  String get dxLevelBad => 'Fix';

  @override
  String get dxLevelWatch => 'Watch';

  @override
  String get dxLevelGood => 'Good';

  @override
  String get dxAiSection => 'AI read-through';

  @override
  String get dxRegenerate => 'Regenerate';

  @override
  String get dxAiPitch =>
      'The conclusions above are computed on this device against real-paper benchmarks and are ready to use. AI joins them into cause and effect and lays out a week\'s training.';

  @override
  String get dxAiNotConfigured =>
      'No AI configured. Everything above works without it — AI is just an extra layer of reading on top.';

  @override
  String get dxAskAi => 'Ask AI';

  @override
  String get dxConfigureAi => 'Set up AI';

  @override
  String get dashTitle => 'Your profile';

  @override
  String get dashByModule => 'Module by module';

  @override
  String get dashByModuleHint => 'Weakest accuracy first';

  @override
  String get dashLast35 => 'Last 35 days';

  @override
  String get dashHeatHint => 'Darker means more practice';

  @override
  String get dashTrend => 'Score trend';

  @override
  String dashLastN(int count) {
    return 'Last $count';
  }

  @override
  String get dashWhen => 'When you practise';

  @override
  String get dashWhenHint => 'What time of day you tend to work';

  @override
  String get dashAdvice => 'What to do next';

  @override
  String get dashAdviceHint => 'Read off your current numbers';

  @override
  String get dashEmpty => 'Finish your first set and this page fills up.';

  @override
  String get dashDataNote =>
      'Everything here comes from this device only; clearing your practice history resets the page.';

  @override
  String get dashDoFirstSet => 'Do a set of 20 first';

  @override
  String get dashDoFirstSetHint =>
      'Accuracy and weak spots need something to work from, and so does this page.';

  @override
  String dashWeakest(String name) {
    return '$name is your weakest right now';
  }

  @override
  String dashWeakestBody(int rate, int done) {
    return '$rate% correct over $done questions. Weak-spot drills give it the biggest share — get this above 70% first.';
  }

  @override
  String get dashTopCareless => 'Most of your mistakes are careless';

  @override
  String get dashTopUnknown => 'Most of your mistakes are gaps';

  @override
  String get dashTopMisread => 'Most of your mistakes are misreads';

  @override
  String get dashTopNoTime => 'Most of your mistakes are time';

  @override
  String dashCarelessBody(int count) {
    return '$count tagged careless. Don\'t add volume — take each answer back to the question and check it.';
  }

  @override
  String dashUnknownBody(int count) {
    return '$count tagged as gaps. Go back for the method first — drilling the same type only pays after that.';
  }

  @override
  String dashMisreadBody(int count) {
    return '$count came down to misreading. Circle the qualifiers and the units as you read.';
  }

  @override
  String dashNoTimeBody(int count) {
    return '$count ran out of time. Time yourself module by module before taking whole papers.';
  }

  @override
  String get dashGoTagged => 'Go through the mistake book by reason';

  @override
  String dashDropped(String name, int points) {
    return '$name dropped $points points this week';
  }

  @override
  String dashDroppedBody(int before, int now, int done) {
    return '$before% the week before, $now% over the last 7 days ($done questions). Don\'t add volume yet — go through this module in the mistake book and see whether it\'s one type repeating or just rust.';
  }

  @override
  String get dashSeeModuleWrong => 'See this module\'s mistakes';

  @override
  String dashRose(String name, int points) {
    return '$name gained $points points this week';
  }

  @override
  String dashRoseBody(int before, int now, int done) {
    return '$before% the week before, $now% over the last 7 days ($done questions). Whatever you\'re doing here works — start squeezing the clock.';
  }

  @override
  String dashSlow(String name) {
    return '$name is taking you a while';
  }

  @override
  String dashSlowBody(int secs) {
    return '${secs}s a question on average. Anything past 90 seconds is one to skip in the exam — hold yourself to that in practice too.';
  }

  @override
  String get dashTimeThisModule => 'Do a timed drill on it';

  @override
  String get dashStreakBroken => 'Your streak broke';

  @override
  String get dashStreakBrokenBody =>
      'Ten a day still counts — rhythm beats any single big session.';

  @override
  String dashStreakDays(int days) {
    return '$days days running';
  }

  @override
  String get dashStreakBody =>
      'Hold it. What separates people is coming back every day, not one 200-question binge.';

  @override
  String get dashAllSteady => 'Everything looks steady';

  @override
  String get dashAllSteadyBody =>
      'Time yourself on whole papers now and bring your pace into exam rhythm.';

  @override
  String dashDaysLine(int days, int streak) {
    return '$days days practised · $streak in a row';
  }

  @override
  String get unitDays => 'days';

  @override
  String get dashToExam => 'To exam';

  @override
  String get dashOverallRate => 'Overall accuracy';

  @override
  String get dashTotalAnswered => 'Answered';

  @override
  String get dashWrongLeft => 'Mistakes left';

  @override
  String get dashToday => 'Today';

  @override
  String dashPacePerQ(int secs) {
    return '${secs}s/q';
  }

  @override
  String get dashLess => 'less';

  @override
  String get dashMore => 'more';

  @override
  String get dashHeatToday => 'Bottom-right is today';

  @override
  String dashFlat(int rate) {
    return 'Latest $rate%, level with where you started';
  }

  @override
  String dashUp(int from, int to, int points) {
    return '$from% to $to%, up $points points';
  }

  @override
  String dashDown(int from, int to, int points) {
    return '$from% to $to%, down $points points';
  }

  @override
  String get dashHour0 => '0:00';

  @override
  String dashPeakHour(int hour) {
    return 'Usually around $hour:00';
  }

  @override
  String get dashHour23 => '23:00';

  @override
  String get dashPractiseNow => 'Practise now';

  @override
  String get bankTab => 'Bank';

  @override
  String get bankPapers => 'Papers';

  @override
  String get bankAllRegions => 'All regions';

  @override
  String get bankAllYears => 'All years';

  @override
  String get bankNoYear => 'No year';

  @override
  String bankYear(String year) {
    return '$year';
  }

  @override
  String get bankAllStatus => 'Any status';

  @override
  String get bankNotStarted => 'Not started';

  @override
  String get bankInProgress => 'In progress';

  @override
  String get bankFinished => 'Finished';

  @override
  String bankPaperCount(int count) {
    return '$count papers';
  }

  @override
  String bankMatchedCount(int matched, int total) {
    return '$matched of $total';
  }

  @override
  String get bankSearchHint => 'Search by year, region or title';

  @override
  String get bankFilterYear => 'Year';

  @override
  String get bankFilterStatus => 'Status';

  @override
  String get bankSort => 'Sort';

  @override
  String get bankSortYear => 'By year (newest first)';

  @override
  String get bankSortProgress => 'By progress';

  @override
  String get bankSortSize => 'By length';

  @override
  String get bankNoPapers => 'No papers yet';

  @override
  String get bankNoMatch => 'No papers match';

  @override
  String get bankNoPapersHint =>
      'Import from You → Import questions and whole papers show up here.';

  @override
  String get bankNoMatchHint =>
      'Try another keyword — a year, a region, an exam name.';

  @override
  String get bankUndatedGroup => 'No year given';

  @override
  String bankPaperCountShort(int count) {
    return '$count papers';
  }

  @override
  String get bankPickPaper => 'Pick a paper';

  @override
  String get bankPickPaperHint => 'Choose one on the left.';

  @override
  String get bankUntitledPaper => 'Untitled paper';

  @override
  String bankPaperProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get bankImport => 'Import';

  @override
  String get badgeFirstBloodName => 'First blood';

  @override
  String get badgeFirstBloodDesc => 'Answer your first question';

  @override
  String get badgeAnswers100Name => 'Hundred';

  @override
  String get badgeAnswers100Desc => '100 questions answered';

  @override
  String get badgeAnswers500Name => 'Five hundred';

  @override
  String get badgeAnswers500Desc => '500 questions answered';

  @override
  String get badgeAnswers2000Name => 'Two thousand';

  @override
  String get badgeAnswers2000Desc => '2,000 questions answered';

  @override
  String get badgeStreak3Name => 'Three days';

  @override
  String get badgeStreak3Desc => 'Practise 3 days running';

  @override
  String get badgeStreak7Name => 'A full week';

  @override
  String get badgeStreak7Desc => 'Practise 7 days running';

  @override
  String get badgeStreak30Name => 'A full month';

  @override
  String get badgeStreak30Desc => 'Practise 30 days running';

  @override
  String get badgeActive20Name => 'Regular';

  @override
  String get badgeActive20Desc => 'Practise on 20 separate days';

  @override
  String get badgeRate70Name => 'Passing';

  @override
  String get badgeRate70Desc => 'Reach 70% overall (50+ questions)';

  @override
  String get badgeRate85Name => 'Solid';

  @override
  String get badgeRate85Desc => 'Reach 85% overall (200+ questions)';

  @override
  String get badgeStrong3Name => 'Three strong';

  @override
  String get badgeStrong3Desc => 'Hit 80% in three modules (20+ each)';

  @override
  String get badgeExam1Name => 'First sitting';

  @override
  String get badgeExam1Desc => 'Finish your first timed mock';

  @override
  String get badgeExam10Name => 'Ten sittings';

  @override
  String get badgeExam10Desc => 'Finish 10 timed mocks';

  @override
  String get badgeExam80Name => 'Strong paper';

  @override
  String get badgeExam80Desc => 'Score 80% on any mock';

  @override
  String get badgeCleanWrongName => 'Cleared out';

  @override
  String get badgeCleanWrongDesc => 'Empty the mistake book (20+ missed)';

  @override
  String get badgeDay100Name => 'Century day';

  @override
  String get badgeDay100Desc => '100 questions in a single day';

  @override
  String get badgeNotes20Name => 'Note taker';

  @override
  String get badgeNotes20Desc => 'Write 20 question notes';

  @override
  String get badgeMarks30Name => 'Collector';

  @override
  String get badgeMarks30Desc => 'Save 30 questions';

  @override
  String get badgeGroupVolume => 'Volume';

  @override
  String get badgeGroupConsistency => 'Consistency';

  @override
  String get badgeGroupAccuracy => 'Accuracy';

  @override
  String get badgeGroupExams => 'Exams';

  @override
  String get badgeGroupGrind => 'Grind';

  @override
  String get tierBronze => 'Bronze';

  @override
  String get tierSilver => 'Silver';

  @override
  String get tierGold => 'Gold';

  @override
  String get tierPlatinum => 'Platinum';

  @override
  String get badgesTitle => 'Badges';

  @override
  String badgesUnlocked(int done, int total) {
    return '$done of $total unlocked';
  }

  @override
  String get badgesNote =>
      'All computed from data on this device; clearing your history starts them over';

  @override
  String get badgesEarned => 'Earned';

  @override
  String badgesToGo(int count) {
    return ' · $count to go';
  }

  @override
  String get badgesUnlockedTitle => 'Badge unlocked';

  @override
  String badgesAlsoUnlocked(int count) {
    return 'And $count more at the same time';
  }

  @override
  String get badgesTake => 'Take it';

  @override
  String badgesEarnedOn(String date) {
    return 'Earned $date';
  }

  @override
  String planCatPractice(String name) {
    return '$name practice';
  }

  @override
  String get planDeleteSet => 'Delete plan';

  @override
  String planDeleteSetBody(String name, int count) {
    return '\"$name\" and its $count items go; anything you\'ve already ticked stays.';
  }

  @override
  String get planDeleteTask => 'Delete item';

  @override
  String planRepeatNote(String title, String rule) {
    return '\"$title\" repeats: $rule.';
  }

  @override
  String get planSkipToday => 'Skip just today';

  @override
  String get planDeleteForever => 'Delete for good';

  @override
  String get planTitle => 'Study plan';

  @override
  String planStreak(int days) {
    return '$days-day plan streak · a day counts when the list is ticked off';
  }

  @override
  String get planIntro =>
      'Pick a template, then work the list each day — add your own items too';

  @override
  String planMonth(int n) {
    return 'Month $n';
  }

  @override
  String get planSwipeHint => 'Swipe for more days';

  @override
  String get planBackToToday => 'Back to today';

  @override
  String get planNothingToday => 'Nothing planned for this day';

  @override
  String get planAddHint => 'Add one, or start from a template';

  @override
  String get planAdd => 'Add';

  @override
  String get planToday => 'Today\'s list';

  @override
  String get planManage => 'Manage';

  @override
  String get planAddTitle => 'Add an item';

  @override
  String get planMine => 'My plans';

  @override
  String get planOff => 'Off';

  @override
  String get planPick => 'Pick a plan';

  @override
  String get planTodayMark => 'Now';

  @override
  String get commonNew => 'New';

  @override
  String get planClosed => 'Plan is off';

  @override
  String get planClose => 'Turn the plan off';

  @override
  String get planClosedHint =>
      'Plan is off — tap any of these to start using one again';

  @override
  String get planNone => 'No plans yet — tap ＋ to make one';

  @override
  String planItemCount(int count) {
    return '$count items';
  }

  @override
  String get planNewTitle => 'New plan';

  @override
  String get planCreate => 'Create';

  @override
  String get planName => 'Name';

  @override
  String get planNameHint => 'e.g. Final sprint';

  @override
  String get planStartFrom => 'Start from';

  @override
  String get planBlank => 'Blank';

  @override
  String get planBlankHint => 'Add items yourself';

  @override
  String get planTemplateHint =>
      'Templates just copy items in — every one can be edited or removed';

  @override
  String get taskCatPractice => 'Practice by type';

  @override
  String get taskManual => 'Reminder / by hand';

  @override
  String get taskVocab => 'Review words';

  @override
  String get taskCheckin => 'Check in';

  @override
  String get taskOpenWrong => 'Open the mistake book';

  @override
  String get taskCatPracticeHint => 'Draws questions of one type';

  @override
  String get taskMockHint => '50 questions · set your own minutes';

  @override
  String get taskWrongHint => 'Draws from your mistakes';

  @override
  String get taskWeakHint => 'Weighted towards your weak modules';

  @override
  String get taskManualHint => 'Just tick it off — nothing opens';

  @override
  String get taskVocabHint => 'Words due today';

  @override
  String get taskCheckinHint => 'Tick it when done — goes nowhere';

  @override
  String get taskOpenWrongHint => 'Jumps to the mistake book';

  @override
  String get taskUntitled => 'Untitled item';

  @override
  String get taskEdit => 'Edit item';

  @override
  String get taskWhat => 'What to do';

  @override
  String get taskWhatHint => 'e.g. Review 20 idioms';

  @override
  String get taskHowOften => 'How often';

  @override
  String get taskOnceOnly => 'Only on this day';

  @override
  String get taskEditForever => 'Edits apply to every future occurrence';

  @override
  String get taskAlsoPractise => 'Practise alongside it';

  @override
  String get taskAlsoPractiseHint => 'Ticking is enough — this is optional';

  @override
  String get taskType => 'Type';

  @override
  String get taskCount => 'How many';

  @override
  String get taskNote => 'Note (optional)';

  @override
  String get taskMinutes => 'Time limit (minutes, optional)';

  @override
  String get taskSoftLimit => 'Estimate from question count';

  @override
  String get taskSoftLimitHint =>
      'With no minutes set, the length is estimated from the count';

  @override
  String get taskDelete => 'Delete this item';

  @override
  String get taskTapHint =>
      'Only Start opens practice; tapping the row just edits the item.';

  @override
  String get taskEditTitle => 'Edit item';

  @override
  String get commonRename => 'Rename';

  @override
  String get repeatOnce => 'Just once';

  @override
  String get repeatDaily => 'Every day';

  @override
  String get repeatWeekdays => 'Weekdays';

  @override
  String get repeatWeekly => 'This day each week';

  @override
  String get repeatEveryOther => 'Every other day';

  @override
  String cmExported(int count) {
    return 'Exported $count questions';
  }

  @override
  String get cmClearBank => 'Clear the bank';

  @override
  String cmClearBody(int count) {
    return 'Deletes all $count questions.';
  }

  @override
  String get cmClearNote =>
      'Your answers, mistake book and notes stay — re-import the same questions and they line up again.\n\nThis can\'t be undone; export first.';

  @override
  String get cmClear => 'Clear';

  @override
  String cmCleared(int count) {
    return 'Cleared $count questions';
  }

  @override
  String get cmMerge => 'Merge categories';

  @override
  String cmMergeBody(int count, String from, String to) {
    return 'The $count questions in \"$from\" move into \"$to\".';
  }

  @override
  String get cmMergeNote => 'This can\'t be undone, but no questions are lost.';

  @override
  String get cmMergeConfirm => 'Merge';

  @override
  String cmMerged(String name) {
    return 'Merged into \"$name\"';
  }

  @override
  String get cmRenamed => 'Renamed';

  @override
  String get cmNeedAiKey => 'Set up a key first under You → AI settings';

  @override
  String get cmUncategorised => 'Uncategorised';

  @override
  String get cmNoTargets =>
      'No other categories to sort into — make a few first';

  @override
  String get cmAiSort => 'Re-sort with AI';

  @override
  String cmAiSortBody(String name) {
    return 'Re-sorts the questions in \"$name\" into your existing categories.';
  }

  @override
  String cmAiSortNote(int count) {
    return 'AI only picks from the $count categories you already have — it won\'t invent new ones.';
  }

  @override
  String get cmReading => 'Reading…';

  @override
  String get cmAiSortFailed => 'AI couldn\'t sort these — change them by hand';

  @override
  String cmAiSorted(int count) {
    return 'Sorted $count';
  }

  @override
  String get cmTitle => 'Manage the bank';

  @override
  String get cmRenameHint =>
      'Renaming is just renaming; rename to a name that already exists and the two merge. No questions are lost either way.';

  @override
  String get cmEmptyTitle => 'The bank is empty';

  @override
  String get cmEmptyBody =>
      'Import questions and their categories show up here.';

  @override
  String get cmRenameMerge => 'Rename / merge';

  @override
  String get cmMergeInto => 'Merge into an existing one:';

  @override
  String wrongMissedTimes(String name, int count) {
    return '$name · missed $count times';
  }

  @override
  String wrongPlanStarted(String name) {
    return 'Started the four-day drill on \"$name\"';
  }

  @override
  String wrongPlanDay(String name, int day) {
    return '$name · day $day';
  }

  @override
  String wrongPickRedo(int count) {
    return 'Redo $count';
  }

  @override
  String get wrongNone => 'No mistakes yet';

  @override
  String get wrongNoneHint =>
      'Do a set on the practice page — anything you miss lands here, and leaves once you get it right.';

  @override
  String get wrongFilterType => 'Type';

  @override
  String get wrongAllTypes => 'All types';

  @override
  String get wrongFilterReason => 'Reason';

  @override
  String get wrongAllReasons => 'Any reason';

  @override
  String get wrongFilterPaper => 'Paper';

  @override
  String get wrongAllPapers => 'All papers';

  @override
  String get wrongFilterLevel => 'Difficulty';

  @override
  String get wrongAllLevels => 'Any difficulty';

  @override
  String get wrongLevelHard => 'I marked it hard';

  @override
  String get wrongLevelNone => 'Not marked';

  @override
  String get wrongSort => 'Sort';

  @override
  String get wrongSortRecent => 'Most recent first';

  @override
  String get wrongSortMost => 'Most missed first';

  @override
  String wrongFilteredHint(int count) {
    return '$count after filters · long-press any to tag a reason or remove it';
  }

  @override
  String get wrongRedoThis => 'Redo this one';

  @override
  String get wrongAnswerOnly => 'Just the answer and explanation';

  @override
  String get wrongTenMore => 'Ten more of the same type';

  @override
  String get wrongAddToSaved => 'Save it';

  @override
  String get wrongTagReason => 'Tag a reason';

  @override
  String get wrongRemoveFromBook => 'Remove from the mistake book';

  @override
  String get wrongRemoveShort => 'Remove';

  @override
  String wrongCorrectAnswer(String answer) {
    return '  ·  Answer: $answer';
  }

  @override
  String wrongPlanTitle(String name) {
    return '$name · four-day drill';
  }

  @override
  String get wrongPlanDoneToday => 'Today\'s step is done — come back tomorrow';

  @override
  String get wrongPlanGapHint => 'Leave a day between steps or it won\'t stick';

  @override
  String get wrongPlanAgain => 'Run it again';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsLast30 => 'Answered in 30 days';

  @override
  String get statsAvgRate => 'Average accuracy';

  @override
  String get statsActiveDays => 'Days practised';

  @override
  String get statsDaily => 'Per day';

  @override
  String get statsLast30Short => 'Last 30 days';

  @override
  String get statsWeekly => 'By week';

  @override
  String get statsLast8Weeks => 'Last 8 weeks';

  @override
  String get statsAccuracyTrend => 'Accuracy trend';

  @override
  String get statsDaysPractised => 'Days you practised';

  @override
  String get statsScoreTrend => 'Score trend';

  @override
  String get statsAllReports => 'All reports';

  @override
  String get statsReasons => 'Why you miss them';

  @override
  String get statsTagged => 'Tagged';

  @override
  String get statsByType => 'Strong and weak types';

  @override
  String get statsLowToHigh => 'Lowest first';

  @override
  String get statsEmptyTypes =>
      'Do a set and your strong and weak types show up here';

  @override
  String statsDoneCount(int count) {
    return ' $count questions';
  }

  @override
  String statsPeak(int count) {
    return 'Peak $count';
  }

  @override
  String get statsNoRecords => 'No practice recorded yet';

  @override
  String get statsOneMoreDay => 'One more day and a trend appears';

  @override
  String statsFrom(String rate) {
    return 'from $rate';
  }

  @override
  String statsLatest(String rate) {
    return 'latest $rate';
  }

  @override
  String get statsNoScores => 'No scores yet — finish a set of 5 or more';

  @override
  String get statsSameAsLast => 'Same as last time';

  @override
  String statsUpFromLast(int delta) {
    return '+$delta on last time';
  }

  @override
  String statsDownFromLast(int delta) {
    return '$delta on last time';
  }

  @override
  String statsAverage(int rate) {
    return 'average $rate%';
  }

  @override
  String get statsMostlyCareless =>
      'Most of your misses are careless — don\'t add volume; slow down and take each answer back to the question.';

  @override
  String get statsMostlyGaps =>
      'Most of your misses are gaps — go back for the method before drilling the same type.';

  @override
  String get statsMostlyMisread =>
      'Most of your misses are misreads — circle the qualifiers and units as you read.';

  @override
  String get statsMostlyTime =>
      'Most of your misses are time — drill single modules against the clock before whole papers.';

  @override
  String get statsVolume => 'Volume';

  @override
  String statsLatestIs(String kind, int count) {
    return 'Rightmost is the latest ($kind · $count questions) — tap to go through it';
  }

  @override
  String get statsKindMock => 'mock';

  @override
  String get statsKindPractice => 'practice';

  @override
  String get vocabToday => 'Today';

  @override
  String get vocabFrequent => 'Frequent';

  @override
  String get vocabConfusable => 'Easily confused';

  @override
  String get vocabMine => 'Mine';

  @override
  String get vocabMissedThis => 'You\'ve missed this one in a question';

  @override
  String get vocabThinkFirst => 'Try it yourself first, then flip';

  @override
  String get vocabMeaning => 'Meaning';

  @override
  String get vocabUsage => 'How it\'s used';

  @override
  String get vocabDontConfuse => 'Don\'t confuse it with';

  @override
  String get vocabTapToFlip => 'Tap to flip';

  @override
  String get vocabForgot => 'Didn\'t get it';

  @override
  String get vocabGotIt => 'Got it';

  @override
  String get vocabFlip => 'Flip';

  @override
  String get vocabNoneToday => 'Nothing due today';

  @override
  String get vocabDoneToday => 'You\'re through today\'s words';

  @override
  String get vocabAutoCollect =>
      'Words you miss in fill-in-the-blank questions land here automatically';

  @override
  String vocabResult(int right, int total) {
    return '$right of $total · the rest come back tomorrow';
  }

  @override
  String get vocabAgain => 'Another round';

  @override
  String get vocabSearchHint => 'Look up a word';

  @override
  String get vocabNoFreq => 'This bank has no frequency data';

  @override
  String get vocabNeverAsked => 'That word hasn\'t come up';

  @override
  String get vocabNoFreqHint =>
      'Frequencies are counted from fill-in-the-blank options; reinstalling the app rebuilds them.';

  @override
  String get vocabNeverAskedHint =>
      'Try another wording, or it genuinely hasn\'t appeared in a real paper.';

  @override
  String vocabAskedTimes(int count) {
    return 'asked $count times';
  }

  @override
  String vocabAskedTimesLong(int count) {
    return 'Asked $count times in real papers';
  }

  @override
  String get vocabAlreadyAdded => 'Already in your list';

  @override
  String get vocabAdd => 'Add to my list';

  @override
  String get vocabQuestionsWith => 'Questions that use it';

  @override
  String get vocabNoSource => 'No source question in this bank.';

  @override
  String vocabSourceLine(String title, String answer) {
    return '$title · answer $answer';
  }

  @override
  String get vocabNoConfusable => 'No easily-confused pairs yet';

  @override
  String get vocabNoConfusableHint =>
      'Entries in the built-in list that are tagged as easily confused show up here.';

  @override
  String vocabConfusableWith(String words) {
    return 'Confused with: $words';
  }

  @override
  String get vocabEmpty => 'Your word list is empty';

  @override
  String get vocabEmptyHint =>
      'Miss a fill-in-the-blank and the pair is collected automatically; you can also add from Frequent.';

  @override
  String get vocabFromMistakes => 'From mistakes';

  @override
  String get scanNeedAi => 'Set up AI first';

  @override
  String get scanNeedAiBody =>
      'Reading a paper calls a model. Add a key and that\'s it — the questions and images only go to the provider you chose.';

  @override
  String get scanGoSettings => 'Open settings';

  @override
  String get scanNoPages => 'No readable pages in that file';

  @override
  String scanCantOpen(String error) {
    return 'Can\'t open that file: $error';
  }

  @override
  String get scanReading => 'Reading';

  @override
  String get scanReview => 'Review';

  @override
  String get scanPickPdf => 'Pick a PDF';

  @override
  String get scanPickPdfHint => 'A whole paper, read page by page';

  @override
  String get scanPickImages => 'Pick images';

  @override
  String get scanPickImagesHint => 'Photos or screenshots — select several';

  @override
  String get scanPrivacyNote =>
      'Reading uses the model you configured, one call per page. The questions and images never touch our servers.';

  @override
  String scanPageProgress(int done, int total) {
    return '$done of $total pages';
  }

  @override
  String scanPageNo(int n) {
    return 'Page $n';
  }

  @override
  String get scanWaiting => 'Queued';

  @override
  String get scanNoWholeQuestion => 'No complete question';

  @override
  String get commonRetry => 'Retry';

  @override
  String scanMissingAnswers(int count) {
    return '$count have no answer detected — moved to the top';
  }

  @override
  String scanFailedPages(int count) {
    return '$count pages failed';
  }

  @override
  String get scanType => 'Type';

  @override
  String scanTypeSummary(int types, int unknown) {
    return '$types types found, $unknown unclassified';
  }

  @override
  String get scanTypeHint =>
      'Classified one by one — fix them in bulk if wrong';

  @override
  String get scanAsDetected => 'As detected';

  @override
  String get scanViewPage => 'View the page';

  @override
  String get scanNothingSelected => 'Nothing selected';

  @override
  String scanImportSelected(int count) {
    return 'Import $count';
  }

  @override
  String get scanNoAnswer => 'No answer detected';

  @override
  String scanAnswerIs(String answer) {
    return 'Answer $answer';
  }

  @override
  String get scanUnclassified => 'Unclassified';

  @override
  String scanOptionCount(int count) {
    return '$count options';
  }

  @override
  String get scanHasMaterial => 'has a passage';

  @override
  String get scanHasImage => 'has a figure';

  @override
  String docFoundCount(int count) {
    return '$count';
  }

  @override
  String docNoAnswerCount(int count) {
    return ' · $count with no answer';
  }

  @override
  String get docNeedAiKey =>
      'Set up a key under You → AI settings first — parsing needs it';

  @override
  String get docOpening => 'Opening…';

  @override
  String get docNoText =>
      'No text in that file. For scans, use the Photo / PDF route instead.';

  @override
  String get docImportTitle => 'Import a document';

  @override
  String get docImportBody =>
      'Word, Excel, CSV or plain text. AI reads it once and picks out the question, options, answer and explanation — for any exam, not just one.';

  @override
  String get docWhichExam => 'Which exam is this (optional)';

  @override
  String get docWhichExamHint => 'e.g. a subject or paper name';

  @override
  String get docWhichExamNote =>
      'Filling this in helps AI classify more accurately';

  @override
  String get docPickFile => 'Choose a file';

  @override
  String get docPickAnother => 'Choose another';

  @override
  String get docFound => 'What it found';

  @override
  String get docNoAnswerHint =>
      'Questions without an answer can\'t be practised — usually the source document lists answers somewhere else. Save them and fill the answers in yourself, or use a copy that has them.';

  @override
  String docMoreHidden(int count) {
    return '$count more — save them and you\'ll see the rest';
  }

  @override
  String docSaveCount(int count) {
    return 'Save $count to the bank';
  }

  @override
  String get docNoAnswer => 'No answer';

  @override
  String get docHasAnalysis => 'has an explanation';

  @override
  String get essayNeedAi => 'Set up AI first';

  @override
  String get essayNeedAiBody => 'Reading a photo needs AI — add an API key?';

  @override
  String get commonLater => 'Later';

  @override
  String get essayScanFailed => 'Couldn\'t read it';

  @override
  String get essayScanDone =>
      'Read it — check the source text for missing paragraphs';

  @override
  String get essayNeedFields =>
      'Title, source text and the task are all needed for AI to mark it well';

  @override
  String get essayNewTitle => 'New essay question';

  @override
  String get essayEditTitle => 'Edit question';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get essayScanning => 'Reading — long text takes a moment…';

  @override
  String get essayScanHint => 'Photograph or pick an image and let AI read it';

  @override
  String get essayScanCheck =>
      'Check the source text afterwards — a missing paragraph means a blind spot in the marking.';

  @override
  String get essayType => 'Type';

  @override
  String get essayTitleField => 'Title';

  @override
  String get essayProvince => 'Region';

  @override
  String get essayYear => 'Year';

  @override
  String get essayWordLimit => 'Word limit';

  @override
  String get essaySuggestedMinutes => 'Suggested time (minutes)';

  @override
  String get essaySource => 'Source text';

  @override
  String get essayTask => 'The task';

  @override
  String get essayReference =>
      'Model answer and mark scheme (optional — improves marking)';

  @override
  String get essayModelAnswer => 'Model answer';

  @override
  String get essayModelAnswerHint =>
      'Paste the official answer if you have one';

  @override
  String get essayMarkPoints => 'Mark scheme, one point per line';

  @override
  String get essayTitleHint => 'e.g. 2025 paper, question 1';

  @override
  String get essaySourceHint => 'Source 1…\nSource 2…';

  @override
  String get essayTaskHint =>
      'Using the sources, summarise… Be complete, accurate and well organised; no more than 200 words.';

  @override
  String get essayMarkPointsHint => 'First point\nSecond point\nThird point';

  @override
  String importMissingImages(int count) {
    return '$count images referenced but missing from the zip — those questions will show a missing-figure placeholder';
  }

  @override
  String get importedPaperTitle => 'Imported';

  @override
  String paperYearPrefix(String year) {
    return '$year · ';
  }

  @override
  String paperDoneSuffix(int done, int rate) {
    return ' · $done done · $rate% correct';
  }

  @override
  String get paperNoQuestions => 'No questions here';

  @override
  String paperSkim(String title) {
    return 'Skim · $title';
  }

  @override
  String get paperHistory => 'This paper\'s history';

  @override
  String get paperHistoryShort => 'History';

  @override
  String get paperFullMock => 'Full mock';

  @override
  String get paperMockMinutes => '120 minutes';

  @override
  String get paperResume => 'Continue';

  @override
  String get paperAllDone => 'All done';

  @override
  String get paperWrong => 'Mistakes in this paper';

  @override
  String get commonNone => 'None';

  @override
  String get paperSkimAnswers => 'Skim the answers';

  @override
  String get paperAllAnalysis => 'Explanations for the whole paper';

  @override
  String get paperModules => 'What\'s in it';

  @override
  String get paperModulesHint => 'Tap a row to practise just that part';

  @override
  String paperModuleYear(String name, String year) {
    return '$name · $year';
  }

  @override
  String get paperNoTypes =>
      'No questions in this paper — usually means the import had no type labels';

  @override
  String get paperTipModules =>
      'Practise module by module first; take the whole paper against the clock once the types are familiar.';

  @override
  String get paperTipMock =>
      'The full mock runs 120 minutes; use the answer sheet to jump around.';

  @override
  String get healthCleanAll => 'Clean up every duplicate';

  @override
  String healthCleanAllBody(int groups, int removed) {
    return '$groups duplicate groups within papers; one is kept from each and $removed are deleted.';
  }

  @override
  String get healthClean => 'Clean up';

  @override
  String get healthTitle => 'Bank check-up';

  @override
  String get healthAllGood => 'Nothing wrong found';

  @override
  String get healthEmptyBody =>
      'Import questions and this page tells you which ones are broken.';

  @override
  String get healthAllGoodBody =>
      'Every question has an answer and options, and no paper collected the same one twice.';

  @override
  String get healthNoAnswer => 'No answer';

  @override
  String healthNoAnswerCount(int count) {
    return '$count · answering these can\'t be marked right or wrong';
  }

  @override
  String get healthFillAnswer => 'Fill the answer in';

  @override
  String get healthBrokenOptions => 'Broken options';

  @override
  String healthBrokenCount(int count) {
    return '$count · fewer than two options, usually a parsing failure';
  }

  @override
  String get healthDupes => 'Duplicates';

  @override
  String healthDupesCount(int count) {
    return '$count groups · collected twice within one paper';
  }

  @override
  String get healthCleanAllShort => 'Clean all';

  @override
  String healthCopies(int count) {
    return '$count copies';
  }

  @override
  String get healthKeepOne => 'Keep one';

  @override
  String get healthByCategory => 'How many in each';

  @override
  String get healthUnitQuestions => 'questions';

  @override
  String get healthUnitCategories => 'categories';

  @override
  String get healthUnitProblems => 'to fix';

  @override
  String healthMore(int count) {
    return '$count more — fix these and refresh';
  }

  @override
  String get healthEmptyStem => '(empty question)';

  @override
  String get healthDelete => 'Delete it';

  @override
  String get healthWhichAnswer => 'Which one is correct';

  @override
  String get healthWhichAnswerHint =>
      'Pick the wrong one and it\'s fine — you can change it later while practising.';

  @override
  String get bankAllShort => 'All';

  @override
  String reportsTodayAt(String time) {
    return 'Today $time';
  }

  @override
  String reportsMinSec(int m, int s) {
    return '${m}m ${s}s';
  }

  @override
  String reportsSec(int s) {
    return '${s}s';
  }

  @override
  String reportsResume(String when, int n) {
    return '$when · stopped at question $n · tap to carry on';
  }

  @override
  String reportsScoreLine(
    String when,
    int correct,
    int total,
    String duration,
  ) {
    return '$when · $correct/$total correct · $duration';
  }

  @override
  String reportsPlainLine(String when, String duration) {
    return '$when · $duration';
  }

  @override
  String get reportsEssayHint =>
      'Essay records: see the marking on the essay page';

  @override
  String get reportsVocabHint => 'Word sessions have no questions to review';

  @override
  String get reportsNeedTwo => 'You need at least two reports to compare';

  @override
  String get reportsTitle => 'Practice history';

  @override
  String get reportsNone => 'No reports yet';

  @override
  String get reportsNoneHint =>
      'Practice sets, mocks and word sessions all get recorded here.';

  @override
  String get reportsKindVocab => 'words';

  @override
  String get reportsUnfinished => 'Unfinished';

  @override
  String reportsSeeWrong(int count) {
    return 'See those $count mistakes';
  }

  @override
  String get reportsDiagnose => 'Diagnose this paper';

  @override
  String get reportsCompareWith => 'Compare with';

  @override
  String get reportsCompare => 'Side by side';

  @override
  String get reportsLevel => 'level';

  @override
  String get reportsCompareNote =>
      'Different questions — this compares accuracy per module, not the same set.';

  @override
  String get notesReview => 'Note review';

  @override
  String get notesTitle => 'My notes';

  @override
  String get notesWriteOne => 'Write one';

  @override
  String get notesReviewAll => 'Review all';

  @override
  String get notesNone => 'No notes yet';

  @override
  String get notesNoneHint =>
      'Tap the note icon while practising to jot down what you learned on a question; for anything not tied to a question, write one below.';

  @override
  String get notesSearchHint => 'Search notes or questions';

  @override
  String get notesNoMatch => 'No notes match';

  @override
  String get notesNoMatchHint =>
      'Try another keyword, or clear the type filter.';

  @override
  String get notesDelete => 'Delete note';

  @override
  String get notesQuick => 'Quick note';

  @override
  String get notesTitleField => 'Title (optional)';

  @override
  String get notesTitleHint => 'Left blank, the first line is used';

  @override
  String get notesBody => 'Body';

  @override
  String get notesBodyHint => 'A formula, a trap, what this mock taught you…';

  @override
  String get usageClear => 'Clear usage history';

  @override
  String get usageClearBody =>
      'Clears these numbers only — explanations already generated and questions already imported stay.';

  @override
  String get usageClearShort => 'Clear';

  @override
  String get usageTitle => 'AI usage';

  @override
  String usageLastDays(int days) {
    return 'Last $days days';
  }

  @override
  String get usageNone => 'No usage yet';

  @override
  String get usageNoneHint =>
      'Explaining questions, parsing imports and marking essays all get logged here.';

  @override
  String get usageWhere => 'Where it goes';

  @override
  String get usageByTokens => 'Most tokens first';

  @override
  String get usageByModel => 'By model';

  @override
  String get usageUnrecorded => 'Not recorded';

  @override
  String get usageTokenNote =>
      'Token counts come from the model, and providers count slightly differently. Use these to compare sizes — your bill may differ a little.';

  @override
  String get usageFeatureExplain => 'Explaining questions';

  @override
  String get usageFeatureDoc => 'Document import';

  @override
  String get usageFeatureScan => 'Photo / PDF reading';

  @override
  String get usageFeatureEssay => 'Essay marking';

  @override
  String get usageFeatureImage => 'Image reading';

  @override
  String get usageFeatureSort => 'Category sorting';

  @override
  String get usageFeatureOther => 'Other';

  @override
  String usageCalls(int count) {
    return '$count calls';
  }

  @override
  String get usageLast14 => 'Last 14 days';

  @override
  String usageGroupLine(int calls, String inTok, String outTok) {
    return '$calls calls · in $inTok · out $outTok';
  }

  @override
  String get explainTitle => 'From the examiner\'s side';

  @override
  String get explainRedo => 'Explain again';

  @override
  String get explainWorking => 'Working on this one';

  @override
  String get explainPitch =>
      'Have AI walk through it the way the examiner built it: what\'s being tested, how the distractors were set, and where you went wrong.';

  @override
  String get explainAsk => 'Explain this one';

  @override
  String get explainBackground =>
      'Go do something else — it keeps going and you can come back';

  @override
  String explainStamp(String stamp) {
    return 'AI · $stamp';
  }

  @override
  String searchFoundCount(int count) {
    return '$count found';
  }

  @override
  String get searchFilteredSuffix => ' · filtered by type';

  @override
  String searchYearSuffix(String year) {
    return ' · $year';
  }

  @override
  String get searchHasFigure => ' · has a figure';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchPractiseThese => 'Practise these';

  @override
  String get searchHint => 'Search questions and explanations';

  @override
  String searchAllCount(int count) {
    return 'All $count';
  }

  @override
  String get searchTop60 => 'Showing the first 60';

  @override
  String get searchNoMatch => 'No questions match';

  @override
  String get searchShorterHint => 'Try a shorter keyword.';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchTryThese => 'Try these';

  @override
  String get searchNote =>
      'Search scans every question and explanation in the bank; matches are highlighted in the results.';

  @override
  String get toolVocabCompare => 'Compare words';

  @override
  String get toolVocabCompareHint =>
      'Easily-confused pairs only separate when you see them side by side';

  @override
  String get toolVocabTop => 'Most frequent';

  @override
  String get toolVocabTopHint =>
      'Counted from the options of every fill-in-the-blank question in your bank';

  @override
  String get toolVocabToday => 'Today\'s cards';

  @override
  String get toolVocabTodayHint => 'Spaced repetition — what\'s due today';

  @override
  String get toolVocabMine => 'Your words';

  @override
  String get toolVocabMineHint =>
      'Missed words land here; you can add your own too';

  @override
  String get toolVocabLookup => 'Look up a word';

  @override
  String get toolVocabLookupHint =>
      'See how a word is actually used in real papers';

  @override
  String get toolTips => 'Method';

  @override
  String get toolTipsHint => 'Per-module methods to check when you\'re stuck';

  @override
  String get toolCheckin => 'Daily list';

  @override
  String get toolCheckinHint => 'Today\'s plan — tick it off';

  @override
  String get toolSearch => 'Search the bank';

  @override
  String get toolSearchHint => 'Find any question by keyword';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get searchNoResults => 'Nothing found';

  @override
  String importedCount(int count) {
    return 'Imported $count questions';
  }

  @override
  String importedImages(int count) {
    return ' and $count images';
  }

  @override
  String importedOverwritten(int count) {
    return ' ($count of them overwritten)';
  }

  @override
  String get importedNothing => 'Nothing was imported this time';

  @override
  String get importFormatTitle => 'What a question file looks like';

  @override
  String get importParsed => 'What was parsed';

  @override
  String get importQuestions => 'Questions';

  @override
  String get importImages => 'Images';

  @override
  String get importOverwrites => 'Overwrites';

  @override
  String get importConfirm => 'Import them';

  @override
  String get aiSaved => 'Saved';

  @override
  String aiCantOpenBrowser(String url) {
    return 'Can\'t open a browser — URL copied: $url';
  }

  @override
  String get aiPickProvider => 'Pick a provider';

  @override
  String get aiEnterKey => 'Enter a key';

  @override
  String aiGetKeyAt(String where) {
    return 'Get one at $where';
  }

  @override
  String get aiWhichModel => 'Which model';

  @override
  String get aiModelHint => 'The model name — ask your provider';

  @override
  String get aiBaseUrl => 'Endpoint';

  @override
  String aiBaseUrlSet(String url) {
    return 'Endpoint already set: $url';
  }

  @override
  String get aiTesting => 'Testing…';

  @override
  String get aiTest => 'Test the connection';

  @override
  String get aiKeyPrivacy =>
      'The key stays on this phone. Requests go straight to the provider you picked and never touch our servers.';

  @override
  String get aiPaste => 'Paste';

  @override
  String get aiHide => 'Hide';

  @override
  String get aiShow => 'Show';

  @override
  String get aiFree => 'Free';

  @override
  String get essayDeletePrompt => 'Delete this question?';

  @override
  String essayDeleteBody(String title) {
    return '\"$title\" and everything you wrote for it go together.';
  }

  @override
  String get essayAddPrompt => 'Add a question';

  @override
  String get essayNoneOfType => 'Nothing of this type yet';

  @override
  String get essayNone => 'No essay questions yet';

  @override
  String get essayNoneOfTypeHint => 'Try another type, or add one.';

  @override
  String get essayNoneHint =>
      'Essay questions have to be added by you.\nPhotograph one and let AI read it, or paste the source text and the task.';

  @override
  String get essayAddFirst => 'Add the first one';

  @override
  String get essayQuit => 'Leave this answer?';

  @override
  String get essayQuitBody =>
      'You haven\'t submitted — what you wrote will be lost.';

  @override
  String get essayKeepWriting => 'Keep writing';

  @override
  String get essayTooShort =>
      'Write at least a little more before submitting — there\'s nothing to mark yet';

  @override
  String get essayNeedAiMark =>
      'Marking needs AI — add an API key? Your answer is saved either way.';

  @override
  String get essayMarkFailed => 'Marking failed';

  @override
  String get essayWriteHint =>
      'Write here. For summaries, split into points first, then lead each one with its key word.';

  @override
  String get essayMarking => 'AI is marking, about 20 seconds…';

  @override
  String get essaySubmitMark => 'Submit for marking';

  @override
  String get essayAttempts => 'Your answers';

  @override
  String get essayNotMarked =>
      'This one wasn\'t marked, but your answer is saved.';

  @override
  String get essayResult => 'Marking';

  @override
  String get essayPointsCovered => 'Points covered';

  @override
  String get essayWordCount => 'Words';

  @override
  String get essayTimeTaken => 'Time';

  @override
  String get essayBreakdown => 'Breakdown';

  @override
  String get essayPointByPoint => 'Point by point';

  @override
  String essayMissedPoints(int count) {
    return '$count missed';
  }

  @override
  String get essayNextTime => 'Next time';

  @override
  String get essayYourAnswer => 'Your answer';

  @override
  String essayEvidence(String text) {
    return 'Source: $text';
  }

  @override
  String essayWords(int n) {
    return '$n words';
  }

  @override
  String essayWordsOfLimit(int n, int limit) {
    return '$n / $limit words';
  }

  @override
  String get essayOverLimit => ' · over';

  @override
  String essayOutOf(String max) {
    return 'out of $max';
  }

  @override
  String planDoneToday(String name) {
    return '\"$name\" is done for today';
  }

  @override
  String planDayPending(String name, int day) {
    return '\"$name\" day $day still to do';
  }

  @override
  String get tabPractice => 'Practice';

  @override
  String get tabPlan => 'Plan';

  @override
  String get navExpand => 'Expand navigation';

  @override
  String get navCollapse => 'Collapse navigation';

  @override
  String shoreStreak(int days) {
    return 'Lighthouse lit for $days days';
  }

  @override
  String backupExportedTo(String name) {
    return 'Exported to $name';
  }

  @override
  String get backupRestore => 'Restore a backup';

  @override
  String get backupRestoreBody =>
      'Restoring overwrites your answers and score reports with the ones in the backup; bookmarks, notes and mistake tags are merged, and the study plan and exam date are written back from the backup. The question bank itself is untouched.';

  @override
  String get backupPickFile => 'Choose a file';

  @override
  String get backupUnreadable => 'Can\'t read that file';

  @override
  String get backupNotOurs => 'That isn\'t an OpenExam backup';

  @override
  String backupRestored(int count) {
    return 'Restored $count records';
  }

  @override
  String backupRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get backupIntro =>
      'There are no accounts here — your data lives on this device. Export a backup before switching phones or clearing data and it all comes with you.';

  @override
  String get backupAnswers => 'Answers';

  @override
  String get backupReports => 'Score reports';

  @override
  String get backupExport => 'Export a backup';

  @override
  String get backupExportHint =>
      'Writes a JSON file with your answers, score reports, bookmarks, notes and mistake tags';

  @override
  String get backupFromFile => 'Restore from a backup';

  @override
  String get backupFromFileHint =>
      'Answers and score reports are overwritten; bookmarks, notes and mistake tags are merged';

  @override
  String get backupSizeNote =>
      'The backup holds no questions, only your own data, so it stays small enough to send or drop in cloud storage.';

  @override
  String get aiNotConfigured =>
      'AI isn\'t set up yet — add it under You → AI settings';

  @override
  String aiNoVision(String provider) {
    return '$provider can\'t read images — switch to a vision model';
  }

  @override
  String get aiUnparsable => 'The model returned nothing usable — try again';

  @override
  String get aiNoKey => 'No API key yet';

  @override
  String get aiNoBaseUrl => 'No endpoint yet';

  @override
  String aiConnOk(String model) {
    return 'Connected · $model';
  }

  @override
  String get aiTimeout =>
      'The request timed out — check your connection or try another endpoint';

  @override
  String aiRequestFailed(String error) {
    return 'Request failed: $error';
  }

  @override
  String get aiNoContent =>
      'The model produced no text. Usually this is a reasoning model spending its whole budget on thinking — switch to a non-reasoning model, or try again later.';

  @override
  String aiBadKey(int status, String detail) {
    return 'Wrong API key or no permission ($status): $detail';
  }

  @override
  String aiNotFound(String detail) {
    return 'Wrong endpoint or model name (404): $detail';
  }

  @override
  String aiRateLimited(String detail) {
    return 'Too many requests or out of credit (429): $detail';
  }

  @override
  String aiServerError(int status, String detail) {
    return 'Server returned $status: $detail';
  }

  @override
  String get tipsTitle => 'Method';

  @override
  String get tipsUnitQuestions => 'questions';

  @override
  String get tipsPaperNumbers => 'on the paper';

  @override
  String get tipsUnitMinutes => 'minutes';

  @override
  String get tipsWhereOnPaper => 'Where it sits';

  @override
  String get tipsYear2026 => '2026';

  @override
  String tipsQuestionRange(int from, int to) {
    return 'Q$from–$to';
  }

  @override
  String tipsTotalAndMinutes(int count, int minutes) {
    return '$count Qs · $minutes min';
  }

  @override
  String get tipsBreakdownPace => 'Breakdown · pace per question';

  @override
  String get tipsBreakdown => 'Breakdown';

  @override
  String get tipsHotspots => 'Common topics';

  @override
  String get tipsHotspotsHint => 'Ordered by how often they appear';

  @override
  String get tipsHotspotsNote =>
      'Rough keyword matching — one question can count towards several topics. Read the relative weight, not an exact share.';

  @override
  String get tipsInExam => 'What to do in the exam';

  @override
  String get tipsMethods => 'Methods';

  @override
  String tipsMethodCount(int count) {
    return '$count';
  }

  @override
  String get examNewProfile => 'New study profile';

  @override
  String get examNewProfileHint => 'e.g. a certification or subject';

  @override
  String get examRename => 'Rename';

  @override
  String get examDeleteProfile => 'Delete study profile';

  @override
  String examDeleteProfileBody(String name) {
    return 'Deletes \"$name\". The bank, your mistakes and your history are untouched.';
  }

  @override
  String get examWhichModules => 'Which modules to show';

  @override
  String get examWhichExam => 'Which exam are you studying for';

  @override
  String get examModulesNote =>
      'These modules were built for one specific exam. Studying for something else, turn them off and they stop appearing.';

  @override
  String get examGenericOnly => 'Common modules only';

  @override
  String examExtrasOn(int count) {
    return '$count extra modules on';
  }

  @override
  String get examSharedBank =>
      'The bank is shared. Switching profiles just changes the glasses — questions, mistakes and history all stay put.';

  @override
  String get examTwoProfiles =>
      'Studying for two exams at once? Tap ＋ and keep a separate set of modules for each.';

  @override
  String sessionHistoryPicked(String when, String answer) {
    return '$when you picked $answer';
  }

  @override
  String get sessionHistoryRight => ' — correct';

  @override
  String get sessionHistoryWrong => ' — wrong';

  @override
  String sessionHistoryMissedN(int count) {
    return ' · missed $count times in all';
  }

  @override
  String sessionHistoryWasRight(String when) {
    return '$when you got this right';
  }

  @override
  String sessionHistoryWasWrong(String when) {
    return '$when you missed this one';
  }

  @override
  String sessionAvgSeconds(String secs) {
    return '${secs}s per question';
  }

  @override
  String sessionYourAnswer(String yours, String right) {
    return 'You: $yours · answer: $right';
  }

  @override
  String get sessionBlankAnswer => 'blank';

  @override
  String sessionDoneTimes(int count) {
    return 'done $count times';
  }

  @override
  String sessionMissedN(int count) {
    return ' · missed $count';
  }

  @override
  String get sessionAllRight => ' · all correct';

  @override
  String sessionLastOn(String date) {
    return ' · last on $date';
  }

  @override
  String get sessionNoteExample =>
      'e.g. when you see \"at least\", think worst case first';

  @override
  String sessionYearSuffix(String year) {
    return ' · $year';
  }

  @override
  String minutesCount(int count) {
    return '$count minutes';
  }

  @override
  String get featEssay => 'Essay / written answers';

  @override
  String get featEssayHint => 'Writing plus AI marking';

  @override
  String get featVocab => 'Words';

  @override
  String get featVocabHint => 'Cards, comparisons, your own list';

  @override
  String get featTips => 'Method';

  @override
  String get featTipsHint => 'Per-module approaches';

  @override
  String get featProvinces => 'Region';

  @override
  String get featProvincesHint => 'Filter papers by region';

  @override
  String get examMyProfile => 'My studies';

  @override
  String get yearAll => 'Any year';

  @override
  String get yearLast1 => 'Most recent year';

  @override
  String get yearLast3 => 'Last three years';

  @override
  String get planStep1 => 'Slow and correct';

  @override
  String get planStep2 => 'Again';

  @override
  String get planStep3 => 'Against the clock';

  @override
  String get planStep4 => 'Mixed check';

  @override
  String get planStep1Hint =>
      'No timer — walk the right reasoning through each one';

  @override
  String get planStep2Hint =>
      'Still no timer — focus on where you stuck yesterday';

  @override
  String get planStep3Hint => 'Exam pace — force a decision inside the time';

  @override
  String get planStep4Hint =>
      'Mix in fresh questions of the same type to check it stuck';

  @override
  String get memoUntitled => 'Untitled';

  @override
  String get examGongkaoName => 'Civil service exam';

  @override
  String get marksTitle => 'Saved';

  @override
  String get marksPractise => 'Practise a set';

  @override
  String get marksNone => 'Nothing saved yet';

  @override
  String get marksNoneHint =>
      'Tap the star while practising and the question lands here.';

  @override
  String get marksUnsave => 'Unsave';

  @override
  String get marksAddTag => '+ tag';

  @override
  String get marksTags => 'Tags';

  @override
  String get marksClearTag => 'Clear tag';

  @override
  String get onboardThreeThings => 'Three quick things';

  @override
  String get onboardChangeLater => 'All changeable later, under You';

  @override
  String get onboardDailyGoal => 'How many a day';

  @override
  String get onboardWhere => 'Where are you sitting it';

  @override
  String get onboardWhereHint => 'Papers from your region get surfaced first';

  @override
  String get onboardWhen => 'When is the exam';

  @override
  String get onboardOptional => 'Optional';

  @override
  String onboardDaysLeft(int days) {
    return ' · $days days away';
  }

  @override
  String get recentTitle => 'Recently practised';

  @override
  String get recentHistory => 'History';

  @override
  String get recentNone => 'No whole papers yet';

  @override
  String get recentNoneHint =>
      'Pick a paper in the bank and this keeps track of where you got to.';

  @override
  String recentFinished(int count) {
    return 'Finished all $count';
  }

  @override
  String recentProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get timelineTitle => 'Practice log';

  @override
  String get timelineNoneHint =>
      'Finish your first set and this logs what you did, day by day.';

  @override
  String timelineDayLine(int count, int rate) {
    return '$count questions · $rate% correct';
  }

  @override
  String get timelineMetGoal => 'goal met';

  @override
  String get feedbackReview => 'Reported errors';

  @override
  String get feedbackTitle => 'Reported errors';

  @override
  String get feedbackNone => 'Nothing reported yet';

  @override
  String get feedbackNoneHint =>
      'Long-press the question number while practising to flag a wrong answer or an unclear explanation.';

  @override
  String get feedbackIssue => 'Issue';

  @override
  String get feedbackNote =>
      'These stay on this device and travel with your backups. Swipe left to delete.';

  @override
  String get padThin => 'Thin';

  @override
  String get padMedium => 'Medium';

  @override
  String get padThick => 'Thick';

  @override
  String get padScratch => 'Scratchpad';

  @override
  String get padCalculator => 'Calculator';

  @override
  String get padHere => 'Work it out here';

  @override
  String get padCantCompute => 'Can\'t compute';

  @override
  String homeMockMeta(int count, int minutes) {
    return '$count questions · $minutes min';
  }

  @override
  String shoreLeftToday(int count) {
    return '$count left today';
  }

  @override
  String get shoreNotStarted => 'Not under way';

  @override
  String essayUnderWords(int n) {
    return 'under $n words';
  }

  @override
  String essayAttemptedTimes(int count) {
    return 'attempted $count times';
  }

  @override
  String get essayNeverAttempted => 'never attempted';

  @override
  String get imageMissing => 'Image missing';

  @override
  String get imagePinchHint => 'Pinch to zoom · tap to close';

  @override
  String get filterClear => 'Clear';

  @override
  String get filterSearch => 'Search';

  @override
  String get docNoContent => 'Nothing readable in that file';

  @override
  String get docLookingAtTable => 'Working out how the table is laid out…';

  @override
  String get docUnknownColumns =>
      'Couldn\'t identify the columns — try another file';

  @override
  String docFoundQuestions(int count) {
    return 'Found $count questions';
  }

  @override
  String get docNoneInTable => 'No questions in that table';

  @override
  String docChunk(int n, int total) {
    return 'Section $n of $total';
  }

  @override
  String get docNoWholeQuestions => 'No complete questions found';

  @override
  String get modelCheapFast => 'Cheap and quick, fine day to day';

  @override
  String get modelStrong => 'Steadier on hard questions and long marking';

  @override
  String get modelCheapVision => 'Cheap, reads images';

  @override
  String get modelStrongerPricier => 'Stronger, costs more';

  @override
  String get modelBestWriting => 'Steadiest for writing and marking';

  @override
  String get modelFast => 'Fast';

  @override
  String get modelGeneral => 'General';

  @override
  String get modelShortText => 'Short text';

  @override
  String get modelLongText => 'Long text';

  @override
  String get modelVision => 'Reads images';

  @override
  String get modelFreeTier => 'Works on the free tier';

  @override
  String get modelStronger => 'Stronger';

  @override
  String get providerCustom => 'Custom';

  @override
  String get providerCustomHint =>
      'Any OpenAI-compatible endpoint; include /v1 in the URL';

  @override
  String get dxAiNotConfiguredShort =>
      'No AI configured. The conclusions above stand on their own; AI just adds a layer.';

  @override
  String get aiEmptyReply => 'The model returned nothing — try again';

  @override
  String get modelNote_cheapFast => 'Cheap and quick, fine day to day';

  @override
  String get modelNote_strong => 'Steadier on hard questions and long marking';

  @override
  String get modelNote_cheapVision => 'Cheap, reads images';

  @override
  String get modelNote_strongerPricier => 'Stronger, costs more';

  @override
  String get modelNote_bestWriting => 'Steadiest for writing and marking';

  @override
  String get modelNote_fast => 'Fast';

  @override
  String get modelNote_general => 'General';

  @override
  String get modelNote_shortText => 'Short text';

  @override
  String get modelNote_longText => 'Long text';

  @override
  String get modelNote_vision => 'Reads images';

  @override
  String get modelNote_freeTier => 'Works on the free tier';

  @override
  String get modelNote_stronger => 'Stronger';

  @override
  String wrongExportYear(int year) {
    return '$year';
  }

  @override
  String wrongExportAnswer(String answer) {
    return '**Answer: $answer**';
  }

  @override
  String wrongExportReason(String reason) {
    return '**Why wrong: $reason**';
  }

  @override
  String wrongExportTimes(int times) {
    return '**Missed $times times**';
  }

  @override
  String get wrongExportFilePrefix => 'openexam-wrong-';

  @override
  String wrongPlanDayStep(int day, String title) {
    return 'Day $day · $title';
  }

  @override
  String markedUncategorized(int count) {
    return 'Untagged $count';
  }

  @override
  String get planSetDefaultName => 'My plan';

  @override
  String get importSampleTitle => 'Civil Service 2026';

  @override
  String get importSampleContent => 'Question stem';

  @override
  String get importSampleMaterial => 'Shared passage, omit if none';

  @override
  String get importSampleOptA => 'First';

  @override
  String get importSampleOptB => 'Second';

  @override
  String get importSampleAnalysis => 'Explanation';

  @override
  String get planTaskDaily => 'Daily set';

  @override
  String get planTaskWrong => 'Wrong-answer review';

  @override
  String planTaskTimed(String category) {
    return '$category · timed';
  }

  @override
  String get noBankLead => 'The bank you install decides the exam.';

  @override
  String get noBankFeatPractice => 'Practice by module';

  @override
  String get noBankFeatMock => 'Timed mocks';

  @override
  String get noBankFeatWrong => 'Mistakes collected for you';

  @override
  String get noBankFeatDiagnose => 'Pace and accuracy diagnostics';

  @override
  String get noBankOffline => 'Offline, no account';
}
