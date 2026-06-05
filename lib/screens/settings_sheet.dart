import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/strings.dart';

/// Beautiful settings bottom sheet with theme + language selectors.
/// Call via: showSettingsSheet(context)
void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0D1526) : const Color(0xFFF8FAFC);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2D47)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Title ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  s.settings,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Appearance ──
            _SectionLabel(label: s.appearance, isDark: isDark),
            const SizedBox(height: 12),
            _ThemeSelector(settings: settings, s: s, cardColor: cardColor, isDark: isDark),
            const SizedBox(height: 24),

            // ── Language ──
            _SectionLabel(label: s.language, isDark: isDark),
            const SizedBox(height: 12),
            _LanguageSelector(settings: settings, cardColor: cardColor, isDark: isDark),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
      ),
    );
  }
}

// ══ THEME SELECTOR ══════════════════════════════════════════════════

class _ThemeSelector extends StatelessWidget {
  final SettingsProvider settings;
  final AppStrings s;
  final Color cardColor;
  final bool isDark;

  const _ThemeSelector({
    required this.settings,
    required this.s,
    required this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, s.systemTheme),
      (ThemeMode.light, Icons.light_mode_rounded, s.lightTheme),
      (ThemeMode.dark, Icons.dark_mode_rounded, s.darkTheme),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2D47) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: options.map((opt) {
          final (mode, icon, label) = opt;
          final isSelected = settings.themeMode == mode;
          final primary = Theme.of(context).colorScheme.primary;

          return Expanded(
            child: GestureDetector(
              onTap: () => settings.setThemeMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: primary.withValues(alpha: 0.35), width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected
                          ? primary
                          : (isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? primary
                            : (isDark ? const Color(0xFF64748B) : Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══ LANGUAGE SELECTOR ═══════════════════════════════════════════════

class _LanguageSelector extends StatelessWidget {
  final SettingsProvider settings;
  final Color cardColor;
  final bool isDark;

  const _LanguageSelector({
    required this.settings,
    required this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('fr', '🇫🇷', 'Français'),
      ('en', '🇬🇧', 'English'),
      ('es', '🇪🇸', 'Español'),
    ];

    return Column(
      children: options.map((opt) {
        final (code, flag, name) = opt;
        final isSelected = settings.locale.languageCode == code;
        final primary = Theme.of(context).colorScheme.primary;
        final borderColor = isDark ? const Color(0xFF1E2D47) : Colors.grey.shade200;

        return GestureDetector(
          onTap: () => settings.setLocale(Locale(code)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.08)
                  : cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? primary.withValues(alpha: 0.4)
                    : borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                      color: isSelected
                          ? primary
                          : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
