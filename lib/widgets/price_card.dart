import 'package:flutter/material.dart';
import '../models/country.dart';
import '../models/price_result.dart';
import '../theme/app_theme.dart';

class PriceCard extends StatelessWidget {
  final Country country;
  final PriceResult? result;
  final double? convertedPrice;
  final bool isCheapest;
  final VoidCallback onTap;
  final VoidCallback? onScan;
  final bool isScanningThis;
  final bool isAnyScanRunning;

  const PriceCard({
    super.key,
    required this.country,
    this.result,
    this.convertedPrice,
    this.isCheapest = false,
    required this.onTap,
    this.onScan,
    this.isScanningThis = false,
    this.isAnyScanRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-aware colors
    final cheapestBg = isDark 
        ? const Color(0xFF064E3B).withValues(alpha: 0.25) // Translucent deep green in dark theme
        : const Color(0xFFF0FDF4); // Light emerald green in light theme
        
    final normalBg = AppTheme.cardColor(context);
    final cardBgColor = isCheapest ? cheapestBg : normalBg;

    const cheapestBorder = Color(0xFF10B981);
    final normalBorder = isDark ? const Color(0xFF1E2D47) : Colors.grey.withValues(alpha: 0.08);
    final cardBorderColor = isCheapest ? cheapestBorder : normalBorder;

    final cheapestShadow = const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.15);
    final normalShadow = Colors.black.withValues(alpha: isDark ? 0.15 : 0.03);
    final cardShadowColor = isCheapest ? cheapestShadow : normalShadow;

    final titleCheapestColor = isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);
    final titleNormalColor = isDark ? const Color(0xFFE2E8F0) : Colors.black87;
    final cardTitleColor = isCheapest ? titleCheapestColor : titleNormalColor;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card Body
          Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardShadowColor,
                  blurRadius: isCheapest ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: cardBorderColor,
                width: isCheapest ? 2.0 : 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  children: [
                     // Header: Emoji + Name + Scan
                     Row(
                       children: [
                         Text(country.emoji, style: const TextStyle(fontSize: 20)),
                         const SizedBox(width: 6),
                         Expanded(
                           child: Text(
                             country.name,
                             style: TextStyle(
                               fontWeight: isCheapest ? FontWeight.w800 : FontWeight.w600, 
                               fontSize: 12, 
                               color: cardTitleColor
                             ),
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                         _buildScanButton(context),
                       ],
                     ),
                     
                     const Spacer(),
                     
                     // Content
                     if (result?.isLoaded == true)
                       _buildPriceContent(context)
                     else if (result?.isWebOnly == true)
                       _buildWebOnlyContent(context)
                     else if (result?.isError == true)
                       _buildErrorContent(context)
                     else
                       _buildEmptyContent(context),
      
                     const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Floating "Best Price" Badge
          if (isCheapest)
            Positioned(
              top: -6,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)], // Premium emerald gradient
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'MEILLEUR PRIX 🏆',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEuro = country.currency == '€';
    
    // Theme-aware price colors
    final convertedPriceColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF);
    final standardPriceColor = isDark ? const Color(0xFFF1F5F9) : Colors.black;
    final localPriceBgColor = isDark ? const Color(0xFF1E293B) : Colors.grey[100];
    final localPriceTextColor = isDark ? const Color(0xFF94A3B8) : Colors.grey[600];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (convertedPrice != null && !isEuro) ...[
          // Big Converted Price
          Text(
            '≈ ${convertedPrice!.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 17,
              color: convertedPriceColor,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // Small Local Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: localPriceBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${result?.value} ${country.currency}',
              style: TextStyle(fontSize: 10, color: localPriceTextColor, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ] else ...[
           // Standard Price (Already Euro)
           Text(
            '${result?.value} ${country.currency}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: standardPriceColor),
            overflow: TextOverflow.ellipsis,
          ),
        ]
      ],
    );
  }

  Widget _buildWebOnlyContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linkColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
    final bgColor = isDark ? const Color(0xFF1E2D47) : const Color(0xFFEFF6FF);

    return GestureDetector(
      onTap: onTap, // opens the URL via the card's onTap callback
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.open_in_new_rounded, size: 11, color: linkColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Voir le prix',
                style: TextStyle(
                  color: linkColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDark ? const Color(0xFFFCA5A5) : Colors.red[300];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, color: errorColor, size: 20),
        const SizedBox(height: 3),
        Text(
          result?.msg ?? 'Erreur',
          style: TextStyle(color: errorColor, fontSize: 10, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF334155) : Colors.grey[300];
    final textColor = isDark ? const Color(0xFF475569) : Colors.grey[400];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.radar_rounded, color: iconColor, size: 20),
        const SizedBox(height: 3),
        Text(
          'Non scanné',
          style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildScanButton(BuildContext context) {
    if (onScan == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isScanningThis) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      );
    }

    final IconData icon = (result?.isLoaded == true) 
        ? Icons.sync_rounded 
        : Icons.play_arrow_rounded;

    final Color color = (result?.isLoaded == true) 
        ? (isDark ? const Color(0xFF475569) : Colors.grey[400]!) 
        : const Color(0xFF10B981);

    // Disable button if any scan is already running (excluding this one)
    final bool isDisabled = isAnyScanRunning;

    return GestureDetector(
      onTap: isDisabled ? null : onScan,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDisabled ? 0.3 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
      ),
    );
  }
}
