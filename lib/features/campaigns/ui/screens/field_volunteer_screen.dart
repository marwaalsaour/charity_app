import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../profile/data/models/volunteer_activity_model.dart';
import '../../../profile/data/repositories/volunteer_activity_repository.dart';
import '../../data/models/community_campaign_model.dart';

class FieldVolunteerScreen extends StatefulWidget {
  const FieldVolunteerScreen({super.key, required this.campaign});

  final CommunityCampaignModel campaign;

  @override
  State<FieldVolunteerScreen> createState() => _FieldVolunteerScreenState();
}

class _FieldVolunteerScreenState extends State<FieldVolunteerScreen> {
  bool _agreedToTerms = false;
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

  void _confirm() async {
    if (!_agreedToTerms) {
      _showMessage('field_volunteer.terms_required');
      return;
    }
    if (!_hasSelectedHours) {
      _showMessage('field_volunteer.hours_required');
      return;
    }

    final slotCount =
        _selectedSlots.values.fold<int>(0, (sum, slots) => sum + slots.length);
    final hours = VolunteerActivityRepository.hoursFromSlotCount(slotCount);

    await VolunteerActivityRepository().saveActivity(
      VolunteerActivityModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        campaignId: widget.campaign.id,
        campaignTitleKey: widget.campaign.titleKey,
        locationKey: widget.campaign.locationKey,
        hours: hours,
        date: DateTime.now(),
      ),
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
  }

  void _showMessage(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(key.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text('field_volunteer.title'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ext.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: ext.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'field_volunteer.campaign_label'.tr(),
                  style: TextStyle(fontSize: 12, color: ext.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.campaign.titleKey.tr(),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.campaign.locationKey.tr(),
                  style: TextStyle(fontSize: 13, color: ext.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'field_volunteer.terms_title'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ext.inputFill,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: _agreedToTerms ? cs.primary : ext.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: cs.primary,
                    onChanged: (v) =>
                        setState(() => _agreedToTerms = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'field_volunteer.terms_agree'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'field_volunteer.hours_title'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'field_volunteer.hours_hint'.tr(),
            style: TextStyle(fontSize: 13, color: ext.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._days.map((day) => _DayScheduleCard(
                dayKey: day,
                slots: _slots,
                selected: _selectedSlots[day] ?? {},
                onToggle: (slot) => _toggleSlot(day, slot),
              )),
          const SizedBox(height: 28),
          CustomButton(
            label: 'field_volunteer.confirm_attendance'.tr(),
            variant: ButtonVariant.primary,
            icon: Icons.check_circle_outline,
            height: 54,
            onTap: _confirm,
          ),
        ],
      ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  const _DayScheduleCard({
    required this.dayKey,
    required this.slots,
    required this.selected,
    required this.onToggle,
  });

  final String dayKey;
  final List<String> slots;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayKey.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              final isSelected = selected.contains(slot);
              return FilterChip(
                label: Text(slot.tr()),
                selected: isSelected,
                onSelected: (_) => onToggle(slot),
                selectedColor: AppColors.accent.withValues(alpha: 0.35),
                checkmarkColor: AppColors.primaryDark,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: cs.onSurface,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.accent : ext.border,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
