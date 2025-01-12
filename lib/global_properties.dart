import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';


class GlobalProperties {
  static final ValueNotifier<int> remainingLives = ValueNotifier<int>(3);
  static final ValueNotifier<int> coin = ValueNotifier<int>(0);
  static final ValueNotifier<int> countdownSeconds = ValueNotifier<int>(30);
  static final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);
  static int deadlineTimestamp = 0;
  static bool isTimeCompletedWhileAppClosed = false;

  static TextStyle globalTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.varelaRound(
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
