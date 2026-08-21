import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/file_share_helper.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../volunteer/data/repositories/volunteer_api_repository.dart';
import '../../data/models/volunteer_activity_model.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/volunteer_activity_repository.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen> {
  static const _requiredHours = 100;

  final _repository = VolunteerActivityRepository();
  late Future<({double totalHours, List<CampaignVolunteerSummary> campaigns})>
      _dataFuture;
  var _downloading = false;
  var _lastTotalHours = 0.0;

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

  Future<({double totalHours, List<CampaignVolunteerSummary> campaigns})>
      _fetchData() async {
    try {
      final totalHours = await _repository.getTotalHours();
      final campaigns = await _repository.getCampaignSummaries();
      return (totalHours: totalHours, campaigns: campaigns);
    } catch (_) {
      return (
        totalHours: 0.0,
        campaigns: <CampaignVolunteerSummary>[],
      );
    }
  }

  Future<void> _downloadCertificate() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      var hours = _lastTotalHours;
      try {
        final remoteHours = await _repository.getTotalHours();
        if (remoteHours > 0) hours = remoteHours;
      } catch (_) {}
      if (hours < _requiredHours) {
        throw const ApiException(
          'volunteer_certificate_hours_required',
          statusCode: 403,
        );
      }
      final profile = await UserProfileRepository().getProfile();
      final name = profile?.fullName.trim() ?? '';
      final file = await VolunteerApiRepository().downloadCertificate(
        volunteerName: name.isNotEmpty ? name : 'ATAA',
        hours: hours,
        isArabic: context.locale.languageCode == 'ar',
        userId: profile?.id,
        phone: profile?.phone,
        email: profile?.email,
      );
      if (!mounted) return;
      await FileShareHelper.shareFile(
        path: file.path,
        filename: 'ataa-volunteer-certificate.pdf',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final key = _snackbarKey(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(key))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('volunteer_certificate_error'))),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _snackbarKey(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('route') || lower.contains('could not be found')) {
      return 'volunteer_certificate_error';
    }
    if (lower.contains('100') && lower.contains('hour')) {
      return 'volunteer_certificate_hours_required';
    }
    if (lower.contains('volunteer profile')) {
      return 'volunteer_certificate_not_found';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: ValueKey('my_activities_${locale.languageCode}'),
      appBar: AtaaAppBar(title: context.tr('my_activities')),
      body: FutureBuilder<
          ({double totalHours, List<CampaignVolunteerSummary> campaigns})>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: cs.primary));
          }

          final totalHours = snapshot.data?.totalHours ?? 0;
          final campaigns = snapshot.data?.campaigns ?? [];
          if (snapshot.hasData) {
            _lastTotalHours = totalHours;
          }
          final canDownload = totalHours >= _requiredHours;

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: () async => _load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _HoursCard(
                  totalHours: totalHours,
                  requiredHours: _requiredHours,
                ),
                const SizedBox(height: 12),
                if (canDownload)
                  CustomButton(
                    label: context.tr('volunteer_certificate_download'),
                    icon: Icons.workspace_premium_outlined,
                    variant: ButtonVariant.primary,
                    height: 52,
                    isLoading: _downloading,
                    onTap: _downloadCertificate,
                  )
                else
                  _CertificateLockedNote(
                    totalHours: totalHours,
                    requiredHours: _requiredHours,
                  ),
                const SizedBox(height: 28),
                Text(
                  context.tr('my_campaigns_section'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (campaigns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      context.tr('no_activities_yet'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context)
                            .extension<AppThemeExtension>()!
                            .textSecondary,
                      ),
                    ),
                  )
                else
                  ...campaigns.map(
                    (campaign) => _CampaignActivityCard(campaign: campaign),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  const _HoursCard({
    required this.totalHours,
    required this.requiredHours,
  });

  final double totalHours;
  final int requiredHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final ext = theme.extension<AppThemeExtension>()!;
    final progress = (totalHours / requiredHours).clamp(0.0, 1.0);
    final reached = totalHours >= requiredHours;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: reached ? AppColors.success.withValues(alpha: 0.45) : ext.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.schedule_rounded, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('total_volunteer_hours'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ext.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        'hours_count',
                        namedArgs: {'count': _formatHours(totalHours)},
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('volunteer_hours_admin_hint'),
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: ext.progressBg,
              valueColor: AlwaysStoppedAnimation(
                reached ? AppColors.success : AppColors.progressFill,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'volunteer_certificate_progress',
              namedArgs: {
                'current': _formatHours(totalHours),
                'required': '$requiredHours',
              },
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: reached ? AppColors.success : ext.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateLockedNote extends StatelessWidget {
  const _CertificateLockedNote({
    required this.totalHours,
    required this.requiredHours,
  });

  final double totalHours;
  final int requiredHours;

  @override
  Widget build(BuildContext context) {
    final remaining = (requiredHours - totalHours).clamp(0.0, requiredHours.toDouble());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(
                'volunteer_certificate_locked',
                namedArgs: {'hours': _formatHours(remaining)},
              ),
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
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
    final localeCode = context.locale.languageCode;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final date = DateFormat.yMMMd(localeCode).format(campaign.lastDate);
    final title = campaign.localizedTitle(localeCode);
    final status = campaign.statusLabel;
    final typeLabel = campaign.typeLabel;
    final location = campaign.localizedLocation(localeCode);
    final subtitle = status.isNotEmpty
        ? status
        : (typeLabel.isNotEmpty ? typeLabel : location);

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
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: campaign.status.toLowerCase() == 'pending'
                          ? Colors.orange.shade700
                          : campaign.status.toLowerCase() == 'approved'
                              ? Colors.green.shade700
                              : ext.textSecondary,
                    ),
                  ),
                ],
                if (typeLabel.isNotEmpty && status.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    typeLabel,
                    style: TextStyle(fontSize: 12, color: ext.textSecondary),
                  ),
                ],
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
              context.tr(
                'hours_count',
                namedArgs: {'count': '${campaign.totalHours}'},
              ),
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

String _formatHours(double hours) {
  if (!hours.isFinite) return '0';
  if (hours.truncateToDouble() == hours) return hours.toStringAsFixed(0);
  return hours.toStringAsFixed(1);
}
