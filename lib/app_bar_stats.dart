import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'global_properties.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'show_coin_popup.dart'; // Coin pop-up
import 'show_lives_popup.dart'; // Remaining lives pop-up

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
    if (GlobalProperties.remainingLives.value == 0 &&
        GlobalProperties.countdownSeconds.value > 0 &&
        !GlobalProperties.isTimerRunning.value) {
      startCountdown(); // Sayaç başlamış değilse başlat
    }
  }

  @override
  void didUpdateWidget(covariant AppBarStats oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Hak sıfırdan büyüğe çıktıysa timer'ı durdur ve sayaç sıfırla
    if (GlobalProperties.remainingLives.value > 0) {
      countdownTimer?.cancel();
      countdownTimer = null;
      GlobalProperties.countdownSeconds.value = 15;
      GlobalProperties.isTimerRunning.value = false;
    }

    // Hak sıfıra düştüyse ve sayaç aktif değilse başlat
    if (GlobalProperties.remainingLives.value == 0 &&
        (countdownTimer == null || !countdownTimer!.isActive)) {
      startCountdown();
    }

    setState(() {}); // AppBar'ı yeniden çiz
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    countdownTimer = null;
    GlobalProperties.isTimerRunning.value = false;
    super.dispose();
  }

  void startCountdown() {
    // Eğer timer hâlâ aktifse, tekrar kurmayalım
    if (countdownTimer != null && countdownTimer!.isActive) {
      return;
    }

    // Eğer isTimerRunning.value = false ise, henüz deadline belirlenmemiştir demektir.
    // O zaman şu andan + X saniye olarak bitiş zamanını kuralım.
    if (!GlobalProperties.isTimerRunning.value) {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Burada 15 sabit ise sabitlersiniz; eğer puzzle_game'den vs. geliyorsa oradaki countdownSeconds'ı kullanabilirsiniz.
      GlobalProperties.deadlineTimestamp =
          now + (GlobalProperties.countdownSeconds.value * 1000);

      GlobalProperties.isTimerRunning.value = true;
      saveGameData(); 
    }

    // Her saniye bir Timer kuruyoruz
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = GlobalProperties.deadlineTimestamp - now;

      if (diff <= 0) {
        // Süre dolmuş
        timer.cancel();
        countdownTimer = null;

        // Sayaç değerlerini sıfırla
        GlobalProperties.countdownSeconds.value = 0;
        GlobalProperties.isTimerRunning.value = false;

        saveGameData(); 
        widget.onTimerEnd(); 
      } else {
        // Hâlâ zaman var => kalan saniyeyi (diff/1000) olarak ayarla
        GlobalProperties.countdownSeconds.value = (diff / 1000).ceil();
      }

      setState(() {}); 
    });
  }

  String formatCountdown(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin', GlobalProperties.coin.value); // Skoru kaydeder
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value); // Kalan hakları kaydeder
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value); // Sayaç değerini kaydeder
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);

    // Deadline da mutlaka kaydedilmeli
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Skor gösterimi
        GestureDetector(
          onTap: () => showCoinPopup(context), // Coin kapsülüne tıklanıldığında
          child: Stack(
            clipBehavior: Clip.none,
            children: [
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
                      '  ${GlobalProperties.coin.value}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -5,
                right: -5,
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Kalan haklar
        GestureDetector(
          onTap: () => showLivesPopup(context), // Remaining Lives kapsülüne tıklanıldığında
          child: Stack(
            clipBehavior: Clip.none,
            children: [
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
                        'assets/animations/heart_beat_animation.json',
                        repeat: true,
                        animate: true,
                      ),
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
              Positioned(
                bottom: -5,
                right: -5,
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
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