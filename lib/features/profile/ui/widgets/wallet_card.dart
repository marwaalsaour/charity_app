import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/wallet_currencies.dart';

class WalletCard extends StatefulWidget {
  const WalletCard({
    super.key,
    required this.balances,
    required this.isLoading,
    this.hint,
  });

  final Map<String, double> balances;
  final bool isLoading;
  final String? hint;

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  late String _selected;
  late final PageController _pageController;
  var _didSyncSelection = false;

  @override
  void initState() {
    super.initState();
    _selected = _defaultCurrency(widget.balances);
    _pageController = PageController(
      initialPage: WalletCurrencies.codes.indexOf(_selected).clamp(0, 4),
    );
  }

  @override
  void didUpdateWidget(covariant WalletCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didSyncSelection || widget.isLoading) return;
    _didSyncSelection = true;
    final next = _defaultCurrency(widget.balances);
    if (next == _selected) return;
    _selected = next;
    final index = WalletCurrencies.codes.indexOf(next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(index);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _defaultCurrency(Map<String, double> balances) {
    for (final code in WalletCurrencies.codes) {
      if ((balances[code] ?? 0) > 0) return code;
    }
    return 'USD';
  }

  Future<void> _selectCurrency(String code) async {
    if (_selected == code) return;
    setState(() => _selected = code);
    final index = WalletCurrencies.codes.indexOf(code);
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final isArabic = locale.languageCode == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: textDirection,
      child: Container(
        key: ValueKey('wallet_${locale.languageCode}'),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(
                alpha: isDark ? 0.45 : 0.28,
              ),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  Color(0xFF0F3D35),
                  Color(0xFF1A5C52),
                  Color(0xFF2A7A6C),
                ],
              ),
            ),
            child: Stack(
              children: [
                const PositionedDirectional(
                  top: -48,
                  end: -36,
                  child: _GlowCircle(size: 150, color: Color(0x29F2C055)),
                ),
                const PositionedDirectional(
                  bottom: -60,
                  start: -40,
                  child: _GlowCircle(size: 170, color: Color(0x12FFFFFF)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 168,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.tr('wallet'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: isArabic ? 0 : 0.3,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr('app_name'),
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: isArabic ? 0 : 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Text(
                              context.tr('wallet_available'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 78,
                              child: PageView.builder(
                                key: ValueKey(
                                  'wallet_pages_${locale.languageCode}',
                                ),
                                controller: _pageController,
                                itemCount: WalletCurrencies.codes.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _selected = WalletCurrencies.codes[index];
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final code = WalletCurrencies.codes[index];
                                  final amount = widget.balances[code] ?? 0;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Text(
                                          WalletCurrencies.format(
                                            amount,
                                            code,
                                            locale: locale,
                                          ),
                                          textDirection: textDirection,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w800,
                                            height: 1.1,
                                            letterSpacing: isArabic ? 0 : 0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        context.tr(
                                          WalletCurrencies.nameKey(code),
                                        ),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (
                                    var i = 0;
                                    i < WalletCurrencies.codes.length;
                                    i++
                                  ) ...[
                                    if (i > 0) const SizedBox(width: 8),
                                    _CurrencyChip(
                                      code: WalletCurrencies.codes[i],
                                      selected:
                                          _selected ==
                                          WalletCurrencies.codes[i],
                                      hasBalance:
                                          (widget.balances[WalletCurrencies
                                                  .codes[i]] ??
                                              0) >
                                          0,
                                      onTap: () => _selectCurrency(
                                        WalletCurrencies.codes[i],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.hint ?? context.tr('wallet_switch_hint'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.code,
    required this.selected,
    required this.hasBalance,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final bool hasBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasBalance) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.primaryDark
                        : const Color(0xFF8FD4B8),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primaryDark : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
