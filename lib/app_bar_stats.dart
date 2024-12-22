import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class AppBarStats extends StatefulWidget {
  final int score;
  final int remainingLives;

  const AppBarStats({
    Key? key,
    required this.score,
    required this.remainingLives,
  }) : super(key: key);

  @override
  _AppBarStatsState createState() => _AppBarStatsState();
}

class _AppBarStatsState extends State<AppBarStats> {
  late int countdownSeconds;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    countdownSeconds = 160; // Sayaç başlangıç süresi (1 dakika)
    startCountdown();
  }

  void startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdownSeconds > 0) {
          countdownSeconds--;
        } else {
          timer.cancel();
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
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Coinler
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
                '  ${widget.score}',
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
                '  ${widget.remainingLives}',
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
        // Sayaç kapsülü
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
                '  ${formatCountdown(countdownSeconds)}',
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