import 'package:flutter/material.dart';

const gainColor = Color(0xFF16C784);
const lossColor = Color(0xFFEA3943);

Color changeColor(double change) => change >= 0 ? gainColor : lossColor;

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: Colors.indigo,
  scaffoldBackgroundColor: const Color(0xFF0E1116),
  cardTheme: const CardThemeData(
    color: Color(0xFF171B22),
    elevation: 0,
    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  ),
);
