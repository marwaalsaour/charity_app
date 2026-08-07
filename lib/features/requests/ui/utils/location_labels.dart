import 'package:easy_localization/easy_localization.dart';

/// Maps English API location names to translation keys.
class LocationLabels {
  LocationLabels._();

  static const Map<String, String> _governorates = {
    'damascus': 'gov_damascus',
    'rural damascus': 'gov_rural_damascus',
    'aleppo': 'gov_aleppo',
    'homs': 'gov_homs',
    'hama': 'gov_hama',
    'latakia': 'gov_latakia',
    'tartus': 'gov_tartus',
    'idlib': 'gov_idlib',
    'deir ez-zor': 'gov_deir_ez_zor',
    'deir ez zor': 'gov_deir_ez_zor',
    'raqqa': 'gov_raqqa',
    'hasakah': 'gov_hasakah',
    'suwayda': 'gov_suwayda',
    'daraa': 'gov_daraa',
    'quneitra': 'gov_quneitra',
  };

  static const Map<String, String> _regions = {
    'mezzeh': 'region_mezzeh',
    'kafr sousa': 'region_kafr_sousa',
    'bab touma': 'region_bab_touma',
    'midan': 'region_midan',
    'qaboun': 'region_qaboun',
    'barzeh': 'region_barzeh',
    'dummar': 'region_dummar',
    'jamiliyah': 'region_jamiliyah',
    'furqan': 'region_furqan',
    'shahbaa': 'region_shahbaa',
    'sulaimaniyah': 'region_sulaimaniyah',
    'hamdaniyah': 'region_hamdaniyah',
    'zahraa': 'region_zahraa',
    'salihin': 'region_salihin',
    'al-waer': 'region_al_waer',
    'bab hud': 'region_bab_hud',
    'zahrawi': 'region_zahrawi',
    'inshaat': 'region_inshaat',
    'karm al-zaytoun': 'region_karm_al_zaytoun',
    'khalidiyah': 'region_khalidiyah',
    'bab al-sebaa': 'region_bab_al_sebaa',
    'al-raml al-janoubi': 'region_al_raml_al_janoubi',
    'al-raml al-shamali': 'region_al_raml_al_shamali',
    'zeraa': 'region_zeraa',
    'saliba': 'region_saliba',
    'sheikh daher': 'region_sheikh_daher',
    'al-dalia': 'region_al_dalia',
    'al-qalaa': 'region_al_qalaa',
    'al-hader': 'region_al_hader',
    'al-jarajima': 'region_al_jarajima',
    'al-sabboura': 'region_al_sabboura',
    'kazo': 'region_kazo',
    'al-midan': 'region_al_midan',
    'al-sharia': 'region_al_sharia',
    'al-janayen': 'region_al_janayen',
    'daraa al-balad': 'region_daraa_al_balad',
    'daraa al-mahatta': 'region_daraa_al_mahatta',
    'tafas': 'region_tafas',
    'inkhil': 'region_inkhil',
    'al-sanamayn': 'region_al_sanamayn',
    'nawa': 'region_nawa',
    'jasim': 'region_jasim',
    'saraqib': 'region_saraqib',
    'maarat al-numan': 'region_maarat_al_numan',
    'ariha': 'region_ariha',
    'harim': 'region_harim',
    'jisr al-shughur': 'region_jisr_al_shughur',
    'binnish': 'region_binnish',
    'kafr nabl': 'region_kafr_nabl',
  };

  static String governorate(String apiName) {
    final key = _governorates[apiName.trim().toLowerCase()];
    return key != null ? key.tr() : apiName;
  }

  static String region(String apiName) {
    final key = _regions[apiName.trim().toLowerCase()];
    return key != null ? key.tr() : apiName;
  }
}
