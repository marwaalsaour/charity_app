import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/image_upload_box.dart';
import '../../logic/cubit/request_cubit.dart';
import '../widgets/request_form_card.dart';

class MedicalRequestPage extends StatelessWidget {
  MedicalRequestPage({super.key});

  final fullName = TextEditingController();
  final motherName = TextEditingController();
  final contact = TextEditingController();
  final address = TextEditingController();
  final cost = TextEditingController();
  final description = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RequestCubit>();

    return Scaffold(
      appBar: AppBar(title: Text('medical_request_title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          RequestFormCard(
            children: [
              CustomTextField(
                label: 'full_name'.tr(),
                hint: 'enter_full_name'.tr(),
                prefixIcon: Icons.person,
                controller: fullName,
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
                label: 'phone_or_email'.tr(),
                hint: 'phone_hint'.tr(),
                prefixIcon: Icons.phone,
                controller: contact,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'address'.tr(),
                hint: 'address_hint'.tr(),
                prefixIcon: Icons.location_on,
                controller: address,
              ),
              const SizedBox(height: 16),
              ImageUploadBox(
                label: 'id_photo'.tr(),
                hint: 'tap_upload'.tr(),
              ),
              const SizedBox(height: 16),
              ImageUploadBox(
                label: 'medical_report'.tr(),
                hint: 'tap_upload'.tr(),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'description_need'.tr(),
                hint: 'describe_need'.tr(),
                maxLines: 4,
                controller: description,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'treatment_cost'.tr(),
                hint: 'cost_hint'.tr(),
                prefixIcon: Icons.attach_money,
                controller: cost,
                keyboardType: TextInputType.number,
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
                type: 'medical',
                name: fullName.text,
                contact: contact.text,
                address: address.text,
                note: description.text,
                amount: double.tryParse(cost.text),
              );
            },
          ),
        ],
      ),
    );
  }
}
