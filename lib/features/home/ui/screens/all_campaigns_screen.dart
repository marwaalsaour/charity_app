import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../logic/home_cubit.dart';
import '../../logic/home_state.dart';
import '../widgets/category_tabs.dart';
import '../widgets/home_campaign_card.dart';

class AllCampaignsScreen extends StatelessWidget {
  const AllCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final locale = context.locale;

    return Scaffold(
      appBar: AtaaAppBar(title: context.tr('all_campaigns')),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is! HomeLoaded) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          final campaigns = state.filteredCampaigns;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              CategoryTabs(
                categoryKeys: context.read<HomeCubit>().categoriesKeys,
                selectedKey: state.selectedCategory,
                onSelect: context.read<HomeCubit>().filterByCategory,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: campaigns.isEmpty
                    ? Center(
                        child: Text(
                          'no_campaigns'.tr(),
                          key: ValueKey('all_empty_${locale.languageCode}'),
                          style: TextStyle(color: ext.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: campaigns.length,
                        itemBuilder: (context, index) {
                          return HomeCampaignCard(
                            campaign: campaigns[index],
                            fullWidth: true,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
