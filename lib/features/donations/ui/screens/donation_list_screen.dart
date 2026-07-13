import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme_extensions.dart';
import '../../data/models/donation_model.dart';import '../../data/repositories/donation_repository.dart';
import '../../logic/donation_cubit.dart';
import '../../logic/donation_state.dart';
import '../widgets/donation_card.dart';

class DonationListScreen extends StatelessWidget {
  const DonationListScreen({super.key, required this.category});

  final DonationCategory category;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return BlocProvider(
      create: (_) =>
          DonationCubit(DonationRepository())..loadDonations(category),
      child: Scaffold(
        appBar: AppBar(
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(category.titleKey.tr()),
          centerTitle: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: BlocBuilder<DonationCubit, DonationState>(
          builder: (context, state) {
            if (state is DonationLoading) {
              return Center(
                child: CircularProgressIndicator(color: cs.primary),
              );
            }

            if (state is DonationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 12),
                    Text(
                      'donation_load_error'.tr(),
                      style: TextStyle(color: cs.onSurface),
                    ),                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context
                          .read<DonationCubit>()
                          .loadDonations(category),
                      child: Text('retry'.tr()),
                    ),
                  ],
                ),
              );
            }

            if (state is DonationLoaded) {
              if (state.items.isEmpty) {
                return Center(
                  child: Text(
                    'no_donations'.tr(),
                    style: TextStyle(color: ext.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  return DonationCard(donation: state.items[index]);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
