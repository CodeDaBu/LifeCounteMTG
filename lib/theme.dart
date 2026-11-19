import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Rounded, heavy numerals for life totals and dice.
TextStyle numberStyle(double size, Color color) => GoogleFonts.quicksand(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.0,
    );

/// Tall condensed caps for buttons and titles.
TextStyle labelStyle(double size, {Color color = Colors.black}) =>
    GoogleFonts.bebasNeue(
      fontSize: size,
      color: color,
      height: 1.0,
      letterSpacing: 0.5,
    );

const sheetColor = Color(0xFF1C1C1F);
const accentGreen = Color(0xFF00D26A);
const accentPink = Color(0xFFFF0A5A);
