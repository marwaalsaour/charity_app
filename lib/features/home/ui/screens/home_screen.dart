import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/host_scaffold.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../donations/data/models/donation_checkout_args.dart';
import '../../../donations/ui/utils/donation_flow_helper.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../../profile/data/repositories/user_profile_repository.dart';
import '../../data/models/search_suggestion.dart';
import '../../logic/home_cubit.dart';
import '../../logic/home_state.dart';

import '../widgets/association_map_card.dart';
import '../widgets/campaign_card.dart';
import '../widgets/category_tabs.dart';
import '../widgets/home_campaign_card.dart';
import '../widgets/quick_donate_button.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/stats_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    // HomeCubit may already be loaded (app start / kept-alive tab).
    context.read<HomeCubit>().loadHome();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final local = await UserProfileRepository().getProfile();
    if (mounted && local != null) {
      setState(() => _profile = local);
    }

    final remote = await AuthRepository().syncProfile();
    if (mounted && remote != null) {
      setState(() => _profile = remote);
    }
  }

  String get _displayName {
    if (_profile != null && _profile!.hasName) {
      return _profile!.fullName;
    }
    return 'donor_mock_name'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    context.locale;

    return Scaffold(
      backgroundColor: cs.surface,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: TextStyle(color: cs.onSurface)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<HomeCubit>().loadHome(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is HomeLoaded) {
            return _buildBody(context, state);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeLoaded state) {
    final cs = Theme.of(context).colorScheme;
    final locale = context.locale;

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, state)),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(color: cs.surface),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppSearchBar(
                      hintText: 'search_hint'.tr(),
                      campaigns: state.campaigns,
                      onChanged: (query) =>
                          context.read<HomeCubit>().filterBySearch(query),
                      onSuggestionTap: (suggestion) =>
                          _onSearchSuggestionTap(context, suggestion),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📂 Categories
                  CategoryTabs(
                    categoryKeys: context.read<HomeCubit>().categoriesKeys,
                    selectedKey: state.selectedCategory,
                    onSelect: context.read<HomeCubit>().filterByCategory,
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Image.asset(
                      'assets/image/logo-green.png',
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ⚡ Quick donate
                  QuickDonateButton(
                    onTap: () => openDonateAmountScreen(
                      context,
                      DonationCheckoutArgs(
                        causeTitle: 'quick_donate'.tr(),
                        targetType: DonationTargetType.association,
                      ),
                    ),
                    label: 'quick_donate'.tr(),
                  ),

                  const SizedBox(height: 24),

                  // 📌 Title row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'recent_campaigns'.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.donorAllCampaigns),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'view_all'.tr(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🏷 Campaigns
                  SizedBox(
                    height: CampaignCard.cardHeight + 8,
                    child: state.filteredCampaigns.isEmpty
                        ? Center(
                            child: Text(
                              'no_campaigns'.tr(),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.filteredCampaigns.length,
                            itemBuilder: (context, i) {
                              return HomeCampaignCard(
                                campaign: state.filteredCampaigns[i],
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 24),

                  AssociationMapCard(
                    key: ValueKey('assoc_map_${locale.languageCode}'),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchSuggestionTap(
    BuildContext context,
    SearchSuggestion suggestion,
  ) {
    final cubit = context.read<HomeCubit>();

    if (suggestion.categoryKey != null) {
      cubit.filterByCategory(suggestion.categoryKey!);
      cubit.filterBySearch('');
      return;
    }

    cubit.filterBySearch(suggestion.query);

    if (suggestion.campaign != null) {
      openHomeCampaignDetails(context, suggestion.campaign!);
    }
  }

  Widget _buildHeader(BuildContext context, HomeLoaded state) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),

      child: Column(
        children: [
          const SizedBox(height: 52),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _HomeProfileAvatar(imagePath: _profile?.imagePath),
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
                StatsCard(
                  label: 'volunteers'.tr(),
                  value: '${state.volunteers}',
                ),
                const SizedBox(width: 10),
                StatsCard(label: 'donors'.tr(), value: '${state.donors}'),
                const SizedBox(width: 10),
                StatsCard(
                  label: 'beneficiaries'.tr(),
                  value: '${state.beneficiaries}',
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

class _HomeProfileAvatar extends StatelessWidget {
  const _HomeProfileAvatar({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white,
      backgroundImage: _imageProvider,
      child: _imageProvider == null
          ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary)
          : null,
    );
  }

  ImageProvider? get _imageProvider {
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
