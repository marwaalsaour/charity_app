import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/image_upload_box.dart';
import '../../logic/cubit/request_cubit.dart';
import '../widgets/request_form_card.dart';

class OrphanRequestPage extends StatelessWidget {
  OrphanRequestPage({super.key});

  final name = TextEditingController();
  final motherName = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RequestCubit>();

    return Scaffold(
      appBar: AppBar(title: Text('orphan_request_title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          RequestFormCard(
            children: [
              CustomTextField(
                label: 'child_full_name'.tr(),
                hint: 'enter_full_name'.tr(),
                prefixIcon: Icons.person,
                controller: name,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'mother_name'.tr(),
                hint: 'enter_mother_name'.tr(),
                prefixIcon: Icons.woman,
                controller: motherName,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'address'.tr(),
                hint: 'address_hint'.tr(),
                prefixIcon: Icons.location_on,
                controller: address,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'phone'.tr(),
                hint: 'phone_hint'.tr(),
                prefixIcon: Icons.phone,
                controller: phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              ImageUploadBox(
                label: 'family_booklet'.tr(),
                hint: 'tap_upload'.tr(),
              ),
              const SizedBox(height: 16),
              ImageUploadBox(
                label: 'death_certificate'.tr(),
                hint: 'tap_upload'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'submit_request'.tr(),
            icon: Icons.favorite,
            isLoading: cubit.state.isLoading,
            onTap: () {
              cubit.submitForm(
                type: 'orphan',
                name: name.text,
                contact: phone.text,
                address: address.text,
                note: '',
              );
            },
          ),
        ],
      ),
    );
  }
}
