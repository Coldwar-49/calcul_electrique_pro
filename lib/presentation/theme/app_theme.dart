import 'package:flutter/material.dart';

/// Couleurs de la marque : bleu électrique + ambre (éclair).
const Color _bleu = Color(0xFF1A4FD6);
const Color _ambre = Color(0xFFFFB400);

class AppTheme {
  static ThemeData clair() => _construire(Brightness.light);
  static ThemeData sombre() => _construire(Brightness.dark);

  static ThemeData _construire(Brightness luminosite) {
    final base = ColorScheme.fromSeed(
      seedColor: _bleu,
      tertiary: _ambre,
      brightness: luminosite,
    );
    final cs = base;
    final sombre = luminosite == Brightness.dark;
    final rayon = BorderRadius.circular(14);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: sombre
          ? cs.surfaceContainerLowest
          : Color.alphaBlend(cs.primary.withValues(alpha: 0.04), cs.surface),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: rayon,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: rayon,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: rayon,
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surfaceContainerLow,
        indicatorColor: cs.primaryContainer,
        selectedIconTheme: IconThemeData(color: cs.onPrimaryContainer),
        selectedLabelTextStyle:
            TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainerLow,
        indicatorColor: cs.primaryContainer,
      ),
      switchTheme: const SwitchThemeData(),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1),
      textTheme: Typography.material2021().black.apply(
            bodyColor: cs.onSurface,
            displayColor: cs.onSurface,
          ),
    );
  }
}
