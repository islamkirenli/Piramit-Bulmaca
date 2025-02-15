import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
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
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  late Timer _bannerAdTimer;
  late InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady = false;

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

    // Örnek doğru tahmin görselleri (rastgele göstermek için)
    correctGuessImages = [
      'assets/images/correct_guess/correct_guess1.png',
      'assets/images/correct_guess/correct_guess2.png',
      'assets/images/correct_guess/correct_guess3.png',
      'assets/images/correct_guess/correct_guess4.png',
    ];

    // Başlangıçta Banner ve Interstitial reklamları yükle
    createAndLoadBannerAd();
    loadInterstitialAd();

    // Banner reklamı 5 saniyede bir yenileme
    _bannerAdTimer = Timer.periodic(Duration(seconds: 5), (_) {
      setState(() {
        _bannerAd.dispose();
        createAndLoadBannerAd();
      });
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
    GlobalProperties.countdownSeconds.value = 15;

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
    _bannerAd.dispose();
    _interstitialAd.dispose();
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
                  height: 90,
                  margin: EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black54,
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Text(
                      currentHint,
                      style: GlobalProperties.globalTextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: 100),

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
                                width: containerWidth,
                                height: 40,
                                margin: EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2.0,
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
                                                    fontSize: 20,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 5,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              ' _ ',
                                              key: ValueKey('hidden-$index-$charIndex'),
                                              style: GlobalProperties.globalTextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 5,
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
                      height: 30,
                      margin: EdgeInsets.symmetric(horizontal: 16.0),
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 300),
                        opacity: showSelectedLetters ? 1.0 : 0.0,
                        child: Container(
                          width: 15.0 *
                              (selectedLetters.length.clamp(1, 9999)
                                  as num), // min 1 harf
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedLetters.join(''),
                            style: GlobalProperties.globalTextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 5),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GestureDetector(
                      onPanUpdate: (details) {
                        final localPosition = details.localPosition;
                        onLetterDrag(localPosition);
                      },
                      onPanEnd: (_) => onDragEnd(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Çokgen animasyon widget
                          CirclePainterWidget(
                            key: _polygonKey,
                            initialSides: shuffledLetters.length.toDouble(),
                            size: 300,
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
                              top: -60,
                              child: FadeTransition(
                                opacity: _correctGuessOpacity,
                                child: Image.asset(
                                  currentCorrectGuessImage!,
                                  width: 200,
                                  height: 200,
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
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shuffle,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: 5),

                // Banner reklam alanı
                if (_isBannerAdReady)
                  Container(
                    height: _bannerAd.size.height.toDouble(),
                    width: _bannerAd.size.width.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ),
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
  void onLetterDrag(Offset position) {
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

    for (int i = 0; i < shuffledLetters.length; i++) {
      final point = _getLetterPosition(i, 300 / 2, Offset(150, 150));
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
            showInterstitialAd();
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
    final int sides = shuffledLetters.length;
    final adjustmentFactor = 0.8;
    final angle = -pi / 2 + (2 * pi / sides) * index;
    final dx = center.dx + (radius * adjustmentFactor) * cos(angle);
    final dy = center.dy + (radius * adjustmentFactor) * sin(angle);
    return Offset(dx, dy);
  }

  // Sayaç bitince yapılacaklar (örnek)
  void onTimerEnd(BuildContext context) {
    GlobalProperties.isTimeCompletedWhileAppClosed = false;
    showTimeCompletedDialog(context, () {
      setState(() {
        GlobalProperties.remainingLives.value = 3;
        GlobalProperties.countdownSeconds.value = 15;
        GlobalProperties.isTimerRunning.value = false;
      });
      saveGameData();
    });
  }

  /// Reklamlar
  void createAndLoadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner yüklenemedi: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/4411468910',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial yüklenemedi: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_isInterstitialAdReady) {
      _interstitialAd.show();
      _isInterstitialAdReady = false;
      loadInterstitialAd(); // Bir sonraki gösterim için yeniden yükle
    } else {
      print('Interstitial henüz hazır değil.');
    }
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
    GlobalProperties.remainingLives.value = prefs.getInt('remainingLives') ?? 3;
    GlobalProperties.countdownSeconds.value = prefs.getInt('countdownSeconds') ?? 15;
    GlobalProperties.isTimerRunning.value = prefs.getBool('isTimerRunning') ?? false;
    GlobalProperties.deadlineTimestamp = prefs.getInt('deadlineTimestamp') ?? 0;
  }
}

