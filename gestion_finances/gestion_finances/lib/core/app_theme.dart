import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // --- PALETTE OFFICIELLE DU PROTOTYPE ---
  static const Color emeraldDarkest = Color(0xFF051F20); // #051F20 - Vert nuit profond / Conteneurs sombres
  static const Color emeraldDeep    = Color(0xFF0B2B26); // #0B2B26 - Pin sombre / Identité principale
  static const Color emeraldForest  = Color(0xFF163832); // #163832 - Ardoise végétale
  static const Color emeraldPine    = Color(0xFF235347); // #235347 - Pin doux / Boutons & Puces
  static const Color emeraldSage    = Color(0xFF8EB69B); // #8EB69B - Sauge mentholée / Accents & Badges
  static const Color emeraldMint    = Color(0xFFDAF1DE); // #DAF1DE - Menthe glacée / Puces lumineuses

  // Rôles principaux
  static const Color primary        = emeraldDeep;
  static const Color primaryDark    = emeraldDarkest;
  static const Color primaryLight   = emeraldPine;
  static const Color accent         = emeraldSage;
  static const Color accentLight    = emeraldMint;

  // Statuts financiers élégants
  static const Color income         = Color(0xFF1E7B56);
  static const Color expense        = Color(0xFFCE4D56);
  static const Color transfer       = Color(0xFF2E6F7E);

  // Surfaces & typographie
  static const Color background     = Color(0xFFF6F8F6);
  static const Color card           = Colors.white;
  static const Color cardBorder     = Color(0xFFE5EDE8);
  static const Color textPrimary    = Color(0xFF051F20);
  static const Color textSecondary  = Color(0xFF5E7166);
  static const Color textMuted      = Color(0xFF8FA197);

  // Gradients néo-fintech inspirés de la maquette
  static const LinearGradient heroGradient = LinearGradient(
    colors: [emeraldDarkest, emeraldDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGlow = LinearGradient(
    colors: [Color(0xFF082723), Color(0xFF041819)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient mintPillGradient = LinearGradient(
    colors: [emeraldMint, Color(0xFFC7EBD0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldDeep,
        primary: emeraldDeep,
        secondary: emeraldPine,
        tertiary: emeraldSage,
        surface: background,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emeraldPine, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldDarkest,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: emeraldDarkest,
          side: const BorderSide(color: cardBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: emeraldDarkest,
        unselectedItemColor: Color(0xFF90A499),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 10,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: emeraldDarkest,
        foregroundColor: emeraldMint,
        elevation: 4,
      ),
    );
  }
}
