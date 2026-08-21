import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/auth/user_role.dart';
import '../../../../core/auth/user_role_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/constants/association_locations.dart';
import '../../../../core/router/app_routes.dart';

class AssociationMapCard extends StatefulWidget {
  const AssociationMapCard({super.key, this.horizontalPadding = 16});

  final double horizontalPadding;

  @override
  State<AssociationMapCard> createState() => _AssociationMapCardState();
}

class _AssociationMapCardState extends State<AssociationMapCard> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    LatLng center = AssociationLocations.syriaCenter;
    var zoom = AssociationLocations.overviewZoom;
    try {
      center = _controller.camera.center;
      zoom = _controller.camera.zoom;
    } catch (_) {}

    final role = context.read<UserRoleCubit>().state;
    context.push(
      role == UserRole.beneficiary
          ? AppRoutes.beneficiaryAssociationMap
          : AppRoutes.associationMap,
      extra: {'lat': center.latitude, 'lng': center.longitude, 'zoom': zoom},
    );
  }

  void _zoomBy(double delta) {
    try {
      final camera = _controller.camera;
      _controller.move(camera.center, (camera.zoom + delta).clamp(5.0, 16.0));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = locale.languageCode == 'ar';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('association_locations_title'),
              key: ValueKey('map_title_${locale.languageCode}'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: ext.cardBackground,
              elevation: isDark ? 0 : 3,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _openFullscreen,
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  height: 248,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        IgnorePointer(
                          child: _ThemedAssociationMap(
                            key: ValueKey('home_map_${locale.languageCode}'),
                            controller: _controller,
                            initialCenter: AssociationLocations.syriaCenter,
                            initialZoom: AssociationLocations.overviewZoom,
                            interactiveFlags: InteractiveFlag.none,
                            showLabels: true,
                          ),
                        ),
                        PositionedDirectional(
                          end: 10,
                          top: 10,
                          child: Column(
                            children: [
                              _MapIconButton(
                                icon: Icons.add_rounded,
                                onTap: () => _zoomBy(1),
                              ),
                              const SizedBox(height: 8),
                              _MapIconButton(
                                icon: Icons.remove_rounded,
                                onTap: () => _zoomBy(-1),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                const _CenterPin(selected: true, compact: true),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.tr('association_map_centers_count'),
                                    key: ValueKey(
                                      'map_count_${locale.languageCode}',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssociationMapFullscreen extends StatefulWidget {
  const AssociationMapFullscreen({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
  });

  final LatLng initialCenter;
  final double initialZoom;

  factory AssociationMapFullscreen.fromRouterExtra(Object? extra) {
    var lat = AssociationLocations.syriaCenter.latitude;
    var lng = AssociationLocations.syriaCenter.longitude;
    var zoom = AssociationLocations.overviewZoom;
    if (extra is Map) {
      lat = (extra['lat'] as num?)?.toDouble() ?? lat;
      lng = (extra['lng'] as num?)?.toDouble() ?? lng;
      zoom = (extra['zoom'] as num?)?.toDouble() ?? zoom;
    }
    return AssociationMapFullscreen(
      initialCenter: LatLng(lat, lng),
      initialZoom: zoom,
    );
  }

  @override
  State<AssociationMapFullscreen> createState() =>
      _AssociationMapFullscreenState();
}

class _AssociationMapFullscreenState extends State<AssociationMapFullscreen> {
  final _controller = MapController();
  AssociationLocation? _selected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() {
    final role = context.read<UserRoleCubit>().state;
    context.go(role?.homeRoute ?? AppRoutes.donorHome);
  }

  void _zoomBy(double delta) {
    try {
      final camera = _controller.camera;
      _controller.move(camera.center, (camera.zoom + delta).clamp(5.0, 18.0));
    } catch (_) {}
  }

  void _goTo(AssociationLocation location) {
    _controller.move(location.point, 13);
    setState(() => _selected = location);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = locale.languageCode == 'ar';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _goHome();
      },
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: cs.surface,
          body: Stack(
            children: [
              _ThemedAssociationMap(
                key: ValueKey('fs_map_${locale.languageCode}'),
                controller: _controller,
                initialCenter: widget.initialCenter,
                initialZoom: widget.initialZoom,
                interactiveFlags:
                    InteractiveFlag.drag |
                    InteractiveFlag.flingAnimation |
                    InteractiveFlag.pinchMove |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
                selected: _selected,
                showLabels: true,
                onMarkerTap: (location) => setState(() => _selected = location),
                onTap: () => setState(() => _selected = null),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? Colors.black : AppColors.primaryDark)
                            .withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 18),
                      child: Row(
                        children: [
                          _MapIconButton(
                            icon: Icons.arrow_back_rounded,
                            matchTextDirection: true,
                            tooltip: context.tr('association_map_back_home'),
                            onTap: _goHome,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr('association_locations_title'),
                              key: ValueKey('map_fs_${locale.languageCode}'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: 14,
                top: MediaQuery.paddingOf(context).top + 66,
                child: Column(
                  children: [
                    _MapIconButton(
                      icon: Icons.add_rounded,
                      onTap: () => _zoomBy(1),
                    ),
                    const SizedBox(height: 8),
                    _MapIconButton(
                      icon: Icons.remove_rounded,
                      onTap: () => _zoomBy(-1),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selected != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: ext.cardBackground,
                              borderRadius: BorderRadius.circular(
                                AppRadius.large,
                              ),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.28 : 0.1,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const _CenterPin(selected: true, compact: true),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('association_center_badge'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: ext.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        context.tr(_selected!.nameKey),
                                        key: ValueKey(
                                          'sel_${locale.languageCode}_'
                                          '${_selected!.nameKey}',
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: AssociationLocations.centers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final location =
                                  AssociationLocations.centers[index];
                              final selected =
                                  _selected?.nameKey == location.nameKey;
                              return ChoiceChip(
                                key: ValueKey(
                                  'chip_${location.nameKey}_${locale.languageCode}',
                                ),
                                avatar: Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: selected
                                      ? AppColors.primaryDark
                                      : AppColors.accentDark,
                                ),
                                label: Text(
                                  context.tr(location.nameKey),
                                  key: ValueKey(
                                    'chip_${location.nameKey}_${locale.languageCode}',
                                  ),
                                ),
                                selected: selected,
                                onSelected: (_) => _goTo(location),
                                selectedColor: AppColors.accent,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? AppColors.primaryDark
                                      : cs.onSurface,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemedAssociationMap extends StatelessWidget {
  const _ThemedAssociationMap({
    super.key,
    required this.controller,
    required this.initialCenter,
    required this.initialZoom,
    required this.interactiveFlags,
    this.onTap,
    this.onMarkerTap,
    this.selected,
    this.showLabels = false,
  });

  final MapController controller;
  final LatLng initialCenter;
  final double initialZoom;
  final int interactiveFlags;
  final VoidCallback? onTap;
  final ValueChanged<AssociationLocation>? onMarkerTap;
  final AssociationLocation? selected;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale;

    return FlutterMap(
      key: ValueKey('flutter_map_${locale.languageCode}_$isDark'),
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: 5,
        maxZoom: 18,
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.authHeaderBackground,
        interactionOptions: InteractionOptions(flags: interactiveFlags),
        onTap: (_, _) => onTap?.call(),
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
              : 'https://basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.charity_app',
        ),
        MarkerLayer(
          key: ValueKey('markers_${locale.languageCode}'),
          markers: AssociationLocations.centers.map((location) {
            final isSelected = selected?.nameKey == location.nameKey;
            return Marker(
              point: location.point,
              width: showLabels ? 168 : 52,
              height: showLabels ? 78 : 56,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () => onMarkerTap?.call(location),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CenterPin(selected: isSelected),
                    if (showLabels) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardBg
                              : Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          context.tr(location.nameKey),
                          key: ValueKey(
                            '${location.nameKey}_${locale.languageCode}',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin({this.selected = false, this.compact = false});

  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : (selected ? 46.0 : 40.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!compact)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(
                  alpha: selected ? 0.28 : 0.16,
                ),
              ),
            ),
          Icon(
            Icons.location_on_rounded,
            size: size,
            color: AppColors.accent,
            shadows: const [
              Shadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          Positioned(
            top: size * 0.22,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.matchTextDirection = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool matchTextDirection;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = Material(
      color: isDark ? AppColors.darkCardBg : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
            textDirection: matchTextDirection
                ? Directionality.of(context)
                : null,
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
