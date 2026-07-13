import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../data/models/donation_model.dart';
import '../widgets/category_card.dart';

class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  void _openCategory(BuildContext context, DonationCategory category) {
    context.push(AppRoutes.donationsList, extra: category);
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(AppRoutes.donorHome),
          ),
          title: Text('donation_categories'.tr()),
          centerTitle: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'choose_cause'.tr(),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'cause_description'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ext.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  childAspectRatio: 0.8,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    CategoryCard(
                      icon: Icons.school,
                      title: 'education'.tr(),
                      subtitle: 'education_desc'.tr(),
                      onDonate: () =>
                          _openCategory(context, DonationCategory.education),
                    ),
                    CategoryCard(
                      icon: Icons.medical_services,
                      title: 'medical'.tr(),
                      subtitle: 'medical_desc'.tr(),
                      onDonate: () =>
                          _openCategory(context, DonationCategory.medical),
                    ),
                    CategoryCard(
                      icon: Icons.face_outlined,
                      title: 'orphans'.tr(),
                      subtitle: 'orphans_desc'.tr(),
                      onDonate: () =>
                          _openCategory(context, DonationCategory.orphans),
                    ),
                    CategoryCard(
                      icon: Icons.volunteer_activism_outlined,
                      title: 'campaigns'.tr(),
                      subtitle: 'campaigns_desc'.tr(),
                      onDonate: () =>
                          context.push(AppRoutes.communityCampaigns),
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
