import 'package:flutter/material.dart';
import '../models/country.dart';
import '../models/price_result.dart';

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
    // Premium Card Styling with special highlight for cheapest country
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card Body
          Container(
            decoration: BoxDecoration(
              color: isCheapest ? const Color(0xFFF0FDF4) : Colors.white, // Light emerald tint for cheapest
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isCheapest 
                      ? const Color(0xFF10B981).withValues(alpha: 0.15) // Glowing green shadow
                      : Colors.black.withValues(alpha: 0.03), // Soft gray shadow
                  blurRadius: isCheapest ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isCheapest 
                    ? const Color(0xFF10B981) // Solid green border for cheapest
                    : Colors.grey.withValues(alpha: 0.08),
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
                               color: isCheapest ? const Color(0xFF065F46) : Colors.black87
                             ),
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                         _buildScanButton(),
                       ],
                     ),
                     
                     const Spacer(),
                     
                     // Content
                     if (result?.isLoaded == true)
                       _buildPriceContent()
                     else if (result?.isError == true)
                       _buildErrorContent()
                     else
                       _buildEmptyContent(),
      
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

  Widget _buildPriceContent() {
    final isEuro = country.currency == '€';
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (convertedPrice != null && !isEuro) ...[
          // Big Converted Price
          Text(
            '≈ ${convertedPrice!.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF1E40AF), // Blue 800
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          // Small Local Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${result?.value} ${country.currency}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ] else ...[
           // Standard Price (Already Euro)
           Text(
            '${result?.value} ${country.currency}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ]
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.red[300], size: 20),
        const SizedBox(height: 3),
        Text(
          result?.msg ?? 'Erreur',
          style: TextStyle(color: Colors.red[300], fontSize: 10, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.radar_rounded, color: Colors.grey[300], size: 20),
        const SizedBox(height: 3),
        Text(
          'Non scanné',
          style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildScanButton() {
    if (onScan == null) return const SizedBox.shrink();

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
        ? Colors.grey[400]! 
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
