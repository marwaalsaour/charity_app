import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/cubit/request_cubit.dart';
import '../../logic/states/request_state.dart';
import '../utils/location_labels.dart';
import 'request_dropdown_field.dart';

class RequestLocationFields extends StatelessWidget {
  const RequestLocationFields({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RequestCubit, RequestState>(
      builder: (context, state) {
        final cubit = context.read<RequestCubit>();

        return Column(
          children: [
            RequestDropdownField<int>(
              label: 'governorate'.tr(),
              hint: 'select_governorate'.tr(),
              prefixIcon: Icons.map_outlined,
              value: state.selectedGovernorateId,
              items: state.governorates
                  .map(
                    (g) => DropdownMenuItem<int>(
                      value: g.id,
                      child: Text(
                        LocationLabels.governorate(g.name),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) cubit.changeGovernorate(value);
              },
            ),
            const SizedBox(height: 16),
            RequestDropdownField<int>(
              label: 'city'.tr(),
              hint: state.selectedGovernorateId == null
                  ? 'select_governorate_first'.tr()
                  : 'select_city'.tr(),
              prefixIcon: Icons.location_city_outlined,
              value: state.selectedCityId,
              enabled: state.selectedGovernorateId != null &&
                  !state.isLoadingLocations,
              items: state.cities
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(
                        LocationLabels.region(c.name),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) cubit.changeCity(value);
              },
            ),
            if (state.isLoadingLocations) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (!state.isLoadingLocations &&
                state.governorates.isEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'locations_load_error'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
