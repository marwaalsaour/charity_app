import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/user_role.dart';
import '../core/constants/app_colors.dart';
import '../core/router/app_routes.dart';
import '../features/requests/ui/utils/request_sheet_helper.dart';

class MainNavigationScreen extends StatelessWidget {
  final UserRole role;
  final Widget child;

  const MainNavigationScreen({
    super.key,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isDonor = role == UserRole.donor;

    final routes = isDonor
        ? [
            AppRoutes.donorHome,
            AppRoutes.donorNotifications,
            AppRoutes.donorCampaigns,
            AppRoutes.donorProfile,
          ]
        : [
            AppRoutes.beneficiaryHome,
            AppRoutes.beneficiaryNotifications,
            AppRoutes.beneficiaryRequests,
            AppRoutes.beneficiaryProfile,
          ];

    int currentIndex = 0;
    for (var i = 0; i < routes.length; i++) {
      if (location.startsWith(routes[i])) {
        currentIndex = i;
        break;
      }
    }

    // Donation sub-routes belong to donor campaigns tab
    if (isDonor &&
        (location.startsWith(AppRoutes.donationsList) ||
            location.startsWith(AppRoutes.donationDetails) ||
            location.startsWith(AppRoutes.donateAmount) ||
            location.startsWith(AppRoutes.communityCampaigns) ||
            location.startsWith(AppRoutes.communityCampaignDetails) ||
            location.startsWith(AppRoutes.fieldVolunteer))) {
      currentIndex = 2;
    }

    if (isDonor &&
        (location.startsWith(AppRoutes.myDonations) ||
            (location.startsWith(AppRoutes.donationReceipt) &&
                location.contains('from=profile')))) {
      currentIndex = 3;
    } else if (isDonor && location.startsWith(AppRoutes.myActivities)) {
      currentIndex = 3;
    } else if (isDonor && location.startsWith(AppRoutes.editProfile)) {
      currentIndex = 3;
    } else if (isDonor && location.startsWith(AppRoutes.donationReceipt)) {
      currentIndex = 2;
    }

    // Request form sub-routes belong to beneficiary requests tab
    if (!isDonor &&
        (location.startsWith(AppRoutes.medicalRequest) ||
            location.startsWith(AppRoutes.educationRequest) ||
            location.startsWith(AppRoutes.orphanRequest))) {
      currentIndex = 2;
    }

    if (!isDonor && location.startsWith(AppRoutes.editProfile)) {
      currentIndex = 3;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(
        role: role,
        currentIndex: currentIndex,
        onTap: (index) => context.go(routes[index]),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final UserRole role;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.role,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDonor = role == UserRole.donor;

    return BottomAppBar(
      shape: isDonor ? null : const CircularNotchedRectangle(),
      notchMargin: isDonor ? 0 : 8,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 12,
      child: SizedBox(
        height: 60,
        child: isDonor ? _buildDonorNav(context) : _buildBeneficiaryNav(context),
      ),
    );
  }

  Widget _buildDonorNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: Icons.home_rounded,
          label: 'nav_home'.tr(),
          index: 0,
          current: currentIndex,
          onTap: onTap,
        ),
        _NavItem(
          icon: Icons.notifications_rounded,
          label: 'nav_alerts'.tr(),
          index: 1,
          current: currentIndex,
          onTap: onTap,
        ),
        _NavItem(
          icon: Icons.volunteer_activism_rounded,
          label: 'nav_impact'.tr(),
          index: 2,
          current: currentIndex,
          onTap: onTap,
        ),
        _NavItem(
          icon: Icons.person_rounded,
          label: 'nav_profile'.tr(),
          index: 3,
          current: currentIndex,
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildBeneficiaryNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: Icons.home_rounded,
          label: 'nav_home'.tr(),
          index: 0,
          current: currentIndex,
          onTap: onTap,
        ),
        _NavItem(
          icon: Icons.notifications_rounded,
          label: 'nav_alerts'.tr(),
          index: 1,
          current: currentIndex,
          onTap: onTap,
        ),
        GestureDetector(
          onTap: () => showBeneficiaryRequestSheet(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add, color: Colors.black87),
          ),
        ),
        _NavItem(
          icon: Icons.request_page_rounded,
          label: 'nav_requests'.tr(),
          index: 2,
          current: currentIndex,
          onTap: onTap,
        ),
        _NavItem(
          icon: Icons.person_rounded,
          label: 'nav_profile'.tr(),
          index: 3,
          current: currentIndex,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = index == current;
    final color = isActive ? cs.primary : cs.onSurface.withOpacity(0.35);

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? cs.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
