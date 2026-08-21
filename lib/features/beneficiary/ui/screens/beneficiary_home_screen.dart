import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/navigation/host_scaffold.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../home/logic/home_cubit.dart';
import '../../../home/logic/home_state.dart';
import '../../../home/ui/widgets/association_map_card.dart';
import '../../../home/ui/widgets/stats_card.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../../requests/logic/cubit/request_cubit.dart';
import '../../../requests/logic/states/request_state.dart';
import '../../../requests/ui/utils/request_sheet_helper.dart';
import '../widgets/beneficiary_case_card.dart';

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
    context.read<HomeCubit>().loadHome();
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadProfile(),
            context.read<HomeCubit>().refresh(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    const SizedBox(height: 24),
                    Center(
                      child: Image.asset(
                        'assets/image/logo-green.png',
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
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

                        final published = requests
                            .where((r) => r.isApproved)
                            .toList();
                        final others = requests
                            .where((r) => !r.isApproved)
                            .take(3)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (published.isNotEmpty) ...[
                              Text(
                                published.length > 1
                                    ? 'my_published_cases'.tr()
                                    : 'my_published_case'.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'beneficiary_case_tracking'.tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: ext.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final item in published)
                                BeneficiaryCaseCard(item: item),
                            ],
                            if (others.isNotEmpty) ...[
                              if (published.isNotEmpty)
                                const SizedBox(height: 16),
                              Text(
                                'my_recent_requests'.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final item in others)
                                BeneficiaryCaseCard(item: item, compact: true),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    AssociationMapCard(
                      key: ValueKey('assoc_map_${context.locale.languageCode}'),
                      horizontalPadding: 0,
                    ),
                    const SizedBox(height: 8),
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
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final volunteers = state is HomeLoaded ? state.volunteers : 0;
        final donors = state is HomeLoaded ? state.donors : 0;
        final beneficiaries = state is HomeLoaded ? state.beneficiaries : 0;

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
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => openHostDrawer(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    StatsCard(label: 'volunteers'.tr(), value: '$volunteers'),
                    const SizedBox(width: 10),
                    StatsCard(label: 'donors'.tr(), value: '$donors'),
                    const SizedBox(width: 10),
                    StatsCard(
                      label: 'beneficiaries'.tr(),
                      value: '$beneficiaries',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
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
