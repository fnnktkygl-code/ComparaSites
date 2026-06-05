import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as import_ui;
import '../providers/app_state.dart';
import 'search_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const SearchScreen(),
      HistoryScreen(
        onRestore: (item) {
           // Switch to search tab and restore
           context.read<AppState>().restoreFromHistory(item);
           setState(() => _currentIndex = 0);
        },
      ),
    ];

    // Select dynamic active tab accent color based on active brand in AppState
    final brand = context.watch<AppState>().brand;
    final activeColor = brand.color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Screen content padded at bottom to prevent floating bar obstruction
          Padding(
            padding: const EdgeInsets.only(bottom: 84.0),
            child: pages[_currentIndex],
          ),
          
          // Custom Floating Navigation Bar
          Positioned(
            left: 50,
            right: 50,
            bottom: 24,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: import_ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65), // Premium glass color
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.search_rounded, 'Recherche', activeColor, brand.useDarkText),
                        _buildNavItem(1, Icons.history_rounded, 'Historique', activeColor, brand.useDarkText),
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

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor, bool useDarkText) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? (useDarkText ? Colors.black : activeColor) : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (useDarkText ? Colors.black : activeColor) : Colors.grey[600],
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
