import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:pyramid_puzzle/background_music.dart';
import 'package:video_player/video_player.dart';
import 'puzzle_game.dart'; // Oyun sayfası dosyasını dahil edin
import 'settings.dart';
import 'sections.dart';
import 'app_bar_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';
import 'time_completed_dialog.dart';
import 'dart:async'; // <<< Timer için ekle
import 'package:lottie/lottie.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'daily_puzzle_game.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(
    MusicBackground(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bulmaca Oyunu',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: IntroAnimationScreen(),
      ),
    ),
  );
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool isDataLoaded = false;
  late AnimationController _settingsIconController;
  Timer? _timer;
  AudioPlayer? _clickAudioPlayer;
  late VideoPlayerController _videoController;
  bool isNewDailyPuzzle = false; // Yeni günlük bulmaca var mı?

  @override
  void initState() {
    super.initState();
    requestAppTrackingPermission();

    _videoController = VideoPlayerController.asset('assets/videos/dongu.mp4')
    ..setLooping(true)
    ..initialize().then((_) {
      setState(() {});
      _videoController.play();
    });

    _settingsIconController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _clickAudioPlayer = AudioPlayer();

    loadGameData().then((_) {
      setState(() {
        isDataLoaded = true;
      });
      if (GlobalProperties.isTimerRunning.value) {
        handleCountdownLogic();
      }
    });
  }

  Future<void> requestAppTrackingPermission() async {
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    if (status == TrackingStatus.authorized) {
      print("Kullanıcı izni verdi.");
    } else {
      print("Kullanıcı izin vermedi.");
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _clickAudioPlayer?.dispose();
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
        // Arka plan videosu
        if (_videoController.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40), // AppBar ile buton arasına boşluk ekler
              Center(
                child: ElevatedButton(
                  onPressed: () async{
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer?.stop();
                      await _clickAudioPlayer?.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }

                    setState(() {
                      isNewDailyPuzzle = false;
                    });
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DailyPuzzleGame()),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Asıl buton metni
                      Text("Yeni Buton"),

                      // Eğer yeni günlük bulmaca varsa, küçük kırmızı çember içinde '!' işareti
                      if (isNewDailyPuzzle)
                        Positioned(
                          top: -17,
                          right: -25,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 100),
                      ValueListenableBuilder<int>(
                        valueListenable: GlobalProperties.remainingLives,
                        builder: (context, remainingLives, _) {
                          return GestureDetector(
                            onTap: remainingLives > 0
                                ? () async {
                                    if (GlobalProperties.isSoundOn) {
                                      await _clickAudioPlayer?.stop();
                                      await _clickAudioPlayer?.play(
                                        AssetSource('audios/click_audio.mp3'),
                                      );
                                    }
                                    await showGeneralDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      barrierColor: Colors.transparent,
                                      pageBuilder: (context, _, __) {
                                        return Scaffold(
                                          backgroundColor: Colors.transparent,
                                          body: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Center(
                                                  child: Transform.scale(
                                                    scale: 1,
                                                    child: Transform.translate(
                                                      offset: Offset(0, 0),
                                                      child: Lottie.asset(
                                                        'assets/animations/screen_transition_animation.json',
                                                        width: MediaQuery.of(context).size.width,
                                                        height: MediaQuery.of(context).size.height,
                                                        fit: BoxFit.fill,
                                                        repeat: false,
                                                        onLoaded: (composition) {
                                                          Future.delayed(
                                                            composition.duration,
                                                            () {
                                                              Navigator.of(context).pop();
                                                              Navigator.of(context)
                                                                  .pushAndRemoveUntil(
                                                                MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        PuzzleGame()),
                                                                (route) => false,
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
                                : null,
                            child: Image.asset(
                              'assets/images/buttons/play_button.png',
                              width: 120,
                              height: 120,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 60.0),
                  child: GestureDetector(
                    onTap: () async{
                      if (GlobalProperties.isSoundOn) {
                        await _clickAudioPlayer?.stop();
                        await _clickAudioPlayer?.play(
                          AssetSource('audios/click_audio.mp3'),
                        );
                      }
                      _settingsIconController.forward(from: 0); // Animasyonu başlat
                      showDialog(
                        context: context,
                        builder: (context) => SettingsDialog(sourcePage: 'main'),
                      ).then((_) {
                        _settingsIconController.reverse(); // Animasyonu geri al
                      });
                    },
                    child: Image.asset(
                      'assets/images/buttons/settings_button.png', // Ayarlar butonu görseli
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: GestureDetector(
                    onTap: () async{
                      if (GlobalProperties.isSoundOn) {
                        await _clickAudioPlayer?.stop();
                        await _clickAudioPlayer?.play(
                          AssetSource('audios/click_audio.mp3'),
                        );
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SectionsPage()),
                      );
                    },
                    child: Image.asset(
                      'assets/images/buttons/levels_button.png', // Bölümler butonu görseli
                      width: 80,
                      height: 80,
                    ),
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
        GlobalProperties.remainingLives.value = 3;
        GlobalProperties.countdownSeconds.value = 15;
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
      GlobalProperties.countdownSeconds.value = 0;
      GlobalProperties.isTimerRunning.value = false;
      saveGameData();
    } else {
      GlobalProperties.countdownSeconds.value = (diff / 1000).ceil();
      GlobalProperties.isTimerRunning.value = true;
      _timer?.cancel();
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
    GlobalProperties.deadlineTimestamp = prefs.getInt('deadlineTimestamp') ?? 0;
    GlobalProperties.isSoundOn = prefs.getBool('isSoundOn') ?? true;
    GlobalProperties.isVibrationOn = prefs.getBool('isVibrationOn') ?? true;
    
    // Bugün ve son kaydedilen tarih
    String? savedDate = prefs.getString('lastPuzzleDate');
    final now = DateTime.now();
    final nowMS = now.millisecondsSinceEpoch;

    // "yyyyMMdd" formatında bugünün tarihi (Örn: 20250120)
    final todayString = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    // Gün değişmişse -> Yeni günlük bulmaca var
    if (savedDate != null && savedDate != todayString) {
      isNewDailyPuzzle = true;
      await prefs.setString('lastPuzzleDate', todayString);
    } else {
      // İlk defa giriyorsa veya gün değişmemişse
      isNewDailyPuzzle = false;
      if (savedDate == null) {
        await prefs.setString('lastPuzzleDate', todayString);
      }
    }

    if (GlobalProperties.deadlineTimestamp != 0 &&
        GlobalProperties.deadlineTimestamp <= nowMS) {
      GlobalProperties.isTimeCompletedWhileAppClosed = true;
      await saveGameData();
    } else if (GlobalProperties.deadlineTimestamp != 0) {
      final remainingMillis = GlobalProperties.deadlineTimestamp - nowMS;
      final remainingSecs = (remainingMillis / 1000).ceil();
      GlobalProperties.countdownSeconds.value = remainingSecs > 0 ? remainingSecs : 0;
      GlobalProperties.isTimerRunning.value = true;
    }
  }
}

/// Uygulama ilk açıldığında tam ekran animasyon gösterecek sayfa
class IntroAnimationScreen extends StatefulWidget {
  const IntroAnimationScreen({Key? key}) : super(key: key);

  @override
  _IntroAnimationScreenState createState() => _IntroAnimationScreenState();
}

class _IntroAnimationScreenState extends State<IntroAnimationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Transform.scale(
                scale: 1,
                child: Transform.translate(
                  offset: const Offset(0, 0),
                  child: Lottie.asset(
                    'assets/animations/screen_transition_animation.json',
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    fit: BoxFit.fill,
                    repeat: false,
                    onLoaded: (composition) {
                      // Animasyon süresi dolunca HomePage'e geç
                      Future.delayed(
                        composition.duration,
                        () {
                          /// IntroAnimationScreen yerine HomePage açılsın
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => HomePage(),
                            ),
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
  }
}