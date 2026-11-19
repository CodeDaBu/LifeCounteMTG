import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Set to false in tests, where fonts can't be downloaded.
bool useGoogleFonts = true;

/// Rounded, heavy numerals for life totals and dice.
TextStyle numberStyle(double size, Color color) {
  final base = TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.0,
  );
  return useGoogleFonts ? GoogleFonts.quicksand(textStyle: base) : base;
}

/// Tall condensed caps for buttons and titles.
TextStyle labelStyle(double size, {Color color = Colors.black}) {
  final base = TextStyle(
    fontSize: size,
    color: color,
    height: 1.0,
    letterSpacing: 0.5,
  );
  return useGoogleFonts ? GoogleFonts.bebasNeue(textStyle: base) : base;
}

const sheetColor = Color(0xFF1C1C1F);
const drawerColor = Color(0xFF36343F);
const accentGreen = Color(0xFF00D26A);
const accentPink = Color(0xFFFF0A5A);

/// Black or white, whichever reads better on [background].
Color inkOn(Color background) =>
    background.computeLuminance() > 0.12 ? Colors.black : Colors.white;
