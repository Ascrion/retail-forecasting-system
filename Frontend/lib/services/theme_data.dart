import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

// Custom Theme: Custom colors and text
final ThemeData customTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    primary: HexColor('#0053E2'), // royal blue (very high impact only)
    onPrimary: const Color.fromARGB(179, 255, 255, 255),
    brightness: Brightness.light,
    secondary: Colors.white, // white (base color)
    onSecondary: Colors.black,
    tertiary: HexColor('#001E60'), // dark blue ( impact color )
    onTertiary: Colors.white,
    onPrimaryFixed: HexColor('#FFC220'), // yellow (hihglight color)
    surface: HexColor('#A9DDF7'), // light blue (good for impact text)
    onSurface: Color(0xFFEFEFEF),
    surfaceContainerHighest: Color(0xFF1A1A1A),
    onSurfaceVariant: Color.fromARGB(255, 61, 61, 61), // Dart
    error: Colors.red,
    onError: Colors.white,
  ),

  fontFamily: 'EverydaySans',
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontWeight: FontWeight.w600),
    bodySmall: TextStyle(fontWeight:FontWeight.w400 ),
    headlineLarge: TextStyle(fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontWeight: FontWeight.w200)
  ),
);
