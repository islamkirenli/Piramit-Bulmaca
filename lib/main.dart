import 'package:flutter/material.dart';
import 'puzzle_game.dart'; // Oyun sayfası dosyasını dahil edin
import 'settings.dart';
import 'sections.dart';
import 'app_bar_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';
import 'dart:math';
import 'time_completed_dialog.dart';
import 'dart:async'; // <<< Timer için ekle
import 'package:lottie/lottie.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bulmaca Oyunu',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(), // Giriş ekranı
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin{
  bool isDataLoaded = false;
  late AnimationController _settingsIconController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _settingsIconController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    loadGameData().then((_) {
      setState(() {
        isDataLoaded = true;
      });
      if (GlobalProperties.isTimerRunning.value) {
        handleCountdownLogic();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _settingsIconController.dispose(); // Animasyon denetleyicisini temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isDataLoaded) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        // Arka plan görseli
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/piramit_background.jpg'),
              fit: BoxFit.cover, // Görsel tüm alanı kaplar
            ),
          ),
        ),
        // İçerik
        Scaffold(
          backgroundColor: Colors.transparent, // Scaffold arka planı şeffaf yapılır
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: AppBarStats(
              onTimerEnd: () {
                onTimerEnd(context); // Zaman dolduğunda pop-up göster
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: GlobalProperties.remainingLives,
                  builder: (context, remainingLives, _) {
                    return ElevatedButton(
                        onPressed: remainingLives > 0
                          ? () async {
                              // Lottie animasyon ekranını tam ekran ve merkezde göster
                              await showGeneralDialog(
                                context: context,
                                barrierDismissible: false, // Kullanıcı animasyonu kapatamaz
                                barrierColor: Colors.transparent, // Hafif siyah arka plan
                                pageBuilder: (context, _, __) {
                                  return Scaffold(
                                    backgroundColor: Colors.transparent, // Arka plan rengini siyah yap
                                    body: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Center( // Animasyonu ekranın tam ortasına hizala
                                            child: Transform.scale(
                                              scale: 1, // Animasyonu büyütüp tam ortalamak için
                                              child: Transform.translate(
                                                offset: Offset(0, 0), // Animasyonun dikey ve yatay ofsetini ayarla
                                                child: Lottie.asset(
                                                  'assets/animations/screen_transition_animation.json',
                                                  width: MediaQuery.of(context).size.width, // Ekran genişliği
                                                  height: MediaQuery.of(context).size.height, // Ekran yüksekliği
                                                  fit: BoxFit.fill, // Ekranı tamamen kapla
                                                  repeat: false, // Animasyonu bir kez oynat
                                                  onLoaded: (composition) {
                                                    Future.delayed(
                                                      composition.duration, // Animasyon süresince bekle
                                                      () {
                                                        Navigator.of(context).pop(); // Animasyon bitince dialog kapat
                                                        Navigator.of(context).pushAndRemoveUntil(
                                                          MaterialPageRoute(builder: (context) => PuzzleGame()),
                                                          (route) => false, // Önceki ekranları temizle
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          : null, // Eğer hak yoksa buton devre dışı
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(40),
                        shape: CircleBorder(),
                        backgroundColor: remainingLives > 0
                            ? Colors.blueAccent
                            : Colors.grey, // Aktif değilse gri
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.4),
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 60,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 60.0),
                  child: FloatingActionButton(
                    heroTag: 'settingsButton',
                    onPressed: () {
                      _settingsIconController.forward(from: 0); // Animasyonu başlat

                      showDialog(
                        context: context,
                        builder: (context) => SettingsDialog(sourcePage: 'main'),
                      ).then((_) {
                        _settingsIconController.reverse(); // Animasyonu geri al
                      });
                    },
                    backgroundColor: Colors.blueAccent,
                    child: AnimatedBuilder(
                      animation: _settingsIconController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _settingsIconController.value * pi / 2,
                          child: child,
                        );
                      },
                      child: Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                    ),
                    shape: CircleBorder(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: FloatingActionButton(
                    heroTag: 'sectionsButton',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SectionsPage()),
                      );
                    },
                    backgroundColor: Colors.blueAccent,
                    child: Icon(
                      Icons.format_list_bulleted,
                      color: Colors.white,
                    ),
                    shape: CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void onTimerEnd(BuildContext context) {
    showTimeCompletedDialog(context, () {
      setState(() {
        GlobalProperties.remainingLives.value = 3; // Hakları sıfırla
        GlobalProperties.countdownSeconds.value = 15; // Sayaç sıfırlanır
        GlobalProperties.isTimerRunning.value = false;
      });
      saveGameData();
    });
  }

  void handleCountdownLogic() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = GlobalProperties.deadlineTimestamp - now;

    if (diff <= 0) {
      onTimerEnd(context);
      // Süre zaten dolmuş
      GlobalProperties.countdownSeconds.value = 0;
      GlobalProperties.isTimerRunning.value = false;
      saveGameData();
    } else {
      // Hala zaman var => kalan saniyeyi hesapla
      GlobalProperties.countdownSeconds.value = (diff / 1000).ceil();
      GlobalProperties.isTimerRunning.value = true;

      // Mevcut bir timer varsa iptal et
      _timer?.cancel();

      // Her saniye bir Timer kuruyoruz ve setState ile UI'ı tazeliyoruz
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (GlobalProperties.countdownSeconds.value <= 1) {
            timer.cancel();
            GlobalProperties.countdownSeconds.value = 0;
            GlobalProperties.isTimerRunning.value = false;
            saveGameData();
          } else {
            GlobalProperties.countdownSeconds.value--;
          }
        });
      });
    }
  }

  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
  }

  Future<void> loadGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    GlobalProperties.coin.value = prefs.getInt('coin') ?? 0;
    GlobalProperties.remainingLives.value = prefs.getInt('remainingLives') ?? 3;
    GlobalProperties.countdownSeconds.value = prefs.getInt('countdownSeconds') ?? 15;
    GlobalProperties.isTimerRunning.value = prefs.getBool('isTimerRunning') ?? false;

    // deadlineTimestamp'i yükle
    GlobalProperties.deadlineTimestamp = prefs.getInt('deadlineTimestamp') ?? 0;

    // Şu anki zaman
    final now = DateTime.now().millisecondsSinceEpoch;

    // Eğer deadline 0 değil ve deadline <= now ise süre dolmuş demektir
    if (GlobalProperties.deadlineTimestamp != 0 &&
        GlobalProperties.deadlineTimestamp <= now) {
      
      // >>> Timer aslında bitmiş, yani uygulama kapalıyken süre doldu.
      // Bunu işaretle:
      GlobalProperties.isTimeCompletedWhileAppClosed = true;

      // Hakları yenile (istersen onTimerEnd içinde de yenileyebilirsin ama burada da olur)
      GlobalProperties.remainingLives.value = 3;
      GlobalProperties.countdownSeconds.value = 15;
      GlobalProperties.isTimerRunning.value = false;

      // Kaydetmeyi unutma
      await saveGameData();

    } else if (GlobalProperties.deadlineTimestamp != 0) {
      // Süre henüz dolmamış, yani deadline gelecekte
      final remainingMillis = GlobalProperties.deadlineTimestamp - now;
      final remainingSecs = (remainingMillis / 1000).ceil();

      GlobalProperties.countdownSeconds.value = remainingSecs > 0 ? remainingSecs : 0;
      GlobalProperties.isTimerRunning.value = true;
    }
  }
}