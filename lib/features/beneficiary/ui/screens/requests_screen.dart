import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../requests/data/models/benefit_request_models.dart';
import '../../../requests/logic/cubit/request_cubit.dart';
import '../../../requests/logic/states/request_state.dart';
import '../../../requests/ui/utils/request_sheet_helper.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AuthRepository().syncProfile();
      if (!mounted) return;
      await context.read<RequestCubit>().loadMyRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text('my_requests'.tr())),
      body: RefreshIndicator(
        onRefresh: () => context.read<RequestCubit>().loadMyRequests(),
        child: BlocBuilder<RequestCubit, RequestState>(
          builder: (context, state) {
            final requests = state.myRequests;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'requests_screen_desc'.tr(),
                  style: TextStyle(color: ext.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 20),
                if (state.isLoadingRequests && requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'no_requests_yet'.tr(),
                        style: TextStyle(color: ext.textSecondary),
                      ),
                    ),
                  )
                else
                  ...requests.map((item) => _RequestItem(item: item)),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'new_request'.tr(),
                  icon: Icons.add,
                  variant: ButtonVariant.accent,
                  onTap: () => showBeneficiaryRequestSheet(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  const _RequestItem({required this.item});

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
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.displayTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: ext.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                item.isApproved
                    ? Icons.check_circle
                    : item.isRejected
                        ? Icons.cancel
                        : Icons.schedule,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(fontSize: 13, color: color),
              ),
              const Spacer(),
              Text(
                DateFormat.yMMMd(context.locale.languageCode)
                    .format(item.createdAt),
                style: TextStyle(fontSize: 12, color: ext.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
