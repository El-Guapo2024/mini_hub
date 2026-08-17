import 'package:flutter/material.dart';

/// The one place the app's palette is written down.
///
/// Four screens each hardcoded the same background, app bar and card colours,
/// and had begun to disagree: one card rounded to 16, another to 20, a third
/// left at the Material default. A screen now says nothing about colour unless
/// it means something — [correct] on a finished question, teal on the active
/// direction toggle.
final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey.shade900,
    foregroundColor: Colors.white,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    color: Colors.grey.shade900,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
);

/// Answered right, and so "this one is finished".
const correct = Color(0xFF4CAF50);
