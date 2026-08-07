import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../../requests/data/models/benefit_request_models.dart';
import '../../../requests/logic/cubit/request_cubit.dart';
import '../../../requests/logic/states/request_state.dart';
import '../../../requests/ui/utils/request_sheet_helper.dart';


class BeneficiaryHomeScreen extends StatefulWidget {
  const BeneficiaryHomeScreen({super.key});

  @override
  State<BeneficiaryHomeScreen> createState() => _BeneficiaryHomeScreenState();
}

class _BeneficiaryHomeScreenState extends State<BeneficiaryHomeScreen> {
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final local = await UserProfileRepository().getProfile();
    if (mounted && local != null) setState(() => _profile = local);

    final remote = await AuthRepository().syncProfile();
    if (mounted && remote != null) setState(() => _profile = remote);

    if (!mounted) return;
    await context.read<RequestCubit>().loadMyRequests();
  }

  String get _displayName {
    if (_profile != null && _profile!.hasName) return _profile!.fullName;
    return 'beneficiary_mock_name'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      drawer: const _BeneficiaryDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'beneficiary_welcome_title'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'beneficiary_welcome_desc'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: ext.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      label: 'submit_request'.tr(),
                      icon: Icons.add_circle_outline,
                      variant: ButtonVariant.primary,
                      onTap: () => showBeneficiaryRequestSheet(context),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'my_recent_requests'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<RequestCubit, RequestState>(
                      builder: (context, state) {
                        final requests = state.myRequests;
                        if (state.isLoadingRequests && requests.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (requests.isEmpty) {
                          return Text(
                            'no_requests_yet'.tr(),
                            style: TextStyle(color: ext.textSecondary),
                          );
                        }
                        final recent = requests.take(3).toList();
                        return Column(
                          children: [
                            for (final item in recent) ...[
                              _RequestPreviewCard(item: item),
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      },
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 52),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _BeneficiaryAvatar(imagePath: _profile?.imagePath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'welcome_back'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _BeneficiaryAvatar extends StatelessWidget {
  const _BeneficiaryAvatar({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white,
      backgroundImage: _provider,
      child: _provider == null
          ? const Icon(Icons.person, color: AppColors.primary)
          : null,
    );
  }

  ImageProvider? get _provider {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImageProvider(path);
    }
    final file = File(path);
    if (file.existsSync()) return FileImage(file);
    return null;
  }
}

class _RequestPreviewCard extends StatelessWidget {
  const _RequestPreviewCard({required this.item});

  final BenefitRequestItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusLabel = item.isApproved
        ? 'beneficiary_status_approved'.tr()
        : item.isRejected
            ? 'beneficiary_status_rejected'.tr()
            : 'beneficiary_status_pending'.tr();
    final color = item.isApproved
        ? AppColors.success
        : item.isRejected
            ? AppColors.error
            : AppColors.accentDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.isApproved
                  ? Icons.check_circle_outline
                  : item.isRejected
                      ? Icons.cancel_outlined
                      : Icons.pending_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          Text(
            DateFormat.yMMMd(context.locale.languageCode).format(item.createdAt),
            style: TextStyle(fontSize: 11, color: ext.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BeneficiaryDrawer extends StatelessWidget {
  const _BeneficiaryDrawer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              color: AppColors.primary,
              child: Text(
                'beneficiary_portal'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: cs.primary),
              title: Text(
                'how_to_get_help'.tr(),
                style: TextStyle(color: cs.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.beneficiaryHowToGetHelp);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.contact_mail_outlined, color: cs.primary),
              title: Text(
                'contact_us'.tr(),
                style: TextStyle(color: cs.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.beneficiaryContactUs);
              },
            ),
          ],
        ),
      ),
    );
  }
}
