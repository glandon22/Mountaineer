import 'package:flutter/material.dart';
import 'package:mountaineer/colors.dart';

class MountaineerTheme {
  ThemeData buildThemeData() {
    return ThemeData(
      primaryColor: AppColors.softSlateBlue,
      scaffoldBackgroundColor: AppColors.creamyOffWhite,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(
          0xFF6B829D,
          {
            50: const Color(0xFFE6E9EF),
            100: const Color(0xFFC3CAD8),
            200: const Color(0xFF9EABBF),
            300: const Color(0xFF858FA7),
            400: const Color(0xFF767E94),
            500: AppColors.softSlateBlue,
            600: const Color(0xFF62748A),
            700: const Color(0xFF566475),
            800: const Color(0xFF4A5662),
            900: const Color(0xFF3A434D),
          },
        ),
        accentColor: AppColors.dustyOrange,
        backgroundColor: AppColors.creamyOffWhite,
        cardColor: AppColors.warmTaupe,
      ).copyWith(secondary: AppColors.mossGreen),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.dustyOrange,
        textTheme: ButtonTextTheme.primary,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.softSlateBlue),
        bodyMedium: TextStyle(color: AppColors.charcoalGray),
      ),
    );
  }
}