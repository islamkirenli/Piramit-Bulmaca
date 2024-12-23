import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'global_properties.dart';

class AppBarStats extends StatefulWidget {
  final VoidCallback onTimerEnd; // Sayaç bittiğinde çağrılacak fonksiyon

  const AppBarStats({
    Key? key,
    required this.onTimerEnd,
  }) : super(key: key);

  @override
  _AppBarStatsState createState() => _AppBarStatsState();
}

class _AppBarStatsState extends State<AppBarStats> {
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    if (GlobalProperties.remainingLives.value == 0) startCountdown();
  }

  @override
  void didUpdateWidget(covariant AppBarStats oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (GlobalProperties.remainingLives.value == 0 && (countdownTimer == null || !countdownTimer!.isActive)) {
      startCountdown();
    } else if (GlobalProperties.remainingLives.value > 0 && countdownTimer != null) {
      countdownTimer?.cancel(); // Sayaç durdurulur
      GlobalProperties.countdownSeconds.value = 15; // Sayaç sıfırlanır
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    countdownTimer?.cancel(); // Önceki sayaç varsa iptal et
    
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (GlobalProperties.countdownSeconds.value > 0) {
          GlobalProperties.countdownSeconds.value--;
        } else {
          timer.cancel();
          widget.onTimerEnd(); // Sayaç bittiğinde kalan hakları yenile
        }
      });
    });
  }

  String formatCountdown(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Skor gösterimi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Lottie.asset(
                  'assets/animations/coin_flip_animation.json',
                  repeat: true,
                  animate: true,
                ),
              ),
              Text(
                '  ${GlobalProperties.score.value}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        // Kalan haklar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 20,
              ),
              Text(
                '  ${GlobalProperties.remainingLives.value}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        // Sayaç (yalnızca kalan haklar 0 ise gösterilir)
        if (GlobalProperties.remainingLives.value == 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 20,
                ),
                Text(
                  '  ${formatCountdown(GlobalProperties.countdownSeconds.value)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
