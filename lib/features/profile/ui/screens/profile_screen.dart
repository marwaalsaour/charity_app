import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/auth/user_role_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../requests/logic/cubit/request_cubit.dart';
import '../../../requests/logic/states/request_state.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/models/wallet_currencies.dart';
import '../../data/repositories/beneficiary_wallet_store.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../widgets/wallet_card.dart';
import 'my_sponsorships_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.role = UserRole.donor});

  final UserRole role;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepository = UserProfileRepository();

  Map<String, double> _walletBalances = WalletCurrencies.empty;
  bool _loadingWallet = true;
  UserProfileModel? _profile;
  bool _loadingProfile = true;

  bool get _isBeneficiary => widget.role == UserRole.beneficiary;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _applyWalletFrom(UserProfileModel? profile) {
    _walletBalances = profile?.walletBalances ?? WalletCurrencies.empty;
    _loadingWallet = false;
  }

  Future<void> _mergeBeneficiaryCredits() async {
    if (!_isBeneficiary) return;
    final credits = await BeneficiaryWalletStore().loadBalances();
    if (!mounted || credits.isEmpty) return;
    setState(() {
      _walletBalances = WalletCurrencies.merge([_walletBalances, credits]);
    });
  }

  Future<void> _loadWallet() async {
    final remote = await AuthRepository().syncProfile();
    final profile = remote ?? await _profileRepository.getProfile();
    if (!mounted) return;
    setState(() {
      if (remote != null) _profile = remote;
      _applyWalletFrom(profile);
    });
    await _mergeBeneficiaryCredits();
  }

  Future<void> _loadProfile() async {
    final local = await _profileRepository.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = local;
      _loadingProfile = false;
      _applyWalletFrom(local);
    });
    await _mergeBeneficiaryCredits();

    final remote = await AuthRepository().syncProfile();
    if (!mounted || remote == null) return;
    setState(() {
      _profile = remote;
      _applyWalletFrom(remote);
    });
    await _mergeBeneficiaryCredits();
  }

  Future<void> _openEditProfile() async {
    final saved = await context.push<bool>(AppRoutes.editProfile);
    if (saved == true) {
      _loadProfile();
    }
  }

  String get _displayName {
    if (_profile != null && _profile!.hasName) {
      return _profile!.fullName;
    }
    return _isBeneficiary
        ? 'beneficiary_mock_name'.tr()
        : 'donor_mock_name'.tr();
  }

  String? get _imagePath => _profile?.imagePath;

  int get _memberSinceYear => _profile?.memberSinceYear ?? 2022;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('nav_profile'.tr()),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const SizedBox(height: 8),
          _AvatarSection(
            name: _displayName,
            imagePath: _imagePath,
            memberSinceYear: _memberSinceYear,
            roleLabel: _isBeneficiary
                ? 'profile_beneficiary_role'.tr()
                : 'profile_donor_role'.tr(),
            isLoading: _loadingProfile,
            onEditTap: _openEditProfile,
          ),
          const SizedBox(height: 24),
          WalletCard(
            balances: _walletBalances,
            isLoading: _loadingWallet,
          ),
          if (_isBeneficiary) ...[
            const SizedBox(height: 16),
            BlocBuilder<RequestCubit, RequestState>(
              builder: (context, state) => _BeneficiaryRequestsCard(
                count: state.myRequests
                    .where((r) => r.isPending || r.isApproved)
                    .length,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_isBeneficiary) ...[
            _ProfileMenuTile(
              icon: Icons.assignment_outlined,
              iconColor: cs.primary,
              iconBg: cs.primary.withValues(alpha: 0.1),
              title: 'my_requests'.tr(),
              onTap: () => context.go(AppRoutes.beneficiaryRequests),
            ),
            const SizedBox(height: 10),
          ] else ...[
            _ProfileMenuTile(
              icon: Icons.volunteer_activism_outlined,
              iconColor: cs.primary,
              iconBg: cs.primary.withValues(alpha: 0.1),
              title: 'my_activities'.tr(),
              onTap: () => context.push(AppRoutes.myActivities),
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              icon: Icons.favorite,
              iconColor: AppColors.accentDark,
              iconBg: AppColors.accent.withValues(alpha: 0.25),
              title: 'my_donations'.tr(),
              onTap: () async {
                await context.push(AppRoutes.myDonations);
                _loadWallet();
              },
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              icon: Icons.child_care_outlined,
              iconColor: cs.primary,
              iconBg: cs.primary.withValues(alpha: 0.1),
              title: context.tr('my_sponsorships'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MySponsorshipsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          _ProfileMenuTile(
            icon: Icons.edit_outlined,
            iconColor: cs.primary,
            iconBg: ext.inputFill,
            title: 'edit_profile'.tr(),
            onTap: _openEditProfile,
          ),
          const SizedBox(height: 28),
          _LogoutButton(
            onTap: () async {
              await AuthRepository().logout();
              if (!context.mounted) return;
              await context.read<UserRoleCubit>().clearRole();
              if (!context.mounted) return;
              context.go(widget.role.loginRoute);
            },
          ),
          const SizedBox(height: 32),
          Center(
            child: Opacity(
              opacity: isDark ? 0.4 : 0.25,
              child: Column(
                children: [
                  Icon(Icons.volunteer_activism, size: 32, color: cs.primary),
                  const SizedBox(height: 4),
                  Text(
                    'app_name'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.name,
    required this.imagePath,
    required this.memberSinceYear,
    required this.roleLabel,
    required this.isLoading,
    required this.onEditTap,
  });

  final String name;
  final String? imagePath;
  final int memberSinceYear;
  final String roleLabel;
  final bool isLoading;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Column(
      children: [
        GestureDetector(
          onTap: onEditTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ext.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ext.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.2
                            : 0.06,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _buildAvatarContent(cs),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            roleLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'profile_member_since'.tr(namedArgs: {'year': '$memberSinceYear'}),
          style: TextStyle(fontSize: 14, color: ext.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAvatarContent(ColorScheme cs) {
    final path = imagePath;
    if (path == null || path.isEmpty) {
      return Icon(Icons.person, size: 48, color: cs.primary);
    }

    final isNetwork = path.startsWith('http://') || path.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: isNetwork
          ? CachedNetworkImage(
              imageUrl: path,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  Icon(Icons.person, size: 48, color: cs.primary),
              errorWidget: (_, _, _) =>
                  Icon(Icons.person, size: 48, color: cs.primary),
            )
          : File(path).existsSync()
          ? Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover)
          : Icon(Icons.person, size: 48, color: cs.primary),
    );
  }
}

class _BeneficiaryRequestsCard extends StatelessWidget {
  const _BeneficiaryRequestsCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'my_requests'.tr().toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ext.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'beneficiary_requests_active'.tr(),
                  style: TextStyle(fontSize: 12, color: ext.textSecondary),
                ),
              ],
            ),
          ),
          Icon(
            Icons.assignment_outlined,
            color: cs.primary.withValues(alpha: 0.7),
            size: 32,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Material(
      color: ext.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: ext.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: ext.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.error.withValues(alpha: 0.15)
          : const Color(0xFFFDECEA),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'logout'.tr(),
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
