import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as import_ui;
import '../providers/app_state.dart';
import '../l10n/strings.dart';
import 'search_screen.dart';
import 'history_screen.dart';
import 'settings_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      const SearchScreen(),
      HistoryScreen(
        onRestore: (item) {
          context.read<AppState>().restoreFromHistory(item);
          setState(() => _currentIndex = 0);
        },
      ),
    ];

    final brand = context.watch<AppState>().brand;
    final activeColor = brand.color;

    // Nav bar colours adapted to theme
    final navBg = isDark
        ? const Color(0xFF0D1526).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.75);
    final navBorder = isDark
        ? const Color(0xFF1E2D47).withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.5);
    final inactiveColor = isDark
        ? const Color(0xFF475569)
        : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Screen content
          Padding(
            padding: const EdgeInsets.only(bottom: 84.0),
            child: pages[_currentIndex],
          ),

          // ── Floating Settings Button ──
          Positioned(
            right: 20,
            bottom: 100,
            child: _SettingsFab(isDark: isDark),
          ),

          // ── Custom Floating Navigation Bar ──
          Positioned(
            left: 44,
            right: 44,
            bottom: 24,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: import_ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: navBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: navBorder, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          0, Icons.search_rounded, s.search,
                          activeColor, brand.useDarkText,
                          isDark, inactiveColor,
                        ),
                        _buildNavItem(
                          1, Icons.history_rounded, s.history,
                          activeColor, brand.useDarkText,
                          isDark, inactiveColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color activeColor,
    bool useDarkText,
    bool isDark,
    Color inactiveColor,
  ) {
    final isSelected = _currentIndex == index;
    final selectedColor = useDarkText ? Colors.black : activeColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: isDark ? 0.18 : 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? selectedColor : inactiveColor, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating settings FAB ──────────────────────────────────────────
class _SettingsFab extends StatelessWidget {
  final bool isDark;
  const _SettingsFab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF111C30) : Colors.white;
    final border = isDark ? const Color(0xFF1E2D47) : Colors.grey.shade200;
    final icon = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600;

    return GestureDetector(
      onTap: () => showSettingsSheet(context),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.tune_rounded, color: icon, size: 20),
      ),
    );
  }
}
