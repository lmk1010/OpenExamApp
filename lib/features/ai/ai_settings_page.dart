import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';

/// AI 设置 —— 申论批改和拍照识题都要用它。
///
/// 这是 app 里唯一联网的功能：请求只发往你自己填的那个服务商，
/// Key 存在本机，不经过任何中间服务器。
class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  AiSettings _settings = AiSettings.empty;
  bool _loading = true;
  bool _testing = false;
  bool _revealKey = false;
  String? _testMessage;
  bool _testOk = false;

  final _keyCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _modelCtrl.dispose();
    _baseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await AiSettingsStore.load();
    if (!mounted) return;
    setState(() {
      _settings = loaded;
      _keyCtrl.text = loaded.apiKey;
      _modelCtrl.text = loaded.model;
      _baseCtrl.text = loaded.baseUrl;
      _loading = false;
    });
  }

  AiSettings get _current => _settings.copyWith(
        apiKey: _keyCtrl.text,
        model: _modelCtrl.text,
        baseUrl: _baseCtrl.text,
      );

  Future<void> _save() async {
    await AiSettingsStore.save(_current);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppL.of(context).aiSaved)),
    );
  }

  Future<void> _test() async {
    // AI 客户端要一份报错文案，而这里在 await 之后 —— 先取出来。
    final l = AppL.of(context);
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    // 先存再测，免得测通了却忘了保存
    await AiSettingsStore.save(_current);
    final result = await AiClient(_current, l).testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = result.isOk;
      _testMessage = result.isOk ? result.value : result.error;
    });
  }

  void _pickProvider(AiProvider provider) {
    setState(() {
      _settings = _settings.copyWith(providerId: provider.id);
      // 切服务商时清掉上一家的模型名和地址，留空即用新家的默认值
      _modelCtrl.text = '';
      if (provider.id != 'custom') _baseCtrl.text = '';
      _testMessage = null;
    });
  }

  Future<void> _openKeyPage() async {
    final url = _settings.provider.keyUrl;
    if (url == null) return;
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppL.of(context).aiCantOpenBrowser(url))));
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final v = data?.text?.trim() ?? '';
    if (v.isEmpty) return;
    setState(() => _keyCtrl.text = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    if (_loading) return const Scaffold(body: LoadingState());

    final provider = _settings.provider;
    final model = _modelCtrl.text.trim().isEmpty
        ? provider.defaultModel
        : _modelCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(title: Text(AppL.of(context).profileAiSettings)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          40,
        ),
        children: [
          // 第一步：挑一家
          _Step(n: 1, title: AppL.of(context).aiPickProvider),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in AiProviders.all)
                _Chip(
                  label: p.labelText(AppL.of(context)),
                  selected: p.id == provider.id,
                  onTap: () => _pickProvider(p),
                ),
            ],
          ),

          SizedBox(height: 26),

          // 第二步：填 Key。这是用户唯一必须自己动手的地方。
          _Step(n: 2, title: AppL.of(context).aiEnterKey),
          const SizedBox(height: 12),
          _KeyField(
            controller: _keyCtrl,
            reveal: _revealKey,
            onReveal: () => setState(() => _revealKey = !_revealKey),
            onPaste: _paste,
            onChanged: (_) => setState(() {}),
          ),
          if (provider.keyUrl != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openKeyPage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: t.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 17, color: t.brand),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        AppL.of(context).aiGetKeyAt(provider.hintText(AppL.of(context))),
                        style: text.bodySmall?.copyWith(
                          color: t.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 26),

          // 第三步：模型给下拉，别让人去背模型名
          _Step(n: 3, title: AppL.of(context).aiWhichModel),
          SizedBox(height: 12),
          if (provider.models.isNotEmpty)
            _ModelPicker(
              models: provider.models,
              value: model,
              onPick: (id) => setState(() => _modelCtrl.text = id),
            )
          else
            _Field(
              controller: _modelCtrl,
              hint: AppL.of(context).aiModelHint,
              onChanged: (_) => setState(() {}),
            ),

          // 地址只有自定义服务商要填。官方那几家已经配好了，
          // 摆一个「留空用默认」的输入框只会让人以为自己漏填了东西。
          if (provider.needsBaseUrl) ...[
            SizedBox(height: 26),
            _Step(n: 4, title: AppL.of(context).aiBaseUrl),
            const SizedBox(height: 12),
            _Field(
              controller: _baseCtrl,
              hint: 'https://…/v1',
              onChanged: (_) => setState(() {}),
            ),
          ] else ...[
            SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 15, color: t.success),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    AppL.of(context).aiBaseUrlSet(provider.baseUrl),
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _testing ? null : _test,
                  child: Text(_testing ? AppL.of(context).aiTesting : AppL.of(context).aiTest),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _keyCtrl.text.trim().isEmpty ? null : _save,
                  child: Text(AppL.of(context).commonSave),
                ),
              ),
            ],
          ),

          if (_testMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _testOk ? t.successSoft : t.dangerSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _testOk
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 17,
                    color: _testOk ? t.success : t.danger,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _testMessage!,
                      style: text.bodySmall?.copyWith(
                        color: _testOk ? t.success : t.danger,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 24),
          _Note(
            text: AppL.of(context).aiKeyPrivacy,
          ),
        ],
      ),
    );
  }
}

/// 步骤号 + 标题。三步走完就能用，不需要读说明。
class _Step extends StatelessWidget {
  const _Step({required this.n, required this.title});

  final int n;
  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
              color: t.onAccent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontSize: 15.5),
        ),
      ],
    );
  }
}

/// Key 输入框：一眼能看出填没填，粘贴和明文各一个按钮。
class _KeyField extends StatelessWidget {
  const _KeyField({
    required this.controller,
    required this.reveal,
    required this.onReveal,
    required this.onPaste,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool reveal;
  final VoidCallback onReveal;
  final VoidCallback onPaste;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final filled = controller.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: filled ? t.success.withValues(alpha: 0.5) : t.line,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: !reveal,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: onChanged,
              style: TextStyle(fontSize: 15, color: t.text),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
                hintText: 'sk-…',
                hintStyle: TextStyle(color: t.muted, fontSize: 15),
              ),
            ),
          ),
          IconButton(
            tooltip: AppL.of(context).aiPaste,
            onPressed: onPaste,
            icon: Icon(Icons.content_paste_rounded, size: 19, color: t.textSoft),
          ),
          IconButton(
            tooltip: reveal ? AppL.of(context).aiHide : AppL.of(context).aiShow,
            onPressed: onReveal,
            icon: Icon(
              reveal
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19,
              color: t.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// 模型下拉。每条带一句用途，免得用户对着一串模型名猜。
class _ModelPicker extends StatelessWidget {
  const _ModelPicker({
    required this.models,
    required this.value,
    required this.onPick,
  });

  final List<AiModel> models;
  final String value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: t.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < models.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: t.lineSoft, indent: 16),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(models[i].id),
              child: Container(
                color: models[i].id == value ? t.accentSoft : null,
                padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                models[i].label,
                                style: text.titleSmall?.copyWith(fontSize: 15),
                              ),
                              if (models[i].free) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.successSoft,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    AppL.of(context).aiFree,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: t.success,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (models[i].note.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              models[i].noteText(AppL.of(context)),
                              style: text.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (models[i].id == value)
                      Icon(Icons.check_rounded, size: 19, color: t.onAccentSoft),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autocorrect: false,
              enableSuggestions: false,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? t.accent : t.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? t.accent : t.line,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? t.onAccent : t.textSoft,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StrokeIcon(AppIcon.privacy, size: 18, color: t.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.65),
            ),
          ),
        ],
      ),
    );
  }
}
