import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';

/// One option inside a filter picker.
class FilterOption {
  const FilterOption(this.value, this.label, {this.count});

  final String value;
  final String label;

  /// Shown on the right so the user knows what a filter will yield.
  final int? count;
}

/// A filter the bar can show: a label, the currently chosen option, and the
/// list to pick from.
class FilterSpec {
  const FilterSpec({
    required this.key,
    required this.label,
    required this.value,
    required this.options,
    this.icon,
  });

  final String key;

  /// Shown when nothing is chosen, e.g. 地区.
  final String label;
  final String value;
  final List<FilterOption> options;
  final AppIcon? icon;

  bool get active => value != 'all';

  String get display =>
      options.firstWhere((o) => o.value == value, orElse: () => FilterOption('all', label)).label;
}

/// Compact horizontal filter chips — always one scrollable row.
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
    this.onReset,
  });

  final List<FilterSpec> filters;
  final void Function(String key, String value) onChanged;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final anyActive = filters.any((f) => f.active);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter + 24,
          0,
        ),
        children: [
          for (final filter in filters) ...[
            _FilterButton(
              spec: filter,
              onTap: () async {
                HapticFeedback.selectionClick();
                final picked = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _PickerSheet(spec: filter),
                );
                if (picked != null) onChanged(filter.key, picked);
              },
            ),
            const SizedBox(width: 6),
          ],
          if (anyActive && onReset != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onReset,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 13, color: t.muted),
                    const SizedBox(width: 4),
                    Text(
                      '清除',
                      style: TextStyle(
                        fontSize: 12,
                        color: t.muted,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.spec, required this.onTap});

  final FilterSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final active = spec.active;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? t.accentSoft : t.surfaceAlt,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? t.accent : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spec.icon != null) ...[
              StrokeIcon(
                spec.icon!,
                size: 13,
                weight: 2,
                color: active ? t.onAccentSoft : t.muted,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              active ? spec.display : spec.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1,
                color: active ? t.onAccentSoft : t.textSoft,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: active ? t.onAccentSoft : t.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.spec});

  final FilterSpec spec;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    // A 32-province list needs a search box; a four-item list does not.
    final searchable = widget.spec.options.length > 12;
    final shown = _query.isEmpty
        ? widget.spec.options
        : widget.spec.options
            .where((o) => o.label.contains(_query))
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.spec.label, style: text.titleMedium),
            if (searchable) ...[
              const SizedBox(height: 14),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: t.name == 'dark'
                      ? Colors.white.withValues(alpha: 0.06)
                      : t.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 17, color: t.muted),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v.trim()),
                        style: text.bodyMedium?.copyWith(
                          color: t.text,
                          fontSize: 14.5,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: '搜一下',
                          hintStyle: text.bodySmall?.copyWith(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  final option = shown[i];
                  final selected = option.value == widget.spec.value;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(option.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              style: text.titleSmall?.copyWith(
                                fontSize: 15,
                                color: selected ? t.brand : t.text,
                              ),
                            ),
                          ),
                          if (option.count != null)
                            Text('${option.count}', style: text.bodySmall),
                          const SizedBox(width: 10),
                          if (selected)
                            Icon(Icons.check, size: 18, color: t.brand)
                          else
                            const SizedBox(width: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
