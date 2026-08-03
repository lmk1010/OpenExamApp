import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/data/db/app_database.dart';

/// Renders the seed's lightweight markup: paragraphs, line breaks, bold and
/// `oeimg://` figures stored as BLOBs. A full HTML engine would be overkill —
/// the bank only ever contains these.
class RichContent extends StatelessWidget {
  const RichContent(
    this.markup, {
    super.key,
    this.style,
    this.imageAlignment = Alignment.centerLeft,
    this.maxImageHeight = 320,
  });

  final String markup;
  final TextStyle? style;
  final Alignment imageAlignment;
  final double maxImageHeight;

  static final _tokenizer = RegExp(
    r'<img[^>]*src="(oeimg://[^"]+)"[^>]*>',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(markup);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final textStyle = style ?? Theme.of(context).textTheme.bodyLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: blocks[i].isImage
                ? Align(
                    alignment: imageAlignment,
                    child: QuestionImage(
                      name: blocks[i].value,
                      maxHeight: maxImageHeight,
                    ),
                  )
                : Text(blocks[i].value, style: textStyle),
          ),
      ],
    );
  }

  static List<_Block> _parse(String markup) {
    if (markup.isEmpty) return const [];
    final blocks = <_Block>[];
    var cursor = 0;

    void addText(String raw) {
      final text = _plain(raw);
      if (text.isNotEmpty) blocks.add(_Block(text, isImage: false));
    }

    for (final match in _tokenizer.allMatches(markup)) {
      addText(markup.substring(cursor, match.start));
      blocks.add(_Block(match.group(1)!.substring('oeimg://'.length), isImage: true));
      cursor = match.end;
    }
    addText(markup.substring(cursor));
    return blocks;
  }

  /// Strips the remaining tags and decodes the handful of entities in the bank.
  static String _plain(String raw) {
    var text = raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|div|li)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}

/// First figure referenced by [markup], if any — used for list thumbnails.
String? firstImageName(String markup) {
  final match = RegExp(r'oeimg://([A-Za-z0-9._-]+)').firstMatch(markup);
  return match?.group(1);
}

class _Block {
  const _Block(this.value, {required this.isImage});
  final String value;
  final bool isImage;
}

/// List-row leading: the question's figure when it has one, its category glyph
/// otherwise — so a 图形推理 row is recognisable without opening it.
class QuestionThumb extends StatelessWidget {
  const QuestionThumb({
    super.key,
    required this.markup,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  final String markup;
  final AppIcon icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = firstImageName(markup);
    if (name == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Align(
          alignment: Alignment.topLeft,
          child: StrokeIcon(icon, size: 20, color: color),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        padding: const EdgeInsets.all(3),
        child: _ThumbImage(name: name),
      ),
    );
  }
}

class _ThumbImage extends StatefulWidget {
  const _ThumbImage({required this.name});

  final String name;

  @override
  State<_ThumbImage> createState() => _ThumbImageState();
}

class _ThumbImageState extends State<_ThumbImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.image(widget.name).then((b) {
      if (mounted) setState(() => _bytes = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) return const SizedBox.shrink();
    return Image.memory(_bytes!, fit: BoxFit.contain, filterQuality: FilterQuality.low);
  }
}

/// Figure loaded from the bundled database.
class QuestionImage extends StatefulWidget {
  const QuestionImage({super.key, required this.name, this.maxHeight = 320});

  final String name;
  final double maxHeight;

  @override
  State<QuestionImage> createState() => _QuestionImageState();
}

class _QuestionImageState extends State<QuestionImage> {
  Uint8List? _bytes;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant QuestionImage old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name) _load();
  }

  Future<void> _load() async {
    final bytes = await AppDatabase.instance.image(widget.name);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _missing = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    if (_missing) {
      return Container(
        height: 64,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: t.glass,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('图片缺失', style: Theme.of(context).textTheme.bodySmall),
      );
    }

    if (_bytes == null) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: t.glass,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    // Figures are line art on white; a light plate keeps them readable in dark
    // mode without inverting the drawing. Tapping opens a zoomable viewer —
    // 图形推理 details are unreadable at thumbnail size.
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.86),
        builder: (_) => _ImageViewer(bytes: _bytes!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: t.name == 'dark' ? const Color(0xFFF4F5F7) : Colors.white,
          padding: const EdgeInsets.all(6),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: Image.memory(
              _bytes!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinch-to-zoom overlay for a figure.
class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 6,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Image.memory(bytes, filterQuality: FilterQuality.high),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '双指缩放 · 点击关闭',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
