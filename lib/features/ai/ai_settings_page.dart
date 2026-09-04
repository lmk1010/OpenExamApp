import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      const SnackBar(content: Text('已保存')),
    );
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    // 先存再测，免得测通了却忘了保存
    await AiSettingsStore.save(_current);
    final result = await AiClient(_current).testConnection();
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    if (_loading) return const Scaffold(body: LoadingState());

    final provider = _settings.provider;
    final isCustom = provider.id == 'custom';

    return Scaffold(
      appBar: AppBar(title: const Text('AI 设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          8,
          AppTheme.gutter,
          40,
        ),
        children: [
          _Note(
            text: '申论批改、拍照识题要用到 AI。Key 只存在这台手机上，'
                '请求直接发给你选的服务商，不经过我们任何服务器。',
          ),
          const SizedBox(height: 20),

          _Label('服务商'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in AiProviders.all)
                _Chip(
                  label: p.label,
                  selected: p.id == provider.id,
                  onTap: () => _pickProvider(p),
                ),
            ],
          ),
          if (provider.hint != null) ...[
            const SizedBox(height: 8),
            Text('去 ${provider.hint} 申请 Key', style: text.bodySmall),
          ],
          const SizedBox(height: 22),

          _Label('API Key'),
          const SizedBox(height: 8),
          _Field(
            controller: _keyCtrl,
            hint: 'sk-…',
            obscure: !_revealKey,
            onChanged: (_) => setState(() => _testMessage = null),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _revealKey ? '隐藏' : '显示',
                  icon: Icon(
                    _revealKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: t.muted,
                  ),
                  onPressed: () => setState(() => _revealKey = !_revealKey),
                ),
                IconButton(
                  tooltip: '粘贴',
                  icon: Icon(Icons.content_paste_rounded, size: 18, color: t.muted),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final value = data?.text?.trim();
                    if (value == null || value.isEmpty) return;
                    setState(() {
                      _keyCtrl.text = value;
                      _testMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _Label('模型'),
          const SizedBox(height: 8),
          _Field(
            controller: _modelCtrl,
            hint: isCustom ? '必填，例如 gpt-4o-mini' : '留空用默认：${provider.defaultModel}',
            onChanged: (_) => setState(() => _testMessage = null),
          ),
          const SizedBox(height: 20),

          _Label(isCustom ? '接口地址' : '接口地址（可选）'),
          const SizedBox(height: 8),
          _Field(
            controller: _baseCtrl,
            hint: isCustom
                ? '必填，例如 https://your-relay.com/v1'
                : '留空用默认：${provider.baseUrl}',
            onChanged: (_) => setState(() => _testMessage = null),
          ),
          const SizedBox(height: 6),
          Text('用中转或自建服务时填这里，要带上 /v1', style: text.bodySmall),

          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _testing ? null : _test,
                  child: Text(_testing ? '测试中…' : '测试连接'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _testing ? null : _save,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),

          if (_testMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (_testOk ? t.success : t.danger).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _testOk ? Icons.check_circle_outline : Icons.error_outline,
                    size: 18,
                    color: _testOk ? t.success : t.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _testMessage!,
                      style: text.bodySmall?.copyWith(
                        color: _testOk ? t.success : t.danger,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: context.tokens.text),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.trailing,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
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
          if (trailing != null) trailing!,
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
          color: selected ? t.brand : t.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? t.brand : t.line),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : t.textSoft,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
        color: t.brand.withValues(alpha: 0.08),
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
