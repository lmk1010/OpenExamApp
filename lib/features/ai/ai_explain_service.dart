import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';

/// 一道题的讲解现在处在什么状态。
class AiExplainState {
  const AiExplainState({
    this.text = '',
    this.streaming = false,
    this.error,
    this.stamp,
  });

  /// 已经吐出来的部分。生成中它会一点点变长。
  final String text;
  final bool streaming;
  final String? error;

  /// 落款：模型名 + 时间。生成完才有。
  final String? stamp;

  bool get isEmpty => text.isEmpty && !streaming && error == null;
}

/// 讲解的生成放在页面之外。
///
/// 讲一道题要几十秒，而用户十有八九会切出去看别的、或者干脆锁屏。请求挂在
/// 页面的 State 上，一 dispose 就断，回来还得从头再来一遍 —— 既白等也白花钱。
/// 所以请求归这里管，页面只是订阅；切走再回来，接着看就是了。
class AiExplainService {
  AiExplainService._();
  static final instance = AiExplainService._();

  final _states = <String, ValueNotifier<AiExplainState>>{};
  final _running = <String, StreamSubscription<String>>{};

  /// 订阅某道题的讲解状态。页面 build 时拿它挂 ValueListenableBuilder。
  ValueNotifier<AiExplainState> stateOf(String questionId) =>
      _states.putIfAbsent(questionId, () => ValueNotifier(const AiExplainState()));

  bool isStreaming(String questionId) => _running.containsKey(questionId);

  /// 把库里存过的读出来填进状态。已经在生成的就别去动它。
  Future<void> hydrate(String questionId) async {
    if (_running.containsKey(questionId)) return;
    final notifier = stateOf(questionId);
    if (notifier.value.text.isNotEmpty) return;
    final saved = await AppDatabase.instance.aiExplanation(questionId);
    if (saved == null) return;
    if (_running.containsKey(questionId)) return;
    notifier.value = AiExplainState(text: saved.body, stamp: saved.stamp);
  }

  /// 开讲。已经在讲的直接返回，不重复发请求。
  Future<void> start({
    required Question question,
    String? userAnswer,
    required String system,
    required String prompt,
    required AppL l,
  }) async {
    final id = question.id;
    if (_running.containsKey(id)) return;

    final notifier = stateOf(id);
    notifier.value = const AiExplainState(streaming: true);

    final settings = await AiSettingsStore.load();
    AiClient.feature = 'explain';
    final buffer = StringBuffer();

    final sub = AiClient(settings, l)
        // 1200 只够讲解正文，不够推理模型先"想"一轮 —— 想的部分同样从
        // max_tokens 里扣，扣光了就吐不出正文。跟弱点诊断那边同一个坑。
        .completeStream(system: system, prompt: prompt, maxTokens: 8000)
        .listen(
      (delta) {
        buffer.write(delta);
        notifier.value = AiExplainState(
          text: buffer.toString(),
          streaming: true,
        );
      },
      onError: (Object error) {
        _running.remove(id);
        notifier.value = AiExplainState(
          text: buffer.toString(),
          error: error is AiException ? error.message : '$error',
        );
      },
      onDone: () async {
        _running.remove(id);
        final body = buffer.toString().trim();
        if (body.isEmpty) {
          notifier.value = AiExplainState(error: l.aiEmptyReply);
          return;
        }
        await AppDatabase.instance.saveAiExplanation(
          id,
          body,
          model: settings.effectiveModel,
        );
        final saved = await AppDatabase.instance.aiExplanation(id);
        notifier.value = AiExplainState(text: body, stamp: saved?.stamp);
      },
      cancelOnError: true,
    );
    _running[id] = sub;
  }

  /// 重讲：清掉存的那份，从头再来。
  Future<void> regenerate({
    required Question question,
    String? userAnswer,
    required String system,
    required String prompt,
    required AppL l,
  }) async {
    final id = question.id;
    await _running.remove(id)?.cancel();
    await AppDatabase.instance.deleteAiExplanation(id);
    stateOf(id).value = const AiExplainState();
    await start(
      question: question,
      userAnswer: userAnswer,
      system: system,
      prompt: prompt,
      l: l,
    );
  }
}
