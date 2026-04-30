import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1DA1F2);
  static const Color accentOrange = Color(0xFFFFA632);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: accentOrange,
      background: Colors.white,
    ),

    fontFamily: 'Poppins',

    scaffoldBackgroundColor: Color(0xFFF5F5F5),

    appBarTheme: AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFF333333),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Color(0xFF333333),
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: Color(0xFF555555),
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF666666),
        fontSize: 14,
      ),
      labelSmall: TextStyle(
        color: Color(0xFF999999),
        fontSize: 12,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(accentOrange),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        minimumSize: WidgetStateProperty.all(Size(double.infinity, 52)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        elevation: WidgetStateProperty.all(3),
      ),
    ),

    cardTheme: CardThemeData(
      shadowColor: Colors.black12,
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),


    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryBlue, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}
