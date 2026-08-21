import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../data/models/volunteer_activity_model.dart';
import '../../data/repositories/volunteer_activity_repository.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  final _repository = VolunteerActivityRepository();
  late Future<({int totalHours, List<CampaignVolunteerSummary> campaigns})>
      _dataFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  Future<({int totalHours, List<CampaignVolunteerSummary> campaigns})>
      _fetchData() async {
    final totalHours = await _repository.getTotalHours();
    final campaigns = await _repository.getCampaignSummaries();
    return (totalHours: totalHours, campaigns: campaigns);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AtaaAppBar(title: 'my_activities'.tr()),
      body: FutureBuilder<
          ({int totalHours, List<CampaignVolunteerSummary> campaigns})>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          final data = snapshot.data;
          final totalHours = data?.totalHours ?? 0;
          final campaigns = data?.campaigns ?? [];

          if (campaigns.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      size: 56,
                      color: ext.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_activities_yet'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: ext.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _TotalHoursCard(totalHours: totalHours),
              const SizedBox(height: 24),
              Text(
                'my_campaigns_section'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ...campaigns.map(
                (campaign) => _CampaignActivityCard(campaign: campaign),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalHoursCard extends StatelessWidget {
  const _TotalHoursCard({required this.totalHours});

  final int totalHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
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
                  'total_volunteer_hours'.tr().toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ext.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'hours_count'.tr(namedArgs: {'count': '$totalHours'}),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.schedule,
            size: 36,
            color: AppColors.accent.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

class _CampaignActivityCard extends StatelessWidget {
  const _CampaignActivityCard({required this.campaign});

  final CampaignVolunteerSummary campaign;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final date = DateFormat.yMMMd(context.locale.languageCode).format(
      campaign.lastDate,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(Icons.campaign_outlined, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.displayTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                if (campaign.status.isNotEmpty)
                  Text(
                    campaign.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: campaign.status.toLowerCase() == 'pending'
                          ? Colors.orange.shade700
                          : campaign.status.toLowerCase() == 'approved'
                              ? Colors.green.shade700
                              : ext.textSecondary,
                    ),
                  )
                else
                  Text(
                    campaign.displayLocation,
                    style: TextStyle(fontSize: 12, color: ext.textSecondary),
                  ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: ext.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'hours_count'.tr(namedArgs: {'count': '${campaign.totalHours}'}),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
