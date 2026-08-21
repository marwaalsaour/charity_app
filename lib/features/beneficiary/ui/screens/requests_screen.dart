import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../requests/logic/cubit/request_cubit.dart';
import '../../../requests/logic/states/request_state.dart';
import '../../../requests/ui/utils/request_sheet_helper.dart';
import '../widgets/beneficiary_case_card.dart';

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
                  ...requests.map(
                    (item) => BeneficiaryCaseCard(item: item),
                  ),
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
