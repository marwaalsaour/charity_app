import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/ataa_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../notifications/data/notification_helper.dart';
import '../../../volunteer/data/repositories/volunteer_api_repository.dart';
import '../../data/models/community_campaign_model.dart';

class FieldVolunteerScreen extends StatefulWidget {
  const FieldVolunteerScreen({super.key, required this.campaign});

  final CommunityCampaignModel campaign;

  @override
  State<FieldVolunteerScreen> createState() => _FieldVolunteerScreenState();
}

class _FieldVolunteerScreenState extends State<FieldVolunteerScreen> {
  bool _agreedToTerms = false;
  bool _submitting = false;
  final Map<String, Set<String>> _selectedSlots = {};

  static const _days = [
    'day_saturday',
    'day_sunday',
    'day_monday',
    'day_tuesday',
    'day_wednesday',
    'day_thursday',
    'day_friday',
  ];

  static const _slots = [
    'slot_morning',
    'slot_afternoon',
    'slot_evening',
  ];

  void _toggleSlot(String day, String slot) {
    setState(() {
      _selectedSlots.putIfAbsent(day, () => {});
      if (_selectedSlots[day]!.contains(slot)) {
        _selectedSlots[day]!.remove(slot);
        if (_selectedSlots[day]!.isEmpty) _selectedSlots.remove(day);
      } else {
        _selectedSlots[day]!.add(slot);
      }
    });
  }

  bool get _hasSelectedHours =>
      _selectedSlots.values.any((slots) => slots.isNotEmpty);

  String _availabilityText() {
    final parts = <String>[];
    for (final entry in _selectedSlots.entries) {
      final slots = entry.value.map((s) => s.tr()).join(', ');
      parts.add('${entry.key.tr()}: $slots');
    }
    return parts.join(' | ');
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    if (!_agreedToTerms) {
      _showMessage('field_volunteer.terms_required');
      return;
    }
    if (!_hasSelectedHours) {
      _showMessage('field_volunteer.hours_required');
      return;
    }

    final campaignId = widget.campaign.apiId;
    if (campaignId <= 0) {
      _showMessage('donate_error_generic');
      return;
    }

    final availability = _availabilityText();

    setState(() => _submitting = true);
    try {
      // Pending until admin approves via PATCH /campaigns/{id}/volunteers/{volunteerId}
      await VolunteerApiRepository().applyForCampaign(
        campaignId: campaignId,
        notes: availability,
        skills: 'field_volunteer',
      );

      await NotificationHelper.notifyVolunteerSubmitted(
        campaignTitle: widget.campaign.displayTitle,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) {
          final ext = Theme.of(ctx).extension<AppThemeExtension>()!;
          return AlertDialog(
            backgroundColor: ext.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            title: Text('field_volunteer.success_title'.tr()),
            content: Text(
              'field_volunteer.success_message'.tr(),
              style: TextStyle(color: ext.textSecondary, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: Text('ok'.tr()),
              ),
            ],
          );
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('donate_error_generic');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(key.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AtaaAppBar(title: 'field_volunteer.title'.tr()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            widget.campaign.displayTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.campaign.displayLocation,
            style: TextStyle(color: ext.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'field_volunteer.pending_note'.tr(),
            style: TextStyle(color: ext.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          Text(
            'field_volunteer.hours_title'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ..._days.map((day) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ext.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((slot) {
                      final selected =
                          _selectedSlots[day]?.contains(slot) ?? false;
                      return FilterChip(
                        label: Text(slot.tr()),
                        selected: selected,
                        onSelected: (_) => _toggleSlot(day, slot),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text('field_volunteer.terms_agree'.tr()),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: _submitting
                ? '...'
                : 'field_volunteer.submit_application'.tr(),
            onTap: _submitting ? null : _confirm,
            variant: ButtonVariant.accent,
          ),
        ],
      ),
    );
  }
}
