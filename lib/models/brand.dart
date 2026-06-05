import 'package:flutter/material.dart';

/// Centralized brand definition — single source of truth for all brand metadata.
/// Adding a new brand is a one-line enum value + filling in the fields.
enum Brand {
  decathlon(
    key: 'decathlon',
    label: 'DECATHLON',
    color: Color(0xFF0077C8),
    icon: Icons.sports_soccer,
    hintText: 'Ex: 8612171',
  ),
  zara(
    key: 'zara',
    label: 'ZARA',
    color: Color(0xFF0E0E0E),
    icon: Icons.checkroom,
    hintText: 'Ex: 4393/555',
  ),
  jdsports(
    key: 'jdsports',
    label: 'JD SPORTS',
    color: Color(0xFFFFB800),
    icon: Icons.shopping_bag,
    hintText: 'Ex: 19716625',
  ),
  amazon(
    key: 'amazon',
    label: 'AMAZON',
    color: Color(0xFFFF9900),
    icon: Icons.shopping_cart,
    hintText: 'Ex: ASIN (B08N5WRWNW) ou mot-clé',
  ),
  ikea(
    key: 'ikea',
    label: 'IKEA',
    color: Color(0xFF0058AB),
    icon: Icons.weekend,
    hintText: 'Ex: Référence (804.782.13)',
  ),
  sephora(
    key: 'sephora',
    label: 'SEPHORA',
    color: Color(0xFFE5007A),
    icon: Icons.face,
    hintText: 'Ex: Référence ou produit',
  );

  final String key;
  final String label;
  final Color color;
  final IconData icon;
  final String hintText;

  const Brand({
    required this.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.hintText,
  });

  /// Whether text on this brand's colored background should be black (for light brand colors).
  bool get useDarkText => this == Brand.jdsports || this == Brand.amazon;

  /// Background color with alpha for badges / chips.
  Color get bgColor => color.withValues(alpha: 0.15);

  /// Lookup a Brand by its key string (for deserialization / history restore).
  static Brand fromKey(String key) {
    return Brand.values.firstWhere(
      (b) => b.key == key,
      orElse: () => Brand.decathlon,
    );
  }
}
