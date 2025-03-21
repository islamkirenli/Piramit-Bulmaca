import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:pyramid_puzzle/ad_manager.dart';
import 'package:pyramid_puzzle/circle_painter.dart';
import 'package:pyramid_puzzle/level_complete_dialog.dart';
import 'daily_puzzle_data.dart'; // Günlük puzzle verileri (liste)
import 'app_bar_stats.dart';     // Sayaç, coin vb. AppBar bileşeni
import 'settings.dart';          // Ayarlar diyalogu
import 'global_properties.dart'; // GlobalProperties
import 'animated_polygon.dart';  // Çokgen widget
import 'time_completed_dialog.dart'; // Sayaç bitim diyaloğu
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Günlük Bulmaca Oyunu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DailyPuzzleGame(),
    );
  }
}

class DailyPuzzleGame extends StatefulWidget {
  @override
  _DailyPuzzleGameState createState() => _DailyPuzzleGameState();
}

class _DailyPuzzleGameState extends State<DailyPuzzleGame>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Her güne ait puzzle indexi
  int puzzleIndex = 0;

  // Günlük puzzle içinde birden fazla kelime varsa, currentIndex o kelimenin sırası
  int currentIndex = 0;

  // Kullanıcı harfleri sürükleyerek seçtiğinde geçici olarak tutulanlar
  List<String> shuffledLetters = [];
  List<String> selectedLetters = [];
  List<int> visitedIndexes = [];
  List<Offset> linePoints = [];
  Offset? temporaryLineEnd;

  // Doğru tahmin edilen kelimelerin listesi
  List<String> correctWords = [];

  // Animasyon kontrolü (shake, correct guess image, vb.)
  bool isShaking = false;
  double shakeOffset = 0.0;
  bool showSelectedLetters = false;

  // Doğru tahmin efektleri
  bool showCorrectAnswerImage = false;
  int correctAnswerCounter = 0;
  List<String> correctGuessImages = [];
  String? currentCorrectGuessImage;

  // Reklamlar
  late Timer _bannerAdTimer;

  // Yanlış seçimler için küçük bir bekleme
  Timer? _wrongChoiceTimer;
  bool _isWrongChoiceWaiting = false;

  // Animasyon denetleyiciler
  late AnimationController _settingsIconController;
  late AnimationController _correctGuessController;
  late Animation<double> _correctGuessOpacity;

  late AnimationController _letterShuffleController;

  // Data yüklendi mi?
  bool isDataLoaded = false;

  bool showPartyAnimation = false;

  // Gün (tarih) kontrolü için
  late DateTime lastPuzzleDate; // Son oynanan tarih

  // Çokgen animasyon widget key
  final GlobalKey<AnimatedPolygonWidgetState> _polygonKey =
      GlobalKey<AnimatedPolygonWidgetState>();

  // Ses oynatıcı
  AudioPlayer? _clickAudioPlayer;

  int nextPuzzleSeconds = 0;       // Bir sonraki günlük bulmacaya kalan saniye
  Timer? _nextPuzzleTimer;         // Geri sayımı her saniye güncellemek için timer


  @override
  void initState() {
    super.initState();

    // Örnek doğru tahmin görselleri
    correctGuessImages = [
      'assets/images/correct_guess/correct_guess1.png',
      'assets/images/correct_guess/correct_guess2.png',
      'assets/images/correct_guess/correct_guess3.png',
      'assets/images/correct_guess/correct_guess4.png',
    ];

    // Reklam yönetimi
    AdManager.loadBannerAd();
    AdManager.loadInterstitialAd();
    AdManager.loadRewardedAd();

    // Banner reklamını periyodik olarak yenile
    _bannerAdTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (mounted) {
        AdManager.loadBannerAd();
      }
    });

    _letterShuffleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _letterShuffleController.value = 1.0;

    // Doğru tahmin animasyonu
    _correctGuessController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _correctGuessOpacity = CurvedAnimation(
      parent: _correctGuessController,
      curve: Curves.easeInOut,
    );

    // Geri sayım başlangıç değeri
    GlobalProperties.countdownSeconds.value = 3599;

    // Settings ikonu animasyonu
    _settingsIconController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    // Ses tıklama efekti için
    _clickAudioPlayer = AudioPlayer();

    // Oyun verilerini (puzzleIndex, coin, vb.) yükle
    loadGameData().then((_) {
      setState(() {
        isDataLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _bannerAdTimer.cancel();
    _correctGuessController.dispose();
    _settingsIconController.dispose();
    _clickAudioPlayer?.dispose();
    _nextPuzzleTimer?.cancel();
    _letterShuffleController.dispose();
    saveGameData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isDataLoaded) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double scaleFactor = (screenWidth / 400).clamp(0.5, 1.5);

    final screenSize = MediaQuery.of(context).size;
    final double calculatedSize = screenSize.width * 0.75;
    final double polygonSize = min(calculatedSize, 400.0);

    if (puzzleIndex >= dailyPuzzleData.length) {
      return Scaffold(
        body: Center(
          child: Text(
            'Tüm günlük bulmacalar tamamlandı!',
            style: GlobalProperties.globalTextStyle(color: Colors.black),
          ),
        ),
      );
    }

    // Şu an oynanan puzzle verisi (o günün tüm kelime/hint listesi)
    final List<Map<String, String>> currentPuzzle = dailyPuzzleData[puzzleIndex];

    // Ekrana çizilecek "word" ve "hint"
    //final String currentWord = currentPuzzle[currentIndex]['word']!;
    final String currentHint = currentPuzzle[currentIndex]['hint']!;

    return WillPopScope(
      onWillPop: () async => false, // Geri tuşu engellendi
      child: Stack(
        children: [
          // Arka plan görseli (örnek)
          Positioned.fill(
            child: Image.asset(
              'assets/images/game_background/keops.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              centerTitle: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: AppBarStats(
                onTimerEnd: () {
                  onTimerEnd(context); // Sayaç bittiğinde
                },
              ),
              actions: [
                IconButton(
                  icon: AnimatedBuilder(
                    animation: _settingsIconController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _settingsIconController.value * pi / 2,
                        child: child,
                      );
                    },
                    child: Icon(Icons.settings, size: 28),
                  ),
                  onPressed: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer?.stop();
                      await _clickAudioPlayer?.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    _settingsIconController.forward(from: 0); // ikon animasyonu

                    showDialog(
                      context: context,
                      builder: (context) =>
                          SettingsDialog(sourcePage: 'puzzle_game'),
                    ).then((_) {
                      _settingsIconController.reverse();
                    });
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // İpucu alanı
                Container(
                  height: 90 * scaleFactor,
                  margin: EdgeInsets.symmetric(horizontal: 16.0 * scaleFactor),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20 * scaleFactor),
                    color: Colors.black54,
                    border: Border.all(color: Colors.black, width: 2.0 * scaleFactor),
                  ),
                  padding: EdgeInsets.all(16.0 * scaleFactor),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Text(
                      currentHint,
                      style: GlobalProperties.globalTextStyle(
                        color: Colors.white,
                        fontSize: 18 * scaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 100 * scaleFactor),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxWidth = constraints.maxWidth;

                      return Center( // <-- Center widget ile sarmaladık
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            currentPuzzle.length,
                            (index) {
                              String word = currentPuzzle[index]['word']!;
                              bool isRevealed = correctWords.contains(word);

                              double calculatedWidth = 50.0 * word.length;
                              double containerWidth = calculatedWidth > maxWidth
                                  ? maxWidth
                                  : calculatedWidth;

                              return Container(
                                width: containerWidth * scaleFactor,
                                height: 40 * scaleFactor,
                                margin: EdgeInsets.only(bottom: 4 * scaleFactor),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10 * scaleFactor),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2.0 * scaleFactor,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(word.length, (charIndex) {
                                    return AnimatedSwitcher(
                                      duration: Duration(milliseconds: 400),
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(scale: animation, child: child);
                                      },
                                      child: isRevealed
                                          ? Stack(
                                              key: ValueKey('revealed-$index-$charIndex'),
                                              alignment: Alignment.center,
                                              children: [
                                                Text(
                                                  ' ${word[charIndex]} ',
                                                  style: GlobalProperties.globalTextStyle(
                                                    fontSize: 20 * scaleFactor,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 5 * scaleFactor,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              ' _ ',
                                              key: ValueKey('hidden-$index-$charIndex'),
                                              style: GlobalProperties.globalTextStyle(
                                                fontSize: 20 * scaleFactor,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 5 * scaleFactor,
                                              ),
                                            ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ).reversed.toList(),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 100),
                      transform: isShaking
                          ? Matrix4.translationValues(shakeOffset, 0, 0)
                          : Matrix4.identity(),
                      height: 30 * scaleFactor,
                      margin: EdgeInsets.symmetric(horizontal: 16.0 * scaleFactor),
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 300),
                        opacity: showSelectedLetters ? 1.0 : 0.0,
                        child: Container(
                          width: 15.0 * scaleFactor *
                              (selectedLetters.length.clamp(1, 9999)
                                  as num), // min 1 harf
                          height: 20 * scaleFactor,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10 * scaleFactor),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedLetters.join(''),
                            style: GlobalProperties.globalTextStyle(
                              color: Colors.white,
                              fontSize: 15 * scaleFactor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 5 * scaleFactor),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0 * scaleFactor),
                  child: GestureDetector(
                      onPanUpdate: (details) {
                        final localPosition = details.localPosition;
                        onLetterDrag(localPosition, polygonSize);
                      },
                      onPanEnd: (_) => onDragEnd(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Çokgen animasyon widget
                          CirclePainterWidget(
                            key: _polygonKey,
                            initialSides: shuffledLetters.length.toDouble(),
                            size: polygonSize,
                            color: Colors.black54,
                            letters: shuffledLetters,
                            selectedIndexes: visitedIndexes,
                            linePoints: linePoints,
                            temporaryLineEnd: temporaryLineEnd,
                            letterShuffleAnimation: _letterShuffleController, // EKLENDİ
                          ),
                          // Doğru cevap görseli
                          if (showCorrectAnswerImage && currentCorrectGuessImage != null)
                            Positioned(
                              top: -60 * scaleFactor,
                              child: FadeTransition(
                                opacity: _correctGuessOpacity,
                                child: Image.asset(
                                  currentCorrectGuessImage!,
                                  width: 200 * scaleFactor,
                                  height: 200 * scaleFactor,
                                ),
                              ),
                            ),
                          // Harfleri karıştırma butonu
                          Positioned(
                            child: GestureDetector(
                              onTap: () async {
                                if (GlobalProperties.isSoundOn) {
                                  await _clickAudioPlayer?.stop();
                                  await _clickAudioPlayer?.play(
                                    AssetSource('audios/click_audio.mp3'),
                                  );
                                }
                                // Her tıklamada harfleri karıştır ve harf animasyonunu çalıştır
                                setState(() {
                                  shuffleLetters();
                                  _letterShuffleController.value = 0.0;
                                });
                                _letterShuffleController.forward(from: 0);
                              },
                              child: Container(
                                width: 50 * scaleFactor,
                                height: 50 * scaleFactor,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shuffle,
                                  color: Colors.white,
                                  size: 30 * scaleFactor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 5 * scaleFactor),

                // Banner reklam alanı
                if (AdManager.bannerAd != null)
                  AdManager.getBannerAdWidget()
              ],
            ),
          ),
          if (showPartyAnimation)
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5), // İsteğe bağlı: arka planı karartmak için
            child: Center(
              child: Lottie.asset(
                'assets/animations/party_animation.json',
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.cover,
                repeat: false,
                animate: true,
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  // Seçilen puzzle/günün "aktif kelimesi" alınır ve harfler karıştırılır
  void shuffleLetters() {
    setState(() {
      shuffledLetters.shuffle();
      selectedLetters.clear();
      visitedIndexes.clear();
      linePoints.clear();
      temporaryLineEnd = null;
      showSelectedLetters = false;
    });
  }

  /// Ekranda sürükleme sırasında harfleri tespit etme
  void onLetterDrag(Offset position, double polygonSize) {
    // Yanlış seçim bekliyorsak, dokunulduğu anda iptal edelim
    if (_isWrongChoiceWaiting) {
      _wrongChoiceTimer?.cancel();
      _isWrongChoiceWaiting = false;
      setState(() {
        showSelectedLetters = false;
        selectedLetters.clear();
        visitedIndexes.clear();
        linePoints.clear();
      });
    }

    final double radius = polygonSize / 2;
    final Offset center = Offset(polygonSize / 2, polygonSize / 2);

    for (int i = 0; i < shuffledLetters.length; i++) {
      final point = _getLetterPosition(i, radius, center);
      final hitBox = Rect.fromCircle(center: point, radius: 30);

      if (hitBox.contains(position)) {
        // Eğer son seçilen harften bir önceki harfe geri dönülüyorsa, son harfi iptal et
        if (visitedIndexes.length > 1 &&
            visitedIndexes[visitedIndexes.length - 2] == i) {
          setState(() {
            selectedLetters.removeLast();
            visitedIndexes.removeLast();
            linePoints.removeLast();
          });
          break;
        }

        // Daha önce seçilmemişse ekle
        if (!visitedIndexes.contains(i)) {
          setState(() {
            selectedLetters.add(shuffledLetters[i]);
            visitedIndexes.add(i);
            linePoints.add(point);
            showSelectedLetters = true;
          });
          break;
        }
      }
    }
    setState(() {
      temporaryLineEnd = position;
    });
  }

  /// Sürükleme bittiğinde seçilen harflerle kelime doğru mu kontrol et
  void onDragEnd() {
    setState(() {
      temporaryLineEnd = null;

      final List<Map<String, String>> currentPuzzle =
          dailyPuzzleData[puzzleIndex];
      final String correctWord = currentPuzzle[currentIndex]['word']!;
      final String selectedWord = selectedLetters.join('');

      // Eğer seçilen harf sayısı doğru kelimeden kısaysa veya yanlışsa
      if (selectedWord != correctWord) {
        triggerShakeEffect();
        _isWrongChoiceWaiting = true;
        _wrongChoiceTimer = Timer(Duration(seconds: 1), () {
          _isWrongChoiceWaiting = false;
          setState(() {
            showSelectedLetters = false;
            selectedLetters.clear();
            visitedIndexes.clear();
            linePoints.clear();
          });
        });
      } else {
        // Doğru tahmin
        correctAnswerCounter++;
        if (!correctWords.contains(correctWord)) {
          correctWords.add(correctWord);
        }

        Timer(Duration(milliseconds: 500), () {
          setState(() {
            showPartyAnimation = true;
          });
        });
        // 2 saniye sonra animasyonu gizle
        Timer(Duration(seconds: 2), () {
          setState(() {
            showPartyAnimation = false;
          });
        });

        // Eğer puzzle içinde birden fazla kelime varsa, sıradaki kelimeye geç
        if (currentIndex < currentPuzzle.length - 1) {
          currentIndex++;
          selectedLetters.clear();
          visitedIndexes.clear();
          linePoints.clear();
          // Yeni kelimenin harflerini al ve karıştır
          shuffledLetters = currentPuzzle[currentIndex]['word']!.split('');
          shuffleLetters();
        } else {
          GlobalProperties.puzzleForTodayCompleted.value = true;
          Timer(Duration(seconds: 2), () {
            showInterstitialIfReady();
            showLevelCompleteDialog(context, sourcePage: 'daily_puzzle_game');
          });
        }
      }
    });

    saveGameData(); // Her tahmin sonrasında veriyi kaydet
  }

  /// Titreşim ve küçük sağa-sola sallanma efekti
  void triggerShakeEffect() {
    setState(() {
      isShaking = true;
    });

    if (GlobalProperties.isVibrationOn) {
      HapticFeedback.vibrate();
    }

    Future.delayed(Duration(milliseconds: 50), () {
      setState(() {
        shakeOffset = 10.0;
      });
    });
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        shakeOffset = -10.0;
      });
    });
    Future.delayed(Duration(milliseconds: 150), () {
      setState(() {
        shakeOffset = 10.0;
      });
    });
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        shakeOffset = 0.0;
        isShaking = false;
      });
    });
  }

  /// Çokgendeki harfin ekrandaki konumunu hesaplar
  Offset _getLetterPosition(int index, double radius, Offset center) {
    // Harflerin çizildiği yerde kullanılan hesaplama: letterRadius = radius - 30
    final double letterRadius = radius - 30;
    final double angle = -pi / 2 + (2 * pi / shuffledLetters.length) * index;
    final double dx = center.dx + letterRadius * cos(angle);
    final double dy = center.dy + letterRadius * sin(angle);
    return Offset(dx, dy);
  }

  // Sayaç bitince yapılacaklar (örnek)
  void onTimerEnd(BuildContext context) {
    GlobalProperties.isTimeCompletedWhileAppClosed = false;
    showTimeCompletedDialog(context, () {
      setState(() {
        GlobalProperties.remainingLives.value = 5;
        GlobalProperties.countdownSeconds.value = 3599;
        GlobalProperties.isTimerRunning.value = false;
      });
      saveGameData();
    });
  }

  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puzzleIndex', puzzleIndex);

    await prefs.setString('lastOpenDate', DateTime.now().toIso8601String());

    // GlobalProperties
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
    await prefs.setBool('puzzleForTodayCompleted', GlobalProperties.puzzleForTodayCompleted.value);
  }

  Future<void> loadGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Önce mevcut son açılış tarihini alalım.
    String? lastOpenDateString = prefs.getString('lastOpenDate');
    DateTime now = DateTime.now();
    bool dayChanged = false;

    if (lastOpenDateString != null) {
      DateTime lastOpenDate = DateTime.parse(lastOpenDateString);
      // Sadece tarih kısmını karşılaştırıyoruz (yıl, ay, gün)
      if (lastOpenDate.year != now.year ||
          lastOpenDate.month != now.month ||
          lastOpenDate.day != now.day) {
        dayChanged = true;
      }
    }

    if (dayChanged) {
      // Gün değişmişse, mevcut puzzleIndex'i artırıyoruz ve kelime sırasını sıfırlıyoruz.
      puzzleIndex = (prefs.getInt('puzzleIndex') ?? 0) + 1;
      currentIndex = 0;
      GlobalProperties.puzzleForTodayCompleted.value = false;
      await prefs.setBool('puzzleForTodayCompleted', GlobalProperties.puzzleForTodayCompleted.value);
    } else {
      puzzleIndex = prefs.getInt('puzzleIndex') ?? 0;
    }

    // Bugünün tarihini kaydediyoruz.
    await prefs.setString('lastOpenDate', now.toIso8601String());

    // Mevcut puzzle'ın ilk kelimesinin harflerini karıştır
    if (puzzleIndex < dailyPuzzleData.length) {
      final currentWord =
          dailyPuzzleData[puzzleIndex][currentIndex]['word'] ?? '';
      shuffledLetters = currentWord.split('');
      shuffledLetters.shuffle();
    }

    // GlobalProperties
    GlobalProperties.coin.value = prefs.getInt('coin') ?? 0;
    GlobalProperties.remainingLives.value = prefs.getInt('remainingLives') ?? 5;
    GlobalProperties.countdownSeconds.value = prefs.getInt('countdownSeconds') ?? 3599;
    GlobalProperties.isTimerRunning.value = prefs.getBool('isTimerRunning') ?? false;
    GlobalProperties.deadlineTimestamp = prefs.getInt('deadlineTimestamp') ?? 0;
  }

  // Interstitial reklam gösterme
  void showInterstitialIfReady() {
    if (AdManager.isInterstitialAdReady) {
      AdManager.showInterstitialAd();
    }
  }

  // Rewarded reklam gösterme
  void showRewardedAdIfReady(Function onRewarded) {
    if (AdManager.rewardedAd != null && AdManager.isRewardedAdReady) {
      AdManager.rewardedAd!.show(onUserEarnedReward: (_, reward) {
        onRewarded();
      });
      AdManager.rewardedAd = null;
      AdManager.loadRewardedAd();
    } else {
      debugPrint('Rewarded reklam henüz hazır değil.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reklam henüz hazır değil, lütfen tekrar deneyin!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

