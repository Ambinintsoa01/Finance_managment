import 'package:flutter/material.dart';

import '../core/icons_map.dart';

/// Sélecteur combiné couleur + icône utilisé dans les formulaires
/// de création de compte / catégorie.
class ColorIconPicker extends StatelessWidget {
  const ColorIconPicker({
    super.key,
    required this.colors,
    required this.icons,
    required this.selectedColor,
    required this.selectedIcon,
    required this.onColorChanged,
    required this.onIconChanged,
  });

  final List<String> colors;
  final List<String> icons;
  final String selectedColor;
  final String selectedIcon;
  final ValueChanged<String> onColorChanged;
  final ValueChanged<String> onIconChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Couleur', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((hex) {
            final isSelected = hex == selectedColor;
            return GestureDetector(
              onTap: () => onColorChanged(hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorFromHex(hex),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.black87, width: 2.5)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Icône', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: icons.map((key) {
            final isSelected = key == selectedIcon;
            final color = colorFromHex(selectedColor);
            return GestureDetector(
              onTap: () => onIconChanged(key),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: color, width: 2) : null,
                ),
                child: Icon(iconFromKey(key), color: isSelected ? color : Colors.grey.shade600),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
