import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pyramid_puzzle/main.dart';
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

  // Data yüklendi mi?
  bool isDataLoaded = false;

  // Gün (tarih) kontrolü için
  late DateTime lastPuzzleDate; // Son oynanan tarih

  // Çokgen animasyon widget key
  final GlobalKey<AnimatedPolygonWidgetState> _polygonKey =
      GlobalKey<AnimatedPolygonWidgetState>();

  // Ses oynatıcı
  AudioPlayer? _clickAudioPlayer;

  bool puzzleForTodayCompleted = false;

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
      // Eğer bugünün puzzle'ı çoktan tamamlanmışsa geri sayımı başlat.
      if (puzzleForTodayCompleted) {
        _startNextPuzzleCountdown();
      }
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

    // Eğer puzzleIndex, dailyPuzzleData listesi boyutunu aşarsa
    // artık oynanacak puzzle kalmamış demektir (uygulama mantığına göre davranın).
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

                // Kelimelerin (özellikle birden çok kelime varsa) gösterimi
                // currentPuzzle listesini tersten çiziyor (örnek kodda öyle yapılmış).
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxWidth = constraints.maxWidth;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          currentPuzzle.length,
                          (index) {
                            String word = currentPuzzle[index]['word']!;
                            bool isRevealed = correctWords.contains(word);

                            // En uzun kelime olabilir vs. (opsiyonel),
                            // basitçe yükseklik verip çerçeve çizelim
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
                                children:
                                    List.generate(word.length, (charIndex) {
                                  return isRevealed
                                      ? Text(
                                          ' ${word[charIndex]} ',
                                          style:
                                              GlobalProperties.globalTextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 5,
                                          ),
                                        )
                                      : Text(
                                          ' _ ',
                                          style:
                                              GlobalProperties.globalTextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 5,
                                          ),
                                        );
                                }),
                              ),
                            );
                          },
                        ).reversed.toList(),
                      );
                    },
                  ),
                ),

                // Seçilen harfleri (geçici) gösteren satır
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

                // Harfleri çokgen şeklinde gösteren ve sürükleyerek tahmin etmeyi sağlayan bölüm
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AbsorbPointer(
                    absorbing: puzzleForTodayCompleted,
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
                          AnimatedPolygonWidget(
                            key: _polygonKey,
                            initialSides: shuffledLetters.length.toDouble(),
                            size: 300,
                            color: Colors.green,
                            letters: shuffledLetters,
                            selectedIndexes: visitedIndexes,
                            linePoints: linePoints,
                            temporaryLineEnd: temporaryLineEnd,
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
                              onTap: shuffleLetters,
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
          // 2) Puzzle tamamlanmışsa, *üzerine* yarı saydam bir katman ekleyip geri sayımı gösterelim
          if (puzzleForTodayCompleted)
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Stack(
                children: [
                  // Sağ üstteki çarpı butonu
                  Positioned(
                    top: 50,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => HomePage()), // HomePage'e yönlendir
                          (route) => false, // Önceki tüm sayfaları kaldır
                        );
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Ortadaki geri sayım metni
                  Center(
                    child: Text(
                      'Yeni bulmaca için kalan süre:\n${_formatTime(nextPuzzleSeconds)}',
                      textAlign: TextAlign.center,
                      style: GlobalProperties.globalTextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ).copyWith(decoration: TextDecoration.none),
                    ),
                  ),
                ],
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
          // Günlük bulmaca (o günün tüm kelimeleri) bitti
          // Tamamlandı diyebiliriz. Yarın yeni puzzle verilecek.
          puzzleForTodayCompleted = true;
          showInterstitialAd();

          // İsterseniz bir diyalog da gösterebilirsiniz:
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: Text('Tebrikler!'),
                content: Text('Bugünün bulmacasını tamamladınız.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: Text('Kapat'),
                  ),
                ],
              );
            },
          );

          // Aynı puzzle kalacak; yarın puzzleIndex artacak.
          // Yine de bugünün bulmacası tekrar görünmeyecek şekilde
          // isterseniz currentIndex vb. sıfırlayabilirsiniz.
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
    final adjustmentFactor = 0.7;
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

  /// Verileri kaydet (SharedPreferences):
  ///  - puzzleIndex
  ///  - bugünkü tarih
  ///  - coin, remainingLives, vb.
  ///  - Sayaç bilgileri
  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('puzzleIndex', puzzleIndex);

    DateTime now = DateTime.now();
    String todayString = _dateToString(now);
    await prefs.setString('lastPuzzleDate', todayString);

    // GlobalProperties
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);

    await prefs.setBool('puzzleForTodayCompleted', puzzleForTodayCompleted);
  }

  /// Uygulama başlarken verileri yükle:
  ///  - puzzleIndex
  ///  - bir önceki gün/tarih
  ///  - eğer yeni güne geçilmişse puzzleIndex bir artır
  ///  - Sayaç bilgileri vb.
  Future<void> loadGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    puzzleIndex = prefs.getInt('puzzleIndex') ?? 0;
    String? savedDate = prefs.getString('lastPuzzleDate');
    lastPuzzleDate = savedDate != null ? _stringToDate(savedDate) : DateTime.now();

    // Bugünün tarihi
    DateTime now = DateTime.now();
    String todayString = _dateToString(now);

    // Yeni güne geçilmiş mi?
    if (savedDate != null && savedDate != todayString) {
      // Yeni gün => puzzleIndex artır (eğer verimiz elveriyorsa)
      if (puzzleIndex < dailyPuzzleData.length - 1) {
        puzzleIndex++;
      }
      await prefs.setInt('puzzleIndex', puzzleIndex);
      await prefs.setString('lastPuzzleDate', todayString);
    }

    // 1. puzzleForTodayCompleted değerini yükle
    bool storedPuzzleCompleted = prefs.getBool('puzzleForTodayCompleted') ?? false;

    // 2. Eğer gün değişmemişse ve puzzleIndex değişmemişse, kaldığımız yerden devam:
    if (savedDate == todayString) {
      puzzleForTodayCompleted = storedPuzzleCompleted;
    } else {
      // Yeni günse veya puzzleIndex değiştiyse, bugünün puzzle'ı henüz tamamlanmamıştır.
      puzzleForTodayCompleted = false;
      await prefs.setBool('puzzleForTodayCompleted', false);
    }

    // Mevcut puzzle'ın ilk kelimesinin harflerini karıştır
    if (puzzleIndex < dailyPuzzleData.length) {
      final currentWord =
          dailyPuzzleData[puzzleIndex][currentIndex]['word'] ?? '';
      shuffledLetters = currentWord.split('');
      shuffledLetters.shuffle();

      // Eğer puzzleForTodayCompleted == true ise, tüm kelimeleri otomatik olarak "doğru" say
      if (puzzleForTodayCompleted) {
        correctWords.addAll(
          dailyPuzzleData[puzzleIndex].map((m) => m['word']!).toList()
        );
      }
    }

    // GlobalProperties
    GlobalProperties.coin.value = prefs.getInt('coin') ?? 0;
    GlobalProperties.remainingLives.value = prefs.getInt('remainingLives') ?? 3;
    GlobalProperties.countdownSeconds.value = prefs.getInt('countdownSeconds') ?? 15;
    GlobalProperties.isTimerRunning.value = prefs.getBool('isTimerRunning') ?? false;

    GlobalProperties.deadlineTimestamp = prefs.getInt('deadlineTimestamp') ?? 0;
    final nowMs = now.millisecondsSinceEpoch;

    // Sayaçın bitip bitmediğini kontrol et
    if (GlobalProperties.deadlineTimestamp != 0 &&
        GlobalProperties.deadlineTimestamp <= nowMs) {
      // Süre bitmiş
      GlobalProperties.isTimeCompletedWhileAppClosed = true;
      await saveGameData();
    } else if (GlobalProperties.deadlineTimestamp != 0) {
      // Devam eden süre varsa, kaç saniye kaldı?
      final remainingMillis = GlobalProperties.deadlineTimestamp - nowMs;
      final remainingSecs = (remainingMillis / 1000).ceil();

      GlobalProperties.countdownSeconds.value =
          remainingSecs > 0 ? remainingSecs : 0;
      GlobalProperties.isTimerRunning.value = true;
    }

    // Mevcut puzzle'ın ilk kelimesinin harflerini karıştır
    if (puzzleIndex < dailyPuzzleData.length) {
      final currentWord =
          dailyPuzzleData[puzzleIndex][currentIndex]['word'] ?? '';
      shuffledLetters = currentWord.split('');
      shuffledLetters.shuffle();
    }
  }

  /// Tarihi string'e çevirme (yyyyMMdd vb.)
  String _dateToString(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// String'i tarihe çevirme
  DateTime _stringToDate(String dateString) {
    final year = int.parse(dateString.substring(0, 4));
    final month = int.parse(dateString.substring(4, 6));
    final day = int.parse(dateString.substring(6, 8));
    return DateTime(year, month, day);
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  void _startNextPuzzleCountdown() {
    final now = DateTime.now();
    // Bir sonraki gün geceyarısını bul (yani yarın 00:00)
    final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);

    // Şu andan yarın geceyarısına kadar kaç saniye var?
    final diff = tomorrowMidnight.difference(now).inSeconds;

    setState(() {
      nextPuzzleSeconds = diff;
    });

    // Her saniye bir kez geri sayımı azalt
    _nextPuzzleTimer?.cancel();
    _nextPuzzleTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (nextPuzzleSeconds > 0) {
        setState(() {
          nextPuzzleSeconds--;
        });
      } else {
        // Sayaç bittiğinde (geceyarısı oldu):
        timer.cancel();
        // Bir sonraki puzzle yükleme mantığı zaten loadGameData() içinde gün/tarih kontrolüyle yapılıyor.
        // Eğer istersek burada loadGameData() çağırabiliriz veya sayfayı yeniden yükleyebiliriz.
      }
    });
  }
}
