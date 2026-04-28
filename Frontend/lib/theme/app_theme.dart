import 'package:flutter/material.dart';

class AppTheme {
  // Pitch Green Palette
  static const Color bg       = Color(0xFF081C15); // Deepest Forest
  static const Color surface  = Color(0xFF1B4332); // Dark Forest
  static const Color surface2 = Color(0xFF2D6A4F); // Medium Forest
  static const Color accent   = Color(0xFF52B788); // Light Pitch Green
  static const Color accent2  = Color(0xFF95D5B2); // Pale Mint
  static const Color green    = Color(0xFF74C69D); // Success Green
  static const Color red      = Color(0xFFEF4444);
  static const Color yellow   = Color(0xFFF59E0B);
  static const Color textMuted = Color(0xFFA9D8B8);
  static const Color textDim   = Color(0xFFD8F3DC);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent2,
          surface: surface,
          error: red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xEE081C15),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x12FFFFFF)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D281E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          labelStyle: const TextStyle(color: textDim),
          hintStyle: const TextStyle(color: textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Color(0xFF081C15),
            elevation: 2,
            shadowColor: accent.withOpacity(.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: accent.withOpacity(.25),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: accent, fontWeight: FontWeight.w800, fontSize: 12);
            }
            return const TextStyle(color: textMuted, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: accent, size: 28);
            }
            return const IconThemeData(color: textMuted);
          }),
        ),
      );

  static Shader gradientShader(Rect bounds) => const LinearGradient(
        colors: [Colors.white, accent2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds);
}
