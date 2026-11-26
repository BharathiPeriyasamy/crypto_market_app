import 'package:flutter/material.dart';

// Emerald crypto palette
const neonGreen = Color(0xFF20D840);
const emeraldGreen = Color(0xFF65D96A);
const deepGreen = Color(0xFF002B08);
const darkGreen = Color(0xFF142018);
const offWhite = Color(0xFFF2F5F2);
const borderColor = Color(0xFF22352A);
const gainColor = Color(0xFF16C784);
const lossColor = Color(0xFFEA3943);

// Filled watchlist stars
const starColor = Color(0xFFFFC107);

Color changeColor(double change) => change >= 0 ? gainColor : lossColor;

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: neonGreen,
    onPrimary: Colors.black,
    secondary: emeraldGreen,
    onSecondary: Colors.black,
    secondaryContainer: deepGreen,
    onSecondaryContainer: neonGreen,
    surface: darkGreen,
    onSurface: offWhite,
    error: lossColor,
  ),
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
  ),
  cardTheme: CardThemeData(
    color: darkGreen,
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: borderColor),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    height: 68,
    indicatorColor: deepGreen,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkGreen,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: darkGreen,
    selectedColor: deepGreen,
    showCheckmark: false,
    side: const BorderSide(color: borderColor),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: const StadiumBorder(),
  ),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: darkGreen),
);
