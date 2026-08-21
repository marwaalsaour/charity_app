/// Skill keys must match GitHub Volunteer::skillsList().
class VolunteerSkills {
  VolunteerSkills._();

  /// apiKey → translation key for UI labels.
  static const Map<String, String> catalog = {
    'design': 'skill_design',
    'translation': 'skill_translation',
    'accounting': 'skill_accounting',
    'hr': 'skill_hr',
    'photography': 'skill_photography',
    'video_editing': 'skill_editing',
    'counseling_mental_health': 'skill_counseling',
    'child_psychosocial_support': 'skill_child_support',
    'public_relations': 'skill_pr',
    'field_work': 'skill_field_work',
    'first_aid': 'skill_first_aid',
    'medical_support': 'skill_medical_support',
    'teaching': 'skill_teaching',
    'logistics': 'skill_logistics',
    'event_management': 'skill_event_management',
    'social_media': 'skill_social_media',
    'fundraising': 'skill_fundraising',
    'legal_support': 'skill_legal_support',
    'it_support': 'skill_it_support',
    'cooking_food_prep': 'skill_cooking',
  };

  static List<String> get apiKeys => catalog.keys.toList();

  static const int maxSelection = 2;

  static const Set<String> requiringPortfolio = {
    'design',
    'translation',
    'photography',
    'video_editing',
    'public_relations',
  };

  static bool needsPortfolio(Set<String> selected) =>
      selected.any(requiringPortfolio.contains);

  static String labelKey(String apiKey) =>
      catalog[apiKey] ?? apiKey;
}

class SyrianGovernorates {
  SyrianGovernorates._();

  /// Fallback labels when /governorates is unavailable.
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
