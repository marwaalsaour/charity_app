import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../data/models/campaign_model.dart';
import '../../data/models/search_suggestion.dart';
import '../../data/search_suggestion_helper.dart';

class AppSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<SearchSuggestion>? onSuggestionTap;
  final String hintText;
  final List<CampaignModel> campaigns;

  const AppSearchBar({
    super.key,
    this.onChanged,
    this.onSuggestionTap,
    required this.hintText,
    this.campaigns = const [],
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<SearchSuggestion> get _suggestions {
    return SearchSuggestionHelper.getSuggestions(
      query: _controller.text,
      campaigns: widget.campaigns,
    );
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    final text = suggestion.categoryKey != null ? '' : suggestion.query;
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    widget.onChanged?.call(text);
    widget.onSuggestionTap?.call(suggestion);
    _focusNode.unfocus();
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final showSuggestions = _focused && _suggestions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ext.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? cs.primary : ext.border,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              widget.onChanged?.call(value);
              setState(() {});
            },
            style: TextStyle(color: cs.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.45)),
              prefixIcon: Icon(Icons.search, color: cs.primary, size: 22),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      onPressed: _clear,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (showSuggestions) ...[
          const SizedBox(height: 8),
          _SuggestionsPanel(
            suggestions: _suggestions,
            showHeader: _controller.text.trim().isEmpty,
            onTap: _selectSuggestion,
          ),
        ],
      ],
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  const _SuggestionsPanel({
    required this.suggestions,
    required this.showHeader,
    required this.onTap,
  });

  final List<SearchSuggestion> suggestions;
  final bool showHeader;
  final ValueChanged<SearchSuggestion> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'search_suggestions.title'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ext.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ...List.generate(suggestions.length, (index) {
            final suggestion = suggestions[index];
            final isLast = index == suggestions.length - 1;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(suggestion),
                borderRadius: BorderRadius.vertical(
                  bottom: isLast ? const Radius.circular(12) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _iconColor(suggestion.kind, cs)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          suggestion.icon,
                          size: 18,
                          color: _iconColor(suggestion.kind, cs),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (suggestion.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                suggestion.subtitle!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ext.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.north_west_rounded,
                        size: 16,
                        color: ext.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _iconColor(SuggestionKind kind, ColorScheme cs) {
    return switch (kind) {
      SuggestionKind.campaign => cs.primary,
      SuggestionKind.category => cs.secondary,
      SuggestionKind.trending => Colors.orange.shade700,
    };
  }
}
