class VolunteerSkills {
  VolunteerSkills._();

  static const List<String> keys = [
    'skill_design',
    'skill_translation',
    'skill_accounting',
    'skill_hr',
    'skill_photography',
    'skill_editing',
    'skill_counseling',
    'skill_child_support',
    'skill_pr',
    'skill_field_work',
  ];

  static const int maxSelection = 2;

  /// Skills that require a CV or portfolio attachment.
  static const Set<String> requiringPortfolio = {
    'skill_design',
    'skill_translation',
    'skill_photography',
    'skill_editing',
    'skill_pr',
  };

  static bool needsPortfolio(Set<String> selected) =>
      selected.any(requiringPortfolio.contains);
}

class SyrianGovernorates {
  SyrianGovernorates._();

  static const List<String> keys = [
    'gov_damascus',
    'gov_rural_damascus',
    'gov_aleppo',
    'gov_homs',
    'gov_hama',
    'gov_latakia',
    'gov_tartus',
    'gov_idlib',
    'gov_deir_ez_zor',
    'gov_raqqa',
    'gov_hasakah',
    'gov_suwayda',
    'gov_daraa',
    'gov_quneitra',
  ];
}
