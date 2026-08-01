import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme_extensions.dart';
import '../../../../core/widgets/custom_button.dart';

class CampaignCard extends StatelessWidget {
  final String title;
  final String category;
  final String image;
  final double progress;
  final double progressPercent;
  final String goal;
  final VoidCallback? onDonateTap;
  final VoidCallback? onTap;

  const CampaignCard({
    super.key,
    required this.title,
    required this.category,
    required this.image,
    required this.progress,
    required this.progressPercent,
    required this.goal,
    this.onDonateTap,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppThemeExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: ext.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔷 Image + Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildImage(image, cs),              ),

              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 🔷 Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Progress Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'progress'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${progressPercent.toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.secondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: cs.surface,
                    valueColor: AlwaysStoppedAnimation(cs.secondary),
                    minHeight: 6,
                  ),
                ),

                const SizedBox(height: 12),

                // Goal + Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'goal'.tr(),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          goal,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),

                    CustomButton(
                      label: 'donate_now'.tr(),
                      onTap: onDonateTap,
                      width: 110,
                      height: 38,
                      variant: ButtonVariant.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildImage(String image, ColorScheme cs) {
    final errorWidget = Container(
      height: 150,
      color: cs.surface,
      child: Icon(Icons.image_outlined, color: cs.onSurface),
    );

    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => errorWidget,
      );
    }

    return Image.network(
      image,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => errorWidget,
    );
  }
}