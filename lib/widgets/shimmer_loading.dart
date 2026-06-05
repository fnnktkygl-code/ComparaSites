import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E2D47) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF2D3F5E) : Colors.grey[100]!;
    final bgColor = isDark ? const Color(0xFF111C30) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
         decoration: BoxDecoration(
           color: bgColor,
           borderRadius: BorderRadius.circular(16),
         ),
      ),
    );
  }
}
