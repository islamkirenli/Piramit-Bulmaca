import 'package:flutter/material.dart';

class GlobalProperties {
  static final ValueNotifier<int> remainingLives = ValueNotifier<int>(3);
  static final ValueNotifier<int> coin = ValueNotifier<int>(0);
  static final ValueNotifier<int> countdownSeconds = ValueNotifier<int>(30);
  static final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);
  static int deadlineTimestamp = 0;
  static bool isTimeCompletedWhileAppClosed = false;

  static bool isSoundOn = true;      // <-- Ses durumu
  static bool isMusicOn = true;      // <-- Müzik durumu
  static bool isVibrationOn = true;  // <-- Titreşim durumu

  static ValueNotifier<int> wordHintCount = ValueNotifier<int>(5);
  static ValueNotifier<int> singleHintCount = ValueNotifier<int>(5);

  static ValueNotifier<bool> puzzleForTodayCompleted = ValueNotifier<bool>(false);

  static TextStyle globalTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    double letterSpacing = 0,
  }) {
    return TextStyle(
        fontFamily: "Asap",
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
  }

  static bool isSpecialDate = false;

  static void updateSpecialDateStatus() {
    final now = DateTime.now();
    isSpecialDate = (now.month == 4 && now.day == 19);
  }
}