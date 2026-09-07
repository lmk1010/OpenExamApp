import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/diagnosis/diagnosis.dart';

class AiDiagnosisState {
  const AiDiagnosisState({
    this.text = '',
    this.streaming = false,
    this.error,
    this.stamp,
  });

  final String text;
  final bool streaming;
  final String? error;

  /// 落款：模型名 + 时间。
  final String? stamp;

  bool get isEmpty => text.isEmpty && !streaming && error == null;
}

/// AI 那一层的诊断。跟讲解一样放在页面之外 —— 生成要几十秒，用户十有八九
/// 会切出去，请求挂在 State 上一 dispose 就断，回来还得重花一次钱。
///
/// [key] 是诊断对象：整段历史是 `history`，单次成卷是 `report:<id>`。
class AiDiagnosisService {
  AiDiagnosisService._();
  static final instance = AiDiagnosisService._();

  final _states = <String, ValueNotifier<AiDiagnosisState>>{};
  final _running = <String, StreamSubscription<String>>{};

  ValueNotifier<AiDiagnosisState> stateOf(String key) =>
      _states.putIfAbsent(key, () => ValueNotifier(const AiDiagnosisState()));

  bool isStreaming(String key) => _running.containsKey(key);

  /// 把存过的读出来。已经在生成的别去动。
  Future<void> hydrate(String key) async {
    if (_running.containsKey(key)) return;
    final notifier = stateOf(key);
    if (notifier.value.text.isNotEmpty) return;
    final saved = await AppDatabase.instance.aiDiagnosis(key);
    if (saved == null || _running.containsKey(key)) return;
    notifier.value = AiDiagnosisState(text: saved.body, stamp: saved.stamp);
  }

  Future<void> start(String key, Diagnosis diagnosis, AppL l) async {
    if (_running.containsKey(key)) return;
    final notifier = stateOf(key);

    final settings = await AiSettingsStore.load();
    if (!settings.isConfigured) {
      notifier.value = AiDiagnosisState(
        error: l.dxAiNotConfiguredShort,
      );
      return;
    }

    notifier.value = const AiDiagnosisState(streaming: true);
    AiClient.feature = 'diagnosis';
    final buffer = StringBuffer();

    final sub = AiClient(settings, l)
        .completeStream(
          system: kDiagnosisSystem,
          prompt: diagnosis.toPrompt(),
          // 正文只要 600 字（≈1200 token），但推理模型要先"想"一轮，
          // 而想的部分也从 max_tokens 里扣。给 1400 的话，想完就没配额
          // 吐正文，回来是一句空的 —— 报错报的是"模型没吐出正文"。
          // 只按实际生成的 token 计费，给宽不花冤枉钱。
          maxTokens: 8000,
        )
        .listen(
      (delta) {
        buffer.write(delta);
        notifier.value = AiDiagnosisState(
          text: buffer.toString(),
          streaming: true,
        );
      },
      onError: (Object error) {
        _running.remove(key);
        notifier.value = AiDiagnosisState(
          text: buffer.toString(),
          error: error is AiException ? error.message : '$error',
        );
      },
      onDone: () async {
        _running.remove(key);
        final body = buffer.toString().trim();
        if (body.isEmpty) {
          notifier.value =
              AiDiagnosisState(error: l.aiEmptyReply);
          return;
        }
        await AppDatabase.instance.saveAiDiagnosis(
          key,
          body,
          model: settings.effectiveModel,
        );
        final saved = await AppDatabase.instance.aiDiagnosis(key);
        notifier.value = AiDiagnosisState(text: body, stamp: saved?.stamp);
      },
      cancelOnError: true,
    );
    _running[key] = sub;
  }

  Future<void> regenerate(String key, Diagnosis diagnosis, AppL l) async {
    await _running.remove(key)?.cancel();
    await AppDatabase.instance.deleteAiDiagnosis(key);
    stateOf(key).value = const AiDiagnosisState();
    await start(key, diagnosis, l);
  }
}
