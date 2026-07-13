import 'package:flutter/material.dart';

import '../../data/models/donation_model.dart';

class DonationCoverImage extends StatelessWidget {
  const DonationCoverImage({
    super.key,
    required this.donation,
    this.height,
    this.aspectRatio,
    this.borderRadius,
  });

  final DonationModel donation;
  final double? height;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = donation.image.isNotEmpty
        ? donation.image
        : 'https://picsum.photos/600/400?random=${donation.id}';

    Widget image;
    if (imageUrl.startsWith('assets/')) {
      image = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    } else {
      image = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      );
    }

    if (aspectRatio != null) {
      image = AspectRatio(aspectRatio: aspectRatio!, child: image);
    } else if (height != null) {
      image = SizedBox(height: height, width: double.infinity, child: image);
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _fallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primary.withValues(alpha: 0.12),
      child: Icon(
        donation.category.fallbackIcon,
        size: 56,
        color: cs.primary,
      ),
    );
  }
}
