import 'package:flutter/material.dart';

import '../core/icons_map.dart';

/// Petit avatar circulaire coloré avec une icône, utilisé pour les
/// comptes et les catégories dans toute l'application.
class IconAvatar extends StatelessWidget {
  const IconAvatar({
    super.key,
    required this.iconKey,
    required this.colorHex,
    this.size = 44,
  });

  final String iconKey;
  final String colorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(iconFromKey(iconKey), color: color, size: size * 0.5),
    );
  }
}
