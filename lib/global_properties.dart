import 'package:flutter/foundation.dart';

class GlobalProperties {
  static final ValueNotifier<int> remainingLives = ValueNotifier<int>(3);
  static final ValueNotifier<int> score = ValueNotifier<int>(0);
  static final ValueNotifier<int> countdownSeconds = ValueNotifier<int>(30);
  static final ValueNotifier<bool> isTimerRunning = ValueNotifier<bool>(false);
}
