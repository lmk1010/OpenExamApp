import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/rich_content.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';

/// Search the whole bank by keyword — 16k questions, LIKE over the plain text.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Question> _results = const [];
  String _query = '';
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 260), () async {
      final hits = await AppDatabase.instance.search(q);
      if (!mounted) return;
      setState(() {
        _query = q;
        _results = hits;
        _searching = false;
      });
    });
  }

  Future<void> _practise(List<Question> questions) async {
    if (questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PracticeSessionPage(questions: questions)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('搜题'),
        actions: [
          if (_results.isNotEmpty)
            TextButton(
              onPressed: () => _practise(_results.take(20).toList()),
              child: const Text('练这些'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 4, AppTheme.gutter, 14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: GlassDecor.panel(t, radius: 22, raised: false),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: t.muted),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      style: text.bodyMedium?.copyWith(color: t.text, fontSize: 15),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '搜题干、解析关键词',
                        hintStyle: text.bodySmall?.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        _onChanged('');
                      },
                      child: Icon(Icons.close, size: 17, color: t.muted),
                    ),
                ],
              ),
            ),
          ),
          if (_query.isNotEmpty && !_searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 6),
              child: Row(
                children: [
                  Text(
                    _results.isEmpty ? '没找到相关题目' : '找到 ${_results.length} 题',
                    style: text.bodySmall,
                  ),
                  const Spacer(),
                  if (_results.length >= 60)
                    Text('只显示前 60 条', style: text.bodySmall),
                ],
              ),
            ),
          Expanded(
            child: _searching
                ? const LoadingState()
                : _query.isEmpty
                    ? const EmptyState(
                        icon: Icons.search,
                        title: '搜索全部 15936 题',
                        message: '输入关键词，例如「行政处罚」「等差数列」「主旨概括」。',
                      )
                    : _results.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off,
                            title: '没有匹配的题目',
                            message: '换个更短的关键词试试。',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const RowDivider(),
                            itemBuilder: (context, i) => _ResultRow(
                              question: _results[i],
                              query: _query,
                              onTap: () => _practise([_results[i]]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.question,
    required this.query,
    required this.onTap,
  });

  final Question question;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(question.category);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: QuestionThumb(
                markup: question.bodyMarkup,
                icon: categoryIcon(question.category),
                color: color,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The matched term is highlighted so hits are scannable.
                  _Highlighted(
                    text: question.content,
                    term: query,
                    style: text.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
                    highlight: color,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${categoryLabel(question.category)}'
                    '${question.year > 0 ? ' · ${question.year} 年' : ''}'
                    '${question.hasImage ? ' · 含图' : ''}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: StrokeIcon(AppIcon.play, size: 22, color: t.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question preview with the search term picked out, trimmed to the first hit.
class _Highlighted extends StatelessWidget {
  const _Highlighted({
    required this.text,
    required this.term,
    required this.style,
    required this.highlight,
  });

  final String text;
  final String term;
  final TextStyle? style;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final index = text.indexOf(term);
    if (index < 0) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
    }
    // Start a little before the match so the term is always visible.
    final from = index > 18 ? index - 14 : 0;
    final body = (from > 0 ? '…' : '') + text.substring(from);
    final at = body.indexOf(term);

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: body.substring(0, at)),
          TextSpan(
            text: term,
            style: style?.copyWith(color: highlight, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: body.substring(at + term.length)),
        ],
      ),
    );
  }
}
