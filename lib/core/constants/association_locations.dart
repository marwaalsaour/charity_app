import 'package:latlong2/latlong.dart';

class AssociationLocation {
  final String nameKey;
  final LatLng point;

  const AssociationLocation({
    required this.nameKey,
    required this.point,
  });
}

/// ATAA centers across Syria. Update coordinates when official addresses change.
class AssociationLocations {
  AssociationLocations._();

  static const LatLng syriaCenter = LatLng(34.85, 37.55);
  static const double overviewZoom = 6.35;

  static const List<AssociationLocation> centers = [
    AssociationLocation(
      nameKey: 'assoc_loc_damascus',
      point: LatLng(33.5138, 36.2765),
    ),
    AssociationLocation(
      nameKey: 'assoc_loc_aleppo',
      point: LatLng(36.2021, 37.1343),
    ),
    AssociationLocation(
      nameKey: 'assoc_loc_homs',
      point: LatLng(34.7324, 36.7137),
    ),
    AssociationLocation(
      nameKey: 'assoc_loc_hama',
      point: LatLng(35.1318, 36.7578),
    ),
    AssociationLocation(
      nameKey: 'assoc_loc_latakia',
      point: LatLng(35.5317, 35.7900),
    ),
  ];
}
