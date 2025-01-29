import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_over_dialog.dart'; // Pop-up için ayrı dosya
import 'puzzle_data.dart'; // puzzleData'yı içe aktar
import 'next_level_dialog.dart';
import 'section_colors.dart'; // Renk haritası dosyasını dahil edin
import 'package:shared_preferences/shared_preferences.dart';
import 'app_bar_stats.dart'; // AppBarStats bileşenini dahil edin
import 'settings.dart';
import 'global_properties.dart';
import 'animated_polygon.dart';
import 'time_completed_dialog.dart';
import 'package:lottie/lottie.dart';
import 'show_coin_popup.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'level_complete_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bulmaca Oyunu',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PuzzleGame(),
    );
  }
}

class PuzzleGame extends StatefulWidget {
  final String? initialMainSection; // Başlangıç ana bölümü
  final String? initialSubSection; // Başlangıç alt bölümü
  final bool isCompleted;

  PuzzleGame({
    this.initialMainSection,
    this.initialSubSection,
    this.isCompleted = false, // Varsayılan olarak tamamlanmamış kabul edilir
  });

  @override
  _PuzzleGameState createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> with WidgetsBindingObserver, TickerProviderStateMixin {
  int currentPuzzle = 0;
  int currentIndex = 0;
  String feedbackMessage = '';
  List<String> shuffledLetters = [];
  List<String> selectedLetters = [];
  Set<String> visitedLetters = {};
  List<Offset> linePoints = []; // Çizgilerin noktaları
  Offset? temporaryLineEnd; // Geçici çizgi bitiş noktası
  List<String> correctWords = [];  // Doğru tahmin edilen kelimelerin tutulduğu liste
  List<int> visitedIndexes = []; // Ziyaret edilen harf indekslerini takip eder
  String currentMainSection = 'Ana Bölüm 1'; // Başlangıç ana bölümü
  String currentSubSection = '1'; // Başlangıç alt bölümü
  bool isShaking = false; // Shake effect için flag
  bool showSelectedLetters = false; // Harflerin görünme süresi için flag
  double shakeOffset = 0.0; // Shake animasyonu için offset
  int hintLetterIndex = -1; // Gösterilecek ipucu harfinin indeksi
  bool showHintLetter = false; // İpucu harfi görünürlük durumu
  List<int> revealedIndexes = []; // Açılan harflerin indekslerini saklar
  List<int> revealedIndexesForCurrentWord = []; // Mevcut kelimenin açılan harfleri
  List<int> hintRevealedIndexesForCurrentWord = [];
  bool isDataLoaded = false; // Veri yüklenme durumu
  bool isTimeCompletedWhileAppClosed = false;
  int? lastOpenedIndex; // <--- Yeni açılan harfin indeksini tutacak
  bool showWordHintAnimation = false;          // Animasyon görünür/gizli
  bool showCorrectAnswerImage = false; // Doğru cevap görseli için bayrak
  int correctAnswerCounter = 0; // Doğru cevapların sayısını takip eder
  List<String> correctGuessImages = []; // Görsellerin yolu
  String? currentCorrectGuessImage; // Şu anki gösterilen görsel
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  late Timer _bannerAdTimer;
  late InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool shouldShowAds = false;
  Timer? _wrongChoiceTimer;        // Yanlış seçim sonrası beklemeyi yöneten Timer
  bool _isWrongChoiceWaiting = false; // Yanlış seçim temizlenmeyi bekliyor mu?
  bool isWordHintActive = false; 


  late AnimationController _settingsIconController;
  late AnimationController _correctGuessController;
  late Animation<double> _correctGuessOpacity;


  final GlobalKey<AnimatedPolygonWidgetState> _polygonKey =
    GlobalKey<AnimatedPolygonWidgetState>();

  AudioPlayer? _audioPlayerForHints;
  AudioPlayer? _clickAudioPlayer;

  @override
  void initState() {
    super.initState();
    if (widget.isCompleted) {
      // Eğer bölüm tamamlanmışsa, tüm kelimeleri aç
      correctWords = puzzleSections[widget.initialMainSection]![widget.initialSubSection]!
          .map((wordData) => wordData['word']!)
          .toList();
    }

    // Görsel dosyalarının listesini doldurun
    correctGuessImages = [
      'assets/images/correct_guess/correct_guess1.png',
      'assets/images/correct_guess/correct_guess2.png',
      'assets/images/correct_guess/correct_guess3.png',
      'assets/images/correct_guess/correct_guess4.png',
    ];

    // Banner reklamı oluştur ve yükle
    createAndLoadBannerAd();

    loadInterstitialAd(); // Interstitial reklamı yükle

    // Banner reklamını 5 saniyede bir yenile
    _bannerAdTimer = Timer.periodic(Duration(seconds: 5), (_) {
      setState(() {
        _bannerAd.dispose(); // Mevcut banner reklamı temizle
        createAndLoadBannerAd(); // Yeni bir banner reklam oluştur ve yükle
        print("banner yenilendi.");
      });
    });

    // Correct Guess animasyonu için controller
    _correctGuessController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Yavaşça açılış ve kapanış süresi
    );
    _correctGuessOpacity = CurvedAnimation(
      parent: _correctGuessController,
      curve: Curves.easeInOut,
    );

    GlobalProperties.countdownSeconds.value = 15;
    // Animasyon denetleyicisini başlat
    _settingsIconController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    loadInitialSection();
    loadGameData().then((_) {
      setState(() {
        isDataLoaded = true;

        // *** YENİ *** Reklam gösterecek miyiz?
        shouldShowAds = checkIfShouldShowAds(currentMainSection, currentSubSection);

        // Eğer reklam göstermemiz gerekiyorsa Banner ve Interstitial yüklüyoruz.
        if (shouldShowAds) {
          createAndLoadBannerAd();
          loadInterstitialAd(); 
          _bannerAdTimer = Timer.periodic(Duration(seconds: 5), (_) {
            setState(() {
              _bannerAd.dispose();
              createAndLoadBannerAd();
            });
          });
        }

        // (Diğer kodlar, örneğin timer bitmiş mi kontrolü vs.)
        if (isTimeCompletedWhileAppClosed) {
          // onTimerEnd(context);
        } else if (GlobalProperties.remainingLives.value == 0 &&
                  GlobalProperties.countdownSeconds.value > 0 &&
                  !GlobalProperties.isTimerRunning.value) {
          startCountdownInAppBarStats();
        }
      });
    });

    _audioPlayerForHints = AudioPlayer();
    _clickAudioPlayer = AudioPlayer();
  }


  @override
  void dispose() {
    _bannerAdTimer.cancel(); // Timer'ı durdur
    _bannerAd.dispose(); // Mevcut reklamı temizle
    _interstitialAd.dispose();
    _correctGuessController.dispose(); // Correct Guess controller'ını temizle
    _settingsIconController.dispose(); // Animasyon denetleyicisini temizle
    WidgetsBinding.instance.removeObserver(this);
    saveGameData(); // Oyun kapatıldığında veriyi kaydet
    _audioPlayerForHints?.dispose();
    _clickAudioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isDataLoaded) {
      // Veri yüklenirken bir yüklenme animasyonu göster
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Stack(
        children: [
          // Arka plan görseli
          Positioned.fill(
            child: Image.asset(
              'assets/images/game_background/keops.jpg',
              fit: BoxFit.cover, // Tüm ekranı kaplayacak şekilde ayarlıyoruz
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
                    onTimerEnd(context); // Zaman dolduğunda pop-up göster
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
                    child: Icon(Icons.settings, size: 28), // Ayarlar simgesi
                  ),
                  onPressed: () async{
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer?.stop();
                      await _clickAudioPlayer?.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    _settingsIconController.forward(from: 0); // Animasyonu başlat

                    showDialog(
                      context: context,
                      builder: (context) => SettingsDialog(sourcePage: 'puzzle_game'),
                    ).then((_) {
                      _settingsIconController.reverse(); // Animasyonu geri al
                    });
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  height: 90,
                  margin: EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: sectionColors[currentMainSection]?['inside'] ?? Colors.grey,
                    border: Border.all(
                      color: sectionColors[currentMainSection]?['border'] ?? Colors.black,
                      width: 2.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Text(
                      puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['hint']!,
                      style: GlobalProperties.globalTextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      puzzleSections[currentMainSection]![currentSubSection]!.length,
                      (index) {
                        bool isLongestWord = puzzleSections[currentMainSection]![currentSubSection]![index]['word'] ==
                            puzzleSections[currentMainSection]![currentSubSection]!
                                .map((e) => e['word']!)
                                .reduce((a, b) => a.length > b.length ? a : b);

                        Color insideColor = sectionColors[currentMainSection]?['inside'] ?? Colors.grey;
                        Color borderColor = sectionColors[currentMainSection]?['border'] ?? Colors.black;

                        String word = puzzleSections[currentMainSection]![currentSubSection]![index]['word']!;
                        
                        return GestureDetector(
                          child: Container(
                            width: 50.0 * word.length,
                            height: 40,
                            decoration: BoxDecoration(
                              color: insideColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: isLongestWord ? Radius.circular(10) : Radius.zero,
                                bottomRight: isLongestWord ? Radius.circular(10) : Radius.zero,
                              ),
                              border: Border(
                                top: BorderSide(color: borderColor, width: 2.0),
                                left: BorderSide(color: borderColor, width: 2.0),
                                right: BorderSide(color: borderColor, width: 2.0),
                                bottom: isLongestWord
                                    ? BorderSide(color: borderColor, width: 2.0)
                                    : BorderSide.none,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(word.length, (charIndex) {
                                // Harf açık mı?
                                bool isRevealed = correctWords.contains(word) || widget.isCompleted ||
                                    (index == currentIndex && revealedIndexesForCurrentWord.contains(charIndex));

                                return AnimatedSwitcher(
                                  duration: Duration(milliseconds: 400),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(scale: animation, child: child);
                                  },
                                  // Eğer harf açılmışsa (isRevealed), Lottie animasyonlu Stack göster
                                  // Aksi halde '_' yaz
                                  child: isRevealed
                                      ? Stack(
                                          alignment: Alignment.center,
                                          key: ValueKey('stack-$index-$charIndex'),
                                          children: [
                                            Text(
                                              ' ${word[charIndex]} ',
                                              style: GlobalProperties.globalTextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 7,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 35,
                                              height: 35,
                                              child: Transform.scale(
                                                scale: 6.0, // Animasyonu içeride büyütmek için
                                                child: Lottie.asset(
                                                  'assets/animations/single_hint_animation.json',
                                                  repeat: false,
                                                  animate: true,
                                                ),
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
                                            letterSpacing: 7,
                                          ),
                                        ),
                                );
                              }),
                            ),
                          ),
                        );
                      },
                    ).reversed.toList(),
                  ),
                ),
                // İpucu Butonu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // SOLDAKİ BUTON
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 1.0),
                      child: GestureDetector(
                        onTap: widget.isCompleted ? null : showWordHint,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_fix_high,
                                color: Colors.white,
                                size: 25,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 10,
                                    width: 10,
                                    child: Lottie.asset(
                                      'assets/animations/coin_flip_animation.json',
                                      repeat: true,
                                      animate: true,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    // Kelimenin harf sayısı x 100
                                    '${(puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.length-1) * 100}',
                                    style: GlobalProperties.globalTextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ORTADA ANIMATEDCONTAINER (SEÇİLİ HARFLER)
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
                          width: 15.0 * (selectedLetters.length.clamp(1, double.infinity)),
                          height: 20,
                          decoration: BoxDecoration(
                            color: sectionColors[currentPuzzle]?['border'] ?? Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selectedLetters.join(''),
                            style: GlobalProperties.globalTextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    // SAĞDAKİ BUTON
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0, bottom: 1.0),
                      child: GestureDetector(
                        onTap: widget.isCompleted ? null : showSingleHint,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.white,
                                size: 25,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 10,
                                    width: 10,
                                    child: Lottie.asset(
                                      'assets/animations/coin_flip_animation.json',
                                      repeat: true,
                                      animate: true,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '100',
                                    style: GlobalProperties.globalTextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                        AnimatedPolygonWidget(
                          key: _polygonKey,
                          initialSides: shuffledLetters.length.toDouble(),
                          size: 300,
                          color: Colors.green,
                          letters: shuffledLetters,
                          selectedIndexes: visitedIndexes, // Seçilen harflerin indeksleri
                          linePoints: linePoints,
                          temporaryLineEnd: temporaryLineEnd,
                        ),
                         // Doğru cevap görseli ekleniyor
                        if (showCorrectAnswerImage && currentCorrectGuessImage != null)
                          Positioned(
                            top: -60, // AnimatedPolygonWidget'ın 10 px yukarısında
                            child: FadeTransition(
                              opacity: _correctGuessOpacity, // Animasyonlu görünürlük
                              child: Image.asset(
                                currentCorrectGuessImage!, // Rastgele seçilen görsel
                                width: 200, // İstediğiniz genişlik
                                height: 200, // İstediğiniz yükseklik
                              ),
                            ),
                          ),
                        Positioned(
                          child: GestureDetector(
                            onTap: widget.isCompleted ? null : shuffleLetters,
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
                SizedBox(height: 5), // Reklamın en altta görünmesi için Spacer ekleniyor
                if (shouldShowAds && _isBannerAdReady)
                  Container(
                    height: _bannerAd.size.height.toDouble(),
                    width: _bannerAd.size.width.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ),
              ],
            ),
          ),
          // 3) LOTTIE ANİMASYONU (YENİ) - EN ÜSTE EKLENİYOR
          Visibility(
            visible: showWordHintAnimation, // Bu flag true olunca görünecek
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Transform.scale(
                  scale: 7,
                  child: Transform.rotate(
                    angle: 45.0,
                    child: Lottie.asset(
                    'assets/animations/word_hint_animation.json',
                    fit: BoxFit.contain,
                    repeat: false,
                    ),
                  )
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Offset _getLetterPosition(int index, double radius, Offset center) {
    final int sides = shuffledLetters.length;
    final adjustmentFactor = 0.7;
    final angle = -pi / 2 + (2 * pi / sides) * index;
    final dx = center.dx + (radius * adjustmentFactor) * cos(angle);
    final dy = center.dy + (radius * adjustmentFactor) * sin(angle);
    return Offset(dx, dy);
  }

  void shuffleLetters() {
    setState(() {
      shuffledLetters.shuffle();
      selectedLetters.clear();
      visitedLetters.clear();
      linePoints.clear(); // Çizgileri temizle
      temporaryLineEnd = null;
      showSelectedLetters = false;
    });
  }

  void onLetterDrag(Offset position) {
    if (widget.isCompleted) return;
    // Eğer yanlış bir seçim beklemesi varsa, ekrana dokunulduğunda hemen iptal et
    if (_isWrongChoiceWaiting) {
      _wrongChoiceTimer?.cancel(); // Timer'ı iptal et
      _isWrongChoiceWaiting = false;

      // Ekrandaki yanlış seçimi hemen temizle
      setState(() {
        showSelectedLetters = false;
        selectedLetters.clear();
        visitedIndexes.clear();
        linePoints.clear();
      });
      // İptal ettikten sonra yeni seçimi dinlemeye devam edebiliriz
    }

    for (int i = 0; i < shuffledLetters.length; i++) {
      // Pozisyonları dinamik olarak belirle
      final point = _getLetterPosition(i, 300 / 2, Offset(150, 150));
      final hitBox = Rect.fromCircle(center: point, radius: 30); // Çember alanı

      if (hitBox.contains(position)) {
        if (visitedIndexes.length > 1 && visitedIndexes[visitedIndexes.length - 2] == i) {
          // Kullanıcı sondan bir önceki harfin üzerine geri geldi
          setState(() {
            selectedLetters.removeLast(); // Son seçimi kaldır
            visitedIndexes.removeLast(); // İndeks listesinden çıkar
            linePoints.removeLast(); // Çizgi noktasını kaldır
          });
          break;
        }

        if (!visitedIndexes.contains(i)) {
          // Yeni bir harf seçildiğinde
          setState(() {
            selectedLetters.add(shuffledLetters[i]); // Harfi ekle
            visitedIndexes.add(i); // İndeksi ekle
            linePoints.add(point); // Çizgi noktasını ekle
            showSelectedLetters = true; // Kutuyu göster
          });
          break;
        }
      }
    }
    setState(() {
      temporaryLineEnd = position; // Geçici çizgi bitiş noktası
    });
  }

  void onDragEnd() {
    if (GlobalProperties.remainingLives.value == 0) {
      setState(() {
        feedbackMessage = "Kalan hak yok! Ekstra hak almanız gerekiyor.";
      });
      return;
    }

    setState(() {
      temporaryLineEnd = null; // Parmağı kaldırınca geçici çizgiyi temizle
      String selectedWord = selectedLetters.join('');
      String correctWord =
          puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!;
      int currentSubSectionNumber = int.tryParse(currentSubSection) ?? 1;

      if (selectedLetters.length < correctWord.length) {
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
        return;
      }

      if (selectedWord == correctWord) {
        feedbackMessage = "Doğru tahmin!";
        correctAnswerCounter++;
        if (!correctWords.contains(correctWord)) {
          correctWords.add(correctWord);
        }

        if (correctAnswerCounter % 2 == 0) {
          // Rastgele bir görsel seç
          setState(() {
            currentCorrectGuessImage = (correctGuessImages..shuffle()).first;
            showCorrectAnswerImage = true;
          });    
        }  

        // Animasyonu başlat
        _correctGuessController.forward(from: 0).then((_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              showCorrectAnswerImage = false;
            });
          });
        });

        _polygonKey.currentState?.reduceSides(); // Kenar sayısını azalt
        if (currentIndex < puzzleSections[currentMainSection]![currentSubSection]!.length - 1) {
          currentIndex++;
          revealedIndexesForCurrentWord.clear();
          selectedLetters.clear();
          visitedIndexes.clear();
          linePoints.clear();
          shuffledLetters =
              puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.split('');
          shuffleLetters();
        } else {
          // Bölüm tamamlandı
          if (correctWords.length ==
              puzzleSections[currentMainSection]![currentSubSection]!.length) {
            int maxWordLength = puzzleSections[currentMainSection]![currentSubSection]!
                .map((wordData) => wordData['word']!.length)
                .reduce((a, b) => a > b ? a : b);

            showInterstitialAd();

            // Çokgen kenarlarını güncellemek için bir callback'e bırak
            showNextLevelDialog(
              context,
              currentMainSection,
              currentSubSection,
              () {
                _polygonKey.currentState?.setSides(maxWordLength.toDouble());
                goToNextSection();
                currentIndex = 0;
                correctWords.clear();
                selectedLetters.clear();
                visitedIndexes.clear();
                linePoints.clear();
                shuffledLetters = puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.split('');
                shuffleLetters();
              },
              () {
                Navigator.of(context).pop();
              },
              incrementScore,
              saveGameData,
            );
            if (currentSubSectionNumber % 10 == 0) {
              showLevelCompleteDialog(context);
            }
          }
        }
      } else {
        if (!(DateTime.now().month == 4 && DateTime.now().day == 19)) {
          GlobalProperties.remainingLives.value = max(0, GlobalProperties.remainingLives.value - 1);
        }
        saveGameData();
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
        if (GlobalProperties.remainingLives.value == 0) {
          startCountdownInAppBarStats();
          showGameOverDialog(
            context,
            resetGame,
            gainExtraLife,
            () {
              Navigator.of(context).pop();
            },
          );
        }
      }
    });
  }


  void triggerShakeEffect() {
    setState(() {
      isShaking = true;
    });

    if (GlobalProperties.isVibrationOn) {
      HapticFeedback.vibrate();
      print("titredi.");
    }

    // Animasyon için hızlı bir şekilde iki kere sağa sola hareket
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

  void checkAnswer(String selectedWord, String correctWord) {
    if (GlobalProperties.remainingLives.value == 0) {
      // Hak sıfırsa oynanamaz
      setState(() {
      });
      return;
    }

    if (selectedWord == correctWord) {
      setState(() {
      });
    } else {
      setState(() {
        if (!(DateTime.now().month == 4 && DateTime.now().day == 19)) {
          GlobalProperties.remainingLives.value = max(0, GlobalProperties.remainingLives.value - 1);
        }
        saveGameData();
      });

      if (GlobalProperties.remainingLives.value == 0) {
        showGameOverDialog(
          context,
          resetGame,
          gainExtraLife,
          () {
            Navigator.of(context).pop();
          },
        );
      }
    }
  }


  /// Oyunu sıfırlayan fonksiyon
  void resetGame() {
    setState(() {
      currentPuzzle = 0; // İlk bölüme dön
      currentIndex = 0; // İlk kelimeye dön
      GlobalProperties.remainingLives.value = 3; // Kullanıcıya tekrar 5 hak ver
      feedbackMessage = ''; // Geri bildirim mesajını temizle
      selectedLetters.clear(); // Seçilen harfleri temizle
      visitedLetters.clear();
      linePoints.clear();
    });
  }

  void gainExtraLife() {
    // Reklam hazırsa göster
    if (_isInterstitialAdReady) {
      _interstitialAd.show();
      _isInterstitialAdReady = false;
      loadInterstitialAd(); // Reklamı tekrar yükle

      // Reklam gösteriminden sonra hak ekleme işlemi
      _interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          // Kullanıcı reklamı kapattıktan sonra hak ekle
          ad.dispose();
          setState(() {
            GlobalProperties.remainingLives.value++; // Kullanıcıya bir hak ekle
            saveGameData();
          });
          print("Reklam kapatıldı, hak eklendi.");
        }
      );
    }
  }


  String? getNextSubSection(String mainSection, String currentSub) {
    List<String> subSections = puzzleSections[mainSection]!.keys.toList();

    int currentSubIndex = subSections.indexOf(currentSub);
    if (currentSubIndex + 1 < subSections.length) {
      // Bir sonraki alt bölüme geç
      return subSections[currentSubIndex + 1];
    } else {
      // Mevcut ana bölümde alt bölüm bitti
      return null; // Eğer alt bölüm kalmadıysa null döner
    }
  }


  void goToNextSection() {
    String? nextSubSection = getNextSubSection(currentMainSection, currentSubSection);

    if (nextSubSection != null) {
      setState(() {
        currentSubSection = nextSubSection;
        currentIndex = 0;
        correctWords.clear();
        selectedLetters.clear();
        visitedIndexes.clear();
        linePoints.clear();

        // Yeni alt bölümdeki en uzun kelimeyi al ve çokgenin kenar sayısını güncelle
        int maxWordLength = puzzleSections[currentMainSection]![currentSubSection]!
            .map((wordData) => wordData['word']!.length)
            .reduce((a, b) => a > b ? a : b);
        _polygonKey.currentState?.setSides(maxWordLength.toDouble());

        shuffledLetters =
            puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.split('');
        shuffledLetters.shuffle(); // Harfleri karıştır
      });
    } else {
      List<String> mainSections = puzzleSections.keys.toList();
      int currentMainIndex = mainSections.indexOf(currentMainSection);

      if (currentMainIndex + 1 < mainSections.length) {
        setState(() {
          currentMainSection = mainSections[currentMainIndex + 1];
          currentSubSection = puzzleSections[currentMainSection]!.keys.first;
          currentIndex = 0;
          correctWords.clear();
          selectedLetters.clear();
          visitedIndexes.clear();
          linePoints.clear();

          // Yeni ana bölümdeki en uzun kelimeyi al ve çokgenin kenar sayısını güncelle
          int maxWordLength = puzzleSections[currentMainSection]![currentSubSection]!
              .map((wordData) => wordData['word']!.length)
              .reduce((a, b) => a > b ? a : b);
          _polygonKey.currentState?.setSides(maxWordLength.toDouble());

          shuffledLetters =
              puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.split('');
          shuffledLetters.shuffle(); // Harfleri karıştır
        });
      }
    }
  }

  Future<void> loadInitialSection() async {
    if (widget.initialMainSection != null && widget.initialSubSection != null) {
      setState(() {
        currentMainSection = widget.initialMainSection!;
        currentSubSection = widget.initialSubSection!;
        currentIndex = 0;

        // Seçilen bölümün ilk kelimesinin harflerini ayarla ve karıştır
        shuffledLetters = puzzleSections[currentMainSection]![currentSubSection]![0]['word']!.split('');
        shuffledLetters.shuffle(); // Harfleri karıştır
      });
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> completedSections = prefs.getStringList('completedSections') ?? [];

    for (String mainSection in puzzleSections.keys) {
      for (String subSection in puzzleSections[mainSection]!.keys) {
        String key = "$mainSection-$subSection";
        if (!completedSections.contains(key)) {
          setState(() {
            currentMainSection = mainSection;
            currentSubSection = subSection;
            currentIndex = 0;

            // İlk tamamlanmamış bölümün harflerini ayarla ve karıştır
            shuffledLetters = puzzleSections[currentMainSection]![currentSubSection]![0]['word']!.split('');
            shuffledLetters.shuffle(); // Harfleri karıştır
          });
          return;
        }
      }
    }
  }

  void incrementScore(int incrementAmount, VoidCallback onComplete) {
    int steps = 10; // Skor artışı kaç adıma bölünecek
    int stepAmount = (incrementAmount / steps).ceil(); // Her adımda ne kadar artacak
    int currentStep = 0;

    Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        if (currentStep < steps) {
          GlobalProperties.coin.value += stepAmount; // Skoru adım adım artır
          currentStep++;
        } else {
          // Timer'ı durdur
          timer.cancel();
          onComplete(); // Artış tamamlandığında geri çağırma çalıştır
        }
      });
    });
  }

  void onTimerEnd(BuildContext context) {
    GlobalProperties.isTimeCompletedWhileAppClosed = false;
    // Timer bitince popup göstermek istiyorsan, göster
    showTimeCompletedDialog(context, () {
      // Popup kapatılırken hakları yenile
      setState(() {
        GlobalProperties.remainingLives.value = 3;
        GlobalProperties.countdownSeconds.value = 15;
        GlobalProperties.isTimerRunning.value = false;
      });
      saveGameData();
    });
  }

  void startCountdownInAppBarStats() {
    // 1) Timer’ın bitiş zamanını hesapla
    final now = DateTime.now().millisecondsSinceEpoch;
    GlobalProperties.deadlineTimestamp = now + (GlobalProperties.countdownSeconds.value * 1000);

    // 2) Timer’ın aktif olduğunu işaretle
    GlobalProperties.isTimerRunning.value = true;

    // 3) Hemen kaydet
    saveGameData();
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
      isTimeCompletedWhileAppClosed = true;

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

  void showSingleHint() async{
    if (GlobalProperties.isSoundOn && GlobalProperties.coin.value > 100){
      await _audioPlayerForHints?.stop();
      await _audioPlayerForHints?.play(
        AssetSource('audios/hint_audio.mp3'),
      );
    }
    setState(() {
      // Önce coin kontrolü yapıyoruz
      if (GlobalProperties.coin.value < 100) {
        // Coin 100'den az ise uyarı popup gösteriliyor
        showCoinPopup(context);
        return; // Popup gösterdikten sonra fonksiyonu sonlandır
      } else {
        // Coin yeterliyse 100 düşür
        GlobalProperties.coin.value -= 100;
        saveGameData();
      }

      // Mevcut ipucu mekanizması
      String currentWord =
          puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!;
      
      int currentSubSectionNumber = int.tryParse(currentSubSection) ?? 1;

      List<int> unopenedIndexes = List.generate(currentWord.length, (i) => i)
          .where((i) => !revealedIndexesForCurrentWord.contains(i))
          .toList();

      if (unopenedIndexes.isNotEmpty) {
        int randomIndex = unopenedIndexes[Random().nextInt(unopenedIndexes.length)];
        revealedIndexesForCurrentWord.add(randomIndex);
        hintRevealedIndexesForCurrentWord.add(randomIndex);

        // YENİ: Açılan harfi kaydet
        lastOpenedIndex = randomIndex;

        // Örnek: 1 saniye sonra lastOpenedIndex’i sıfırlayıp animasyonu gizlemek isterseniz:
        Timer(Duration(seconds: 1), () {
          setState(() {
            lastOpenedIndex = null; 
          });
        });
      }

      if (revealedIndexesForCurrentWord.length == currentWord.length) {
        feedbackMessage = "Doğru tahmin!";
        if (!correctWords.contains(currentWord)) {
          correctWords.add(currentWord);
        }

        _polygonKey.currentState?.reduceSides(); // Kenar sayısını azalt

        if (currentIndex <
            puzzleSections[currentMainSection]![currentSubSection]!.length - 1) {
          currentIndex++;
          revealedIndexesForCurrentWord.clear();
          selectedLetters.clear();
          visitedIndexes.clear();
          linePoints.clear();
          shuffledLetters = puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.split('');
          shuffleLetters();
        } else {
          revealedIndexesForCurrentWord.clear();
          // Bölüm tamamlandı
          if (correctWords.length ==
              puzzleSections[currentMainSection]![currentSubSection]!.length) {
            int maxWordLength = puzzleSections[currentMainSection]![currentSubSection]!
                .map((wordData) => wordData['word']!.length)
                .reduce((a, b) => a > b ? a : b);

            showInterstitialAd();

            // Çokgen kenarlarını güncellemek için bir callback'e bırak
            showNextLevelDialog(
              context,
              currentMainSection,
              currentSubSection,
              () {
                _polygonKey.currentState?.setSides(maxWordLength.toDouble());
                goToNextSection();
                currentIndex = 0;
                correctWords.clear();
                selectedLetters.clear();
                visitedIndexes.clear();
                linePoints.clear();
                shuffledLetters = puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.split('');
                shuffleLetters();
              },
              () {
                Navigator.of(context).pop();
              },
              incrementScore,
              saveGameData,
            );
            if (currentSubSectionNumber % 10 == 0) {
              showLevelCompleteDialog(context);
            }
          }
        }
      }
    });
  }

  Future<void> showWordHint() async {
    if (isWordHintActive) {
      return; // Animasyon hâlâ çalışıyorsa tekrar tıklanmayı engelle
    }

    // 1) Coin kontrolü
    String currentWord =
        puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!;
    int cost = (currentWord.length - 1) * 100;

    if (GlobalProperties.coin.value < cost) {
      showCoinPopup(context);
      return;
    }

    setState(() {
      isWordHintActive = true; // Animasyon başladı
    });

    if (GlobalProperties.isSoundOn){
      await _audioPlayerForHints?.stop(); 
      await _audioPlayerForHints?.play(
        AssetSource('audios/magic_wand_audio.mp3'),
      );
    }
    
    // Coin yeterliyse düş
    GlobalProperties.coin.value -= cost;
    saveGameData();

    // 2) Animasyonu görünür hale getir
    setState(() {
      showWordHintAnimation = true; // Lottie animasyonu başlıyor
    });

    // >>> DEĞİŞİKLİK - Lottie animasyonu tamamlanana kadar beklemek için bir gecikme ekleyin:
    // İsterseniz 2 saniye yerine animasyonun süresine uyacak başka bir değeri kullanabilirsiniz.
    await Future.delayed(const Duration(seconds: 2));

    // 3) Harfleri teker teker açma - animasyon bittikten sonra başlatıyoruz
    revealedIndexesForCurrentWord.clear(); // Önce sıfırla (daha önce açık harfler varsa)

    for (int i = 0; i < currentWord.length; i++) {
      setState(() {
        revealedIndexesForCurrentWord.add(i);
        hintRevealedIndexesForCurrentWord.add(i);
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 4) Tüm harfler açıldıktan sonra "Doğru tahmin" akışını başlat
    setState(() {
      feedbackMessage = "Doğru tahmin!";
      int currentSubSectionNumber = int.tryParse(currentSubSection) ?? 1;

      if (!correctWords.contains(currentWord)) {
        correctWords.add(currentWord);
      }
      _polygonKey.currentState?.reduceSides();

      if (currentIndex < puzzleSections[currentMainSection]![currentSubSection]!.length - 1) {
        currentIndex++;
        revealedIndexesForCurrentWord.clear();
        selectedLetters.clear();
        visitedIndexes.clear();
        linePoints.clear();
        shuffledLetters =
            puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.split('');
        shuffleLetters();
      } else {
        revealedIndexesForCurrentWord.clear();
        if (correctWords.length ==
            puzzleSections[currentMainSection]![currentSubSection]!.length) {
          int maxWordLength = puzzleSections[currentMainSection]![currentSubSection]!
              .map((wordData) => wordData['word']!.length)
              .reduce((a, b) => a > b ? a : b);
          
          showInterstitialAd(); // Reklamı göster

          showNextLevelDialog(
            context,
            currentMainSection,
            currentSubSection,
            () {
              _polygonKey.currentState?.setSides(maxWordLength.toDouble());
              goToNextSection();
              currentIndex = 0;
              correctWords.clear();
              selectedLetters.clear();
              visitedIndexes.clear();
              linePoints.clear();
              shuffledLetters =
                  puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!.split('');
              shuffleLetters();
            },
            () {
              Navigator.of(context).pop();
            },
            incrementScore,
            saveGameData,
          );
          if (currentSubSectionNumber % 10 == 0) {
            showLevelCompleteDialog(context);
          }
        }
      }
    });

    // 5) Bir süre daha animasyon gözüksün (opsiyonel)
    await Future.delayed(const Duration(seconds: 1));

    // 6) Animasyonu kapat
    setState(() {
      showWordHintAnimation = false;
    });

    setState(() {
      isWordHintActive = false; // Animasyon bitti
    });
  }

  void createAndLoadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/2934735716', // AdMob reklam birimi kimliğiniz
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  // Interstitial reklamı yükleyen fonksiyon
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/4411468910', // AdMob interstitial reklam birimi kimliğiniz
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  // Interstitial reklamı gösteren fonksiyon
  void showInterstitialAd() {
    if (shouldShowAds && _isInterstitialAdReady) {
      _interstitialAd.show();
      _isInterstitialAdReady = false;
      loadInterstitialAd(); // Reklamı tekrar yükle
    } else {
      print('Interstitial ad is not ready yet.');
    }
  }

  bool checkIfShouldShowAds(String mainSection, String subSection) {
    // Eğer "Ana Bölüm 1" ise alt bölüm sayısını kontrol edelim:
    if (mainSection == "Ana Bölüm 1") {
      final subSecInt = int.tryParse(subSection) ?? 0;
      // 10. alt bölümü geçtikten sonra, yani 11 veya üstüyse reklam göster
      if (subSecInt > 10) {
        return true;
      } else {
        return false;
      }
    } else {
      // Ana Bölüm 2 veya 3 veya başka bir bölüme geçilmişse direkt göster
      return true;
    }
  }
}