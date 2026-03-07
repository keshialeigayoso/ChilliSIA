import 'package:flutter/material.dart';

const PRIMARY_COLOR = Color.fromARGB(255, 37, 103, 30);
const ACCENT_COLOR = Color.fromARGB(255, 242, 181, 11);
const WHITE_SHADE = Color.fromARGB(255, 247, 240, 240);
const LIGHT_GREEN = Color.fromARGB(255, 72, 161, 17);

ThemeData appTheme = ThemeData(
  fontFamily: 'Poppins',
  colorScheme: const ColorScheme.light(
    primary: PRIMARY_COLOR,
    secondary: ACCENT_COLOR,
  ),
  scaffoldBackgroundColor: WHITE_SHADE,

  // Text Theme
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ), // Heading
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ), // Subheading
    bodyMedium: TextStyle(fontSize: 16),
  ),

  // AppBar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: PRIMARY_COLOR,
    foregroundColor: WHITE_SHADE,
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.primary),
);

class AppButtonStyles {
  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: PRIMARY_COLOR,
    foregroundColor: WHITE_SHADE,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  static final ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: LIGHT_GREEN,
    foregroundColor: WHITE_SHADE,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  static final ButtonStyle accent = ElevatedButton.styleFrom(
    backgroundColor: ACCENT_COLOR,
    foregroundColor: PRIMARY_COLOR,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );
}
