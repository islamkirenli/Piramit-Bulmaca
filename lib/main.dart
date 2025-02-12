/*import 'package:audioplayers/audioplayers.dart';
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
import 'special_day_popup.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(
    MusicBackground(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bulmaca Oyunu',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomePage(),
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isDataLoaded = false;
  late AnimationController _settingsIconController;
  Timer? _timer;
  AudioPlayer? _clickAudioPlayer;
  late VideoPlayerController _videoController;
  bool isNewDailyPuzzle = false; // Yeni günlük bulmaca var mı?
  bool _isPressed = false;
  bool _isSettingsPressed = false;
  bool _isSectionsPressed = false;
  bool _isDailyPuzzlePressed = false;

  int nextPuzzleSeconds = 0;
  Timer? _nextPuzzleTimer;
  String _currentDayString = "";
  Timer? _dailyCheckTimer;

  late AnimationController _rippleController;

  bool _isTimeDialogShown = false;

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
      if (GlobalProperties.puzzleForTodayCompleted.value) {
        startNextPuzzleCountdown();
      }
      checkSpecialDay();
    });

    _currentDayString = _getTodayString(); // Aşağıda tanımlayacağımız helper fonksiyon

    _dailyCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      String newTodayString = _getTodayString();
      if (newTodayString != _currentDayString) {
        // Yeni gün başladıysa; isNewDailyPuzzle'yi true yap
        setState(() {
          isNewDailyPuzzle = true;
          _currentDayString = newTodayString;
        });
      }
    });

    _rippleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _rippleController.repeat();
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
    _settingsIconController.dispose(); 
    _rippleController.dispose();
    _nextPuzzleTimer?.cancel();
    _dailyCheckTimer?.cancel();
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
              SizedBox(height: 60), // AppBar ile buton arasına boşluk ekler
              ValueListenableBuilder<bool>(
                valueListenable: GlobalProperties.puzzleForTodayCompleted,
                builder: (context, puzzleCompleted, child) {
                  bool disableButton = puzzleCompleted && !isNewDailyPuzzle;
                  double buttonHeight = (puzzleCompleted && !isNewDailyPuzzle) ? 70 : 40;
                  return Center(
                    child: GestureDetector(
                      onTapDown: (_) {
                        if (!disableButton) {
                          setState(() {
                            _isDailyPuzzlePressed = true;
                          });
                        }
                      },
                      onTapUp: (_) {
                        if (!disableButton) {
                          setState(() {
                            _isDailyPuzzlePressed = false;
                          });
                        }
                      },
                      onTapCancel: () {
                        if (!disableButton) {
                          setState(() {
                            _isDailyPuzzlePressed = false;
                          });
                        }
                      },
                      onTap: disableButton
                          ? null
                          : () async {
                              if (GlobalProperties.isSoundOn) {
                                await _clickAudioPlayer?.stop();
                                await _clickAudioPlayer?.play(
                                  AssetSource('audios/click_audio.mp3'),
                                );
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DailyPuzzleGame()),
                              );
                            },
                      child: AnimatedScale(
                        scale: _isDailyPuzzlePressed ? 0.95 : 1.0,
                        duration: Duration(milliseconds: 100),
                        child: Container(
                          width: 200,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: disableButton
                                ? LinearGradient(colors: [Colors.grey, Colors.grey])
                                : LinearGradient(
                                    colors: [
                                      Color(0xFFFFC107),
                                      Color(0xFFFF9800),
                                      Color(0xFFF57C00),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: disableButton
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      offset: Offset(4, 4),
                                      blurRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.8),
                                      offset: Offset(-4, -4),
                                      blurRadius: 8,
                                    ),
                                  ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Günlük Bulmaca",
                                      style: GlobalProperties.globalTextStyle(
                                        color: disableButton ? Colors.black38 : Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (puzzleCompleted && !isNewDailyPuzzle)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          _formatTime(nextPuzzleSeconds),
                                          style: GlobalProperties.globalTextStyle(
                                            color: Colors.black38,
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // İsteğe bağlı: Yeni günlük bulmaca varsa sağ üst köşeye (!) işareti ekleyebilirsiniz.
                              if (isNewDailyPuzzle)
                                Positioned(
                                  top: -10,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
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
                    ),
                  );
                },
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
                            onTapDown: (details) {
                              setState(() {
                                _isPressed = true;
                              });
                            },
                            onTapUp: (details) {
                              setState(() {
                                _isPressed = false;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                _isPressed = false;
                              });
                            },
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
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ripple (dalgalanma) efekti
                                AnimatedBuilder(
                                  animation: _rippleController,
                                  builder: (context, child) {
                                    // Controller değeri 0-1 arasında; bunu scale ve opacity'ye dönüştürelim
                                    double scaleFactor = 1 + _rippleController.value * 0.3; // Örneğin %30 büyüme
                                    double opacity = (1 - _rippleController.value).clamp(0.0, 1.0);
                                    return Container(
                                      width: 150 * scaleFactor,
                                      height: 150 * scaleFactor,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(opacity * 0.2), // Opaklık ayarlanabilir
                                      ),
                                    );
                                  },
                                ),
                                // Mevcut play butonunuz
                                AnimatedScale(
                                  scale: _isPressed ? 0.95 : 1.0,
                                  duration: Duration(milliseconds: 100),
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF0194D7), // Daha açık ve canlı mavi
                                          Color(0xFF0172B9), // Ana renk
                                          Color(0xFF015C8E), // Biraz daha koyu ve doygun mavi
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          offset: Offset(4, 4),
                                          blurRadius: 10,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.8),
                                          offset: Offset(-4, -4),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(Icons.play_arrow.codePoint),
                                        style: TextStyle(
                                          fontFamily: Icons.play_arrow.fontFamily,
                                          package: Icons.play_arrow.fontPackage,
                                          fontSize: 60,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(2, 2),
                                              blurRadius: 4,
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                    onTapDown: (_) {
                      setState(() {
                        _isSettingsPressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isSettingsPressed = false;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _isSettingsPressed = false;
                      });
                    },
                    onTap: () async {
                      if (GlobalProperties.isSoundOn) {
                        await _clickAudioPlayer?.stop();
                        await _clickAudioPlayer?.play(
                          AssetSource('audios/click_audio.mp3'),
                        );
                      }
                      _settingsIconController.forward(from: 0);
                      showDialog(
                        context: context,
                        builder: (context) => SettingsDialog(sourcePage: 'main'),
                      ).then((_) {
                        _settingsIconController.reverse();
                      });
                    },
                    child: AnimatedScale(
                      scale: _isSettingsPressed ? 0.95 : 1.0,
                      duration: Duration(milliseconds: 100),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0180C8), // Orta-açık mavi
                              Color(0xFF015C8E), // Temel teal-mavi (daha koyu)
                              Color(0xFF013F62), // En koyu ton (derin mavi)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            // Alt sağa doğru koyu gölge
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: Offset(4, 4),
                              blurRadius: 8,
                            ),
                            // Üst sola doğru çıkan aydınlık gölge
                            BoxShadow(
                              color: Colors.black.withOpacity(0.8),
                              offset: Offset(-4, -4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 40,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isSectionsPressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isSectionsPressed = false;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _isSectionsPressed = false;
                      });
                    },
                    onTap: () async {
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
                    child: AnimatedScale(
                      scale: _isSectionsPressed ? 0.95 : 1.0,
                      duration: Duration(milliseconds: 100),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0180C8), // Orta-açık mavi
                              Color(0xFF015C8E), // Temel teal-mavi (daha koyu)
                              Color(0xFF013F62), // En koyu ton (derin mavi)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            // Alt sağa doğru koyu gölge
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: Offset(4, 4),
                              blurRadius: 8,
                            ),
                            // Üst sola doğru çıkan aydınlık gölge
                            BoxShadow(
                              color: Colors.black.withOpacity(0.8),
                              offset: Offset(-4, -4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.format_list_bulleted, // İkon tercihinize göre değiştirilebilir
                            color: Colors.white,
                            size: 40,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
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
    if (_isTimeDialogShown) return;
    _isTimeDialogShown = true;
    showTimeCompletedDialog(context, () {
      _isTimeDialogShown = false;
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
    
    GlobalProperties.puzzleForTodayCompleted.value = prefs.getBool('puzzleForTodayCompleted') ?? false;
    
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

  Future<void> checkSpecialDay() async {
    final now = DateTime.now();
    if (now.month == 4 && now.day == 19) { // Özel tarih kontrolü
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isPopupShown = prefs.getBool('specialDayPopupShown') ?? false;

      if (!isPopupShown) {
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            barrierDismissible: false, // Kullanıcı kapatmadan devam edemez
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;

              return StatefulBuilder(
                builder: (context, setState) {
                  bool isAnimationVisible = true; // Animasyon görünürlüğünü kontrol eder

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pop-up Widget'ı
                      Center(
                        child: SpecialDayPopup(
                          onClose: () async {
                            // Pop-up'ı kapat ve gösterildiğini kaydet
                            await prefs.setBool('specialDayPopupShown', true);
                            Navigator.of(context).pop(); // Pop-up'ı kapat
                          },
                        ),
                      ),
                      // Animasyon Pop-up'ın Önünde
                      if (isAnimationVisible)
                        IgnorePointer(
                          ignoring: true, // Etkileşimi devre dışı bırakır
                          child: SizedBox(
                            width: screenWidth,
                            height: screenHeight,
                            child: Lottie.asset(
                              'assets/animations/party_animation.json',
                              fit: BoxFit.cover,
                              repeat: false,
                              onLoaded: (composition) {
                                // Animasyon tamamlandığında görünürlüğü kaldır
                                Future.delayed(composition.duration, () {
                                  setState(() {
                                    isAnimationVisible = false;
                                  });
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        });
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('specialDayPopupShown', false);
    }
  }

  void startNextPuzzleCountdown() {
    DateTime now = DateTime.now();
    // Yarın gece yarısına kadar geçen süre
    DateTime tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      nextPuzzleSeconds = tomorrowMidnight.difference(now).inSeconds;
    });
    _nextPuzzleTimer?.cancel();
    _nextPuzzleTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (nextPuzzleSeconds > 0) {
          nextPuzzleSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // Zamanı HH:MM:SS formatında döndüren yardımcı fonksiyon:
  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:"
          "${minutes.toString().padLeft(2, '0')}:"
          "${seconds.toString().padLeft(2, '0')}";
  }

  String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
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
}*/

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
import 'special_day_popup.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(
    MusicBackground(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bulmaca Oyunu',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomePage(),
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isDataLoaded = false;
  late AnimationController _settingsIconController;
  Timer? _timer;
  AudioPlayer? _clickAudioPlayer;
  late VideoPlayerController _videoController;
  bool isNewDailyPuzzle = false; // Yeni günlük bulmaca var mı?
  bool _isPressed = false;
  bool _isSettingsPressed = false;
  bool _isSectionsPressed = false;
  bool _isDailyPuzzlePressed = false;

  int nextPuzzleSeconds = 0;
  Timer? _nextPuzzleTimer;
  String _currentDayString = "";
  Timer? _dailyCheckTimer;

  late AnimationController _rippleController;

  bool _isTimeDialogShown = false;

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
      if (GlobalProperties.puzzleForTodayCompleted.value) {
        startNextPuzzleCountdown();
      }
      checkSpecialDay();
    });

    _currentDayString = _getTodayString(); // Aşağıda tanımlayacağımız helper fonksiyon

    _dailyCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      String newTodayString = _getTodayString();
      if (newTodayString != _currentDayString) {
        // Yeni gün başladıysa; isNewDailyPuzzle'yi true yap
        setState(() {
          isNewDailyPuzzle = true;
          _currentDayString = newTodayString;
        });
      }
    });

    _rippleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _rippleController.repeat();
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
    _settingsIconController.dispose(); 
    _rippleController.dispose();
    _nextPuzzleTimer?.cancel();
    _dailyCheckTimer?.cancel();
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
              SizedBox(height: 60), // AppBar ile buton arasına boşluk ekler
              ValueListenableBuilder<bool>(
                valueListenable: GlobalProperties.puzzleForTodayCompleted,
                builder: (context, puzzleCompleted, child) {
                  bool disableButton = puzzleCompleted && !isNewDailyPuzzle;
                  double buttonHeight = (puzzleCompleted && !isNewDailyPuzzle) ? 70 : 40;
                  return Center(
                    child: GestureDetector(
                      onTapDown: (_) {
                        if (!disableButton) {
                          setState(() {
                            _isDailyPuzzlePressed = true;
                          });
                        }
                      },
                      onTapUp: (_) {
                        if (!disableButton) {
                          setState(() {
                            _isDailyPuzzlePressed = false;
                          });
                        }
                      },
                      onTapCancel: () {
                        if (!disableButton) {
                          setState(() {
                            _isDailyPuzzlePressed = false;
                          });
                        }
                      },
                      onTap: disableButton
                          ? null
                          : () async {
                              if (GlobalProperties.isSoundOn) {
                                await _clickAudioPlayer?.stop();
                                await _clickAudioPlayer?.play(
                                  AssetSource('audios/click_audio.mp3'),
                                );
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DailyPuzzleGame()),
                              );
                            },
                      child: AnimatedScale(
                        scale: _isDailyPuzzlePressed ? 0.95 : 1.0,
                        duration: Duration(milliseconds: 100),
                        child: Container(
                          width: 200,
                          height: buttonHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: disableButton
                                ? LinearGradient(colors: [Colors.grey, Colors.grey])
                                : LinearGradient(
                                    colors: [
                                      Color(0xFFFFC107),
                                      Color(0xFFFF9800),
                                      Color(0xFFF57C00),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: disableButton
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      offset: Offset(4, 4),
                                      blurRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.8),
                                      offset: Offset(-4, -4),
                                      blurRadius: 8,
                                    ),
                                  ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Günlük Bulmaca",
                                      style: GlobalProperties.globalTextStyle(
                                        color: disableButton ? Colors.black38 : Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (puzzleCompleted && !isNewDailyPuzzle)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          _formatTime(nextPuzzleSeconds),
                                          style: GlobalProperties.globalTextStyle(
                                            color: Colors.black38,
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // İsteğe bağlı: Yeni günlük bulmaca varsa sağ üst köşeye (!) işareti ekleyebilirsiniz.
                              if (isNewDailyPuzzle)
                                Positioned(
                                  top: -10,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
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
                    ),
                  );
                },
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
                            onTapDown: (details) {
                              setState(() {
                                _isPressed = true;
                              });
                            },
                            onTapUp: (details) {
                              setState(() {
                                _isPressed = false;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                _isPressed = false;
                              });
                            },
                            onTap: remainingLives > 0
                              ? () async {
                                  if (GlobalProperties.isSoundOn) {
                                    // Önce tıklama sesini çal
                                    await _clickAudioPlayer?.stop();
                                    await _clickAudioPlayer?.play(
                                      AssetSource('audios/click_audio.mp3'),
                                    );
                                    // Tıklama sesinin tamamlanması için kısa bir gecikme verelim
                                    await Future.delayed(Duration(milliseconds: 200));
                                    // Geçiş (transition) ses efektini çal
                                    await _clickAudioPlayer?.play(
                                      AssetSource('audios/transition_sound.mp3'),
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
                                                            Navigator.of(context).pushAndRemoveUntil(
                                                              MaterialPageRoute(
                                                                  builder: (context) => PuzzleGame()),
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
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ripple (dalgalanma) efekti
                                AnimatedBuilder(
                                  animation: _rippleController,
                                  builder: (context, child) {
                                    // Controller değeri 0-1 arasında; bunu scale ve opacity'ye dönüştürelim
                                    double scaleFactor = 1 + _rippleController.value * 0.3; // Örneğin %30 büyüme
                                    double opacity = (1 - _rippleController.value).clamp(0.0, 1.0);
                                    return Container(
                                      width: 150 * scaleFactor,
                                      height: 150 * scaleFactor,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(opacity * 0.2), // Opaklık ayarlanabilir
                                      ),
                                    );
                                  },
                                ),
                                // Mevcut play butonunuz
                                AnimatedScale(
                                  scale: _isPressed ? 0.95 : 1.0,
                                  duration: Duration(milliseconds: 100),
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF0194D7), // Daha açık ve canlı mavi
                                          Color(0xFF0172B9), // Ana renk
                                          Color(0xFF015C8E), // Biraz daha koyu ve doygun mavi
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          offset: Offset(4, 4),
                                          blurRadius: 10,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.8),
                                          offset: Offset(-4, -4),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(Icons.play_arrow.codePoint),
                                        style: TextStyle(
                                          fontFamily: Icons.play_arrow.fontFamily,
                                          package: Icons.play_arrow.fontPackage,
                                          fontSize: 60,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(2, 2),
                                              blurRadius: 4,
                                              color: Colors.black.withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                    onTapDown: (_) {
                      setState(() {
                        _isSettingsPressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isSettingsPressed = false;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _isSettingsPressed = false;
                      });
                    },
                    onTap: () async {
                      if (GlobalProperties.isSoundOn) {
                        await _clickAudioPlayer?.stop();
                        await _clickAudioPlayer?.play(
                          AssetSource('audios/click_audio.mp3'),
                        );
                      }
                      _settingsIconController.forward(from: 0);
                      showDialog(
                        context: context,
                        builder: (context) => SettingsDialog(sourcePage: 'main'),
                      ).then((_) {
                        _settingsIconController.reverse();
                      });
                    },
                    child: AnimatedScale(
                      scale: _isSettingsPressed ? 0.95 : 1.0,
                      duration: Duration(milliseconds: 100),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0180C8), // Orta-açık mavi
                              Color(0xFF015C8E), // Temel teal-mavi (daha koyu)
                              Color(0xFF013F62), // En koyu ton (derin mavi)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            // Alt sağa doğru koyu gölge
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: Offset(4, 4),
                              blurRadius: 8,
                            ),
                            // Üst sola doğru çıkan aydınlık gölge
                            BoxShadow(
                              color: Colors.black.withOpacity(0.8),
                              offset: Offset(-4, -4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 40,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() {
                        _isSectionsPressed = true;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _isSectionsPressed = false;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _isSectionsPressed = false;
                      });
                    },
                    onTap: () async {
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
                    child: AnimatedScale(
                      scale: _isSectionsPressed ? 0.95 : 1.0,
                      duration: Duration(milliseconds: 100),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0180C8), // Orta-açık mavi
                              Color(0xFF015C8E), // Temel teal-mavi (daha koyu)
                              Color(0xFF013F62), // En koyu ton (derin mavi)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            // Alt sağa doğru koyu gölge
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: Offset(4, 4),
                              blurRadius: 8,
                            ),
                            // Üst sola doğru çıkan aydınlık gölge
                            BoxShadow(
                              color: Colors.black.withOpacity(0.8),
                              offset: Offset(-4, -4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.format_list_bulleted, // İkon tercihinize göre değiştirilebilir
                            color: Colors.white,
                            size: 40,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
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
    if (_isTimeDialogShown) return;
    _isTimeDialogShown = true;
    showTimeCompletedDialog(context, () {
      _isTimeDialogShown = false;
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
    
    GlobalProperties.puzzleForTodayCompleted.value = prefs.getBool('puzzleForTodayCompleted') ?? false;
    
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

  Future<void> checkSpecialDay() async {
    final now = DateTime.now();
    if (now.month == 4 && now.day == 19) { // Özel tarih kontrolü
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isPopupShown = prefs.getBool('specialDayPopupShown') ?? false;

      if (!isPopupShown) {
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            barrierDismissible: false, // Kullanıcı kapatmadan devam edemez
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;

              return StatefulBuilder(
                builder: (context, setState) {
                  bool isAnimationVisible = true; // Animasyon görünürlüğünü kontrol eder

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pop-up Widget'ı
                      Center(
                        child: SpecialDayPopup(
                          onClose: () async {
                            // Pop-up'ı kapat ve gösterildiğini kaydet
                            await prefs.setBool('specialDayPopupShown', true);
                            Navigator.of(context).pop(); // Pop-up'ı kapat
                          },
                        ),
                      ),
                      // Animasyon Pop-up'ın Önünde
                      if (isAnimationVisible)
                        IgnorePointer(
                          ignoring: true, // Etkileşimi devre dışı bırakır
                          child: SizedBox(
                            width: screenWidth,
                            height: screenHeight,
                            child: Lottie.asset(
                              'assets/animations/party_animation.json',
                              fit: BoxFit.cover,
                              repeat: false,
                              onLoaded: (composition) {
                                // Animasyon tamamlandığında görünürlüğü kaldır
                                Future.delayed(composition.duration, () {
                                  setState(() {
                                    isAnimationVisible = false;
                                  });
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        });
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('specialDayPopupShown', false);
    }
  }

  void startNextPuzzleCountdown() {
    DateTime now = DateTime.now();
    // Yarın gece yarısına kadar geçen süre
    DateTime tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      nextPuzzleSeconds = tomorrowMidnight.difference(now).inSeconds;
    });
    _nextPuzzleTimer?.cancel();
    _nextPuzzleTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (nextPuzzleSeconds > 0) {
          nextPuzzleSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // Zamanı HH:MM:SS formatında döndüren yardımcı fonksiyon:
  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:"
          "${minutes.toString().padLeft(2, '0')}:"
          "${seconds.toString().padLeft(2, '0')}";
  }

  String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
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