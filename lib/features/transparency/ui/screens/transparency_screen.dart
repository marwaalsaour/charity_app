import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/utils/external_launch_helper.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../profile/data/models/wallet_currencies.dart';
import '../../data/models/transparency_model.dart';
import '../../logic/transparency_cubit.dart';
import '../../logic/transparency_state.dart';

class TransparencyScreen extends StatelessWidget {
  const TransparencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale;
    final path = GoRouterState.of(context).uri.path;

    return Scaffold(
      key: ValueKey('transparency-${locale.languageCode}'),
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AtaaAppBar(
        title: 'transparency_file'.tr(),
        onBack: () => context.go(AppRoutes.homeForPath(path)),
      ),
      body: BlocBuilder<TransparencyCubit, TransparencyState>(
        builder: (context, state) {
          final data = state is TransparencyLoaded
              ? state.data
              : TransparencyData.empty;
          final loading = state is TransparencyLoading ||
              state is TransparencyInitial;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<TransparencyCubit>().refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              children: [
                _HeroCard(),
                const SizedBox(height: 22),
                _StatsSection(stats: data.stats, loading: loading),
                const SizedBox(height: 26),
                _AnnualSection(document: data.annualReport),
                const SizedBox(height: 12),
                _FinancialSection(document: data.financialReport),
                const SizedBox(height: 12),
                _PolicySection(
                  body: data.localizedPolicy(
                    context.locale.languageCode == 'ar',
                  ),
                ),
                const SizedBox(height: 12),
                _VerificationSection(
                  body: data.localizedVerification(
                    context.locale.languageCode == 'ar',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'transparency_hero_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'transparency_intro'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats, required this.loading});

  final TransparencyStats stats;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final locale = context.locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'transparency_stats_title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'transparency_stats_hint'.tr(),
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: ext.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.payments_outlined,
                  color: AppColors.accentDark,
                  label: 'transparency_total_donations'.tr(),
                  value: WalletCurrencies.format(
                    stats.totalDonations,
                    'USD',
                    locale: locale,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.favorite_outline,
                  color: AppColors.primary,
                  label: 'transparency_beneficiaries'.tr(),
                  value: WalletCurrencies.formatAmount(
                    stats.beneficiaries.toDouble(),
                    locale,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.volunteer_activism_outlined,
                  color: const Color(0xFF2A9D8F),
                  label: 'transparency_volunteers'.tr(),
                  value: WalletCurrencies.formatAmount(
                    stats.volunteers.toDouble(),
                    locale,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.campaign_outlined,
                  color: const Color(0xFF457B9D),
                  label: 'transparency_campaigns'.tr(),
                  value: WalletCurrencies.formatAmount(
                    stats.campaigns.toDouble(),
                    locale,
                  ),
                ),
              ),
            ],
          ),
          if (stats.updatedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'transparency_updated_at'.tr(
                namedArgs: {
                  'date': DateFormat.yMMMd(locale.toString()).format(
                    stats.updatedAt!.toLocal(),
                  ),
                },
              ),
              style: TextStyle(fontSize: 12, color: ext.textSecondary),
            ),
          ],
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: ext.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnualSection extends StatelessWidget {
  const _AnnualSection({required this.document});

  final TransparencyDocument document;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final year = document.year ?? DateTime.now().year.toString();

    return _ExpandableDocCard(
      icon: Icons.description_outlined,
      color: AppColors.primary,
      title: 'transparency_annual_title'.tr(),
      subtitle: 'transparency_annual_year'.tr(namedArgs: {'year': year}),
      body: document.localizedSummary(isArabic) ??
          'transparency_annual_body'.tr(),
      fileUrl: document.fileUrl,
    );
  }
}

class _FinancialSection extends StatelessWidget {
  const _FinancialSection({required this.document});

  final TransparencyDocument document;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final period = document.period ??
        document.year ??
        DateTime.now().year.toString();

    return _ExpandableDocCard(
      icon: Icons.account_balance_outlined,
      color: AppColors.accentDark,
      title: 'transparency_financial_title'.tr(),
      subtitle: 'transparency_financial_period'.tr(
        namedArgs: {'period': period},
      ),
      body: document.localizedSummary(isArabic) ??
          'transparency_financial_body'.tr(),
      fileUrl: document.fileUrl,
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({this.body});

  final String? body;

  @override
  Widget build(BuildContext context) {
    return _ExpandableDocCard(
      icon: Icons.policy_outlined,
      color: const Color(0xFF457B9D),
      title: 'transparency_policy_title'.tr(),
      subtitle: 'transparency_policy_subtitle'.tr(),
      body: body ?? 'transparency_policy_body'.tr(),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({this.body});

  final String? body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return _DocumentShell(
      icon: Icons.fact_check_outlined,
      color: const Color(0xFF2A9D8F),
      title: 'transparency_verify_title'.tr(),
      subtitle: 'transparency_verify_subtitle'.tr(),
      children: [
        Text(
          body ?? 'transparency_verify_intro'.tr(),
          style: TextStyle(
            fontSize: 13.5,
            height: 1.6,
            color: ext.textSecondary,
          ),
        ),
        if (body == null) ...[
          const SizedBox(height: 14),
          _VerifyStep(
            number: '1',
            title: 'transparency_verify_step1_title'.tr(),
            body: 'transparency_verify_step1_body'.tr(),
          ),
          _VerifyStep(
            number: '2',
            title: 'transparency_verify_step2_title'.tr(),
            body: 'transparency_verify_step2_body'.tr(),
          ),
          _VerifyStep(
            number: '3',
            title: 'transparency_verify_step3_title'.tr(),
            body: 'transparency_verify_step3_body'.tr(),
          ),
          _VerifyStep(
            number: '4',
            title: 'transparency_verify_step4_title'.tr(),
            body: 'transparency_verify_step4_body'.tr(),
          ),
          _VerifyStep(
            number: '5',
            title: 'transparency_verify_step5_title'.tr(),
            body: 'transparency_verify_step5_body'.tr(),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'transparency_verify_note'.tr(),
          style: TextStyle(
            fontSize: 12.5,
            height: 1.5,
            fontStyle: FontStyle.italic,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}

class _ExpandableDocCard extends StatelessWidget {
  const _ExpandableDocCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.body,
    this.fileUrl,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String body;
  final String? fileUrl;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return _DocumentShell(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      children: [
        Text(
          body,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.65,
            color: ext.textSecondary,
          ),
        ),
        if (fileUrl != null && fileUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          CustomButton(
            label: 'transparency_view_file'.tr(),
            icon: Icons.picture_as_pdf_outlined,
            variant: ButtonVariant.outline,
            onTap: () => ExternalLaunchHelper.openUrl(context, fileUrl!),
          ),
        ],
      ],
    );
  }
}

class _DocumentShell extends StatelessWidget {
  const _DocumentShell({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: ext.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          initiallyExpanded: false,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: ext.textSecondary),
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

class _VerifyStep extends StatelessWidget {
  const _VerifyStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: ext.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
