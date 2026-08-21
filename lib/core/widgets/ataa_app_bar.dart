import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../navigation/tab_navigation.dart';
import '../router/app_routes.dart';

class AtaaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AtaaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBack;

  static const Color actionForeground = Colors.white;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    final tabs = TabNavigation.maybeOf(context);
    if (tabs != null) {
      tabs.selectTab(0);
      return;
    }
    context.go(AppRoutes.homeForPath(GoRouterState.of(context).uri.path));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 4,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.primary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => _handleBack(context),
            )
          : null,
      automaticallyImplyLeading: showBack,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      actions: actions,
    );
  }
}
