import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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
      home: PuzzleGame(),
    );
  }
}

class PuzzleGame extends StatefulWidget {
  final String? initialMainSection; // Başlangıç ana bölümü
  final String? initialSubSection; // Başlangıç alt bölümü

  PuzzleGame({this.initialMainSection, this.initialSubSection});

  @override
  _PuzzleGameState createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<PuzzleGame> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
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
  bool isDataLoaded = false; // Veri yüklenme durumu
  bool isTimeCompletedWhileAppClosed = false;

  late AnimationController _settingsIconController;


  final GlobalKey<AnimatedPolygonWidgetState> _polygonKey =
    GlobalKey<AnimatedPolygonWidgetState>();



  @override
  void initState() {
    super.initState();
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
      });

      // 1) Eğer uygulama kapalıyken timer süresi dolmuşsa,
      //    onTimerEnd fonksiyonunu otomatik tetikle.
      if (isTimeCompletedWhileAppClosed) {
        //onTimerEnd(context);
      } 
      // 2) Değilse ve haklar yine 0 ise, sayacı başlatmayı düşünebilirsin
      else if (GlobalProperties.remainingLives.value == 0 &&
               GlobalProperties.countdownSeconds.value > 0 &&
               !GlobalProperties.isTimerRunning.value) {
        startCountdownInAppBarStats();
      }
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



  @override
  void dispose() {
    _settingsIconController.dispose(); // Animasyon denetleyicisini temizle
    WidgetsBinding.instance.removeObserver(this);
    saveGameData(); // Oyun kapatıldığında veriyi kaydet
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
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
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
              onPressed: () {
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
                  style: TextStyle(
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
                      onTap: () {
                        if (GlobalProperties.remainingLives.value == 0) {
                          setState(() {
                            feedbackMessage = "Kalan hak yok! Ekstra hak almanız gerekiyor.";
                          });
                          return;
                        }
                        String selectedWord = selectedLetters.join('');
                        checkAnswer(
                          selectedWord,
                          puzzleSections[currentMainSection]![currentSubSection]![index]['word']!,
                        );
                      },
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
                        child: Text(
                          correctWords.contains(word)
                              ? word.characters.join('  ') // Doğru tahmin edilen kelime
                              : index == currentIndex
                                  ? List.generate(word.length, (charIndex) {
                                      return revealedIndexesForCurrentWord.contains(charIndex)
                                          ? ' ' + word[charIndex] + ' '
                                          : ' _ ';
                                    }).join('')
                                  : ' _ ' * word.length,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ).reversed.toList(),
              ),
            ),
            // İpucu Butonu
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 1.0),
                child: GestureDetector(
                  onTap: () {
                    // İpucu gösterme işlevi
                    showHint();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.yellow, // Sarı arka plan
                      shape: BoxShape.circle, // Daire şekli
                    ),
                    child: Icon(
                      Icons.lightbulb, // Ampul simgesi
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
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
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
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
            SizedBox(height: 20),
          ],
        ),
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

      if (selectedLetters.length < correctWord.length) {
        triggerShakeEffect();
        Future.delayed(Duration(seconds: 1), () {
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
        if (!correctWords.contains(correctWord)) {
          correctWords.add(correctWord);
        }

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
          }
        }
      } else {
        GlobalProperties.remainingLives.value = max(0, GlobalProperties.remainingLives.value - 1);
        saveGameData();
        triggerShakeEffect();
        Future.delayed(Duration(seconds: 1), () {
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
        GlobalProperties.remainingLives.value = max(0, GlobalProperties.remainingLives.value - 1); // Sıfırın altına düşmesine izin verme
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

  /// Kullanıcıya bir hak daha veren fonksiyon
  void gainExtraLife() {
    setState(() {
      GlobalProperties.remainingLives.value++; // Kullanıcıya bir hak daha ekle
      saveGameData();
    });
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
          GlobalProperties.score.value += stepAmount; // Skoru adım adım artır
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


  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', GlobalProperties.score.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
  }

  Future<void> loadGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    GlobalProperties.score.value = prefs.getInt('score') ?? 0;
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


  void showHint() {
    setState(() {
      String currentWord =
          puzzleSections[currentMainSection]![currentSubSection]![currentIndex]['word']!;

      List<int> unopenedIndexes = List.generate(currentWord.length, (i) => i)
          .where((i) => !revealedIndexesForCurrentWord.contains(i))
          .toList();

      if (unopenedIndexes.isNotEmpty) {
        int randomIndex = unopenedIndexes[Random().nextInt(unopenedIndexes.length)];
        revealedIndexesForCurrentWord.add(randomIndex);
      }

      if (revealedIndexesForCurrentWord.length == currentWord.length) {
        feedbackMessage = "Doğru tahmin!";
        if (!correctWords.contains(currentWord)) {
          correctWords.add(currentWord);
        }

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
          revealedIndexesForCurrentWord.clear();
          // Bölüm tamamlandı
          if (correctWords.length ==
              puzzleSections[currentMainSection]![currentSubSection]!.length) {
            int maxWordLength = puzzleSections[currentMainSection]![currentSubSection]!
                .map((wordData) => wordData['word']!.length)
                .reduce((a, b) => a > b ? a : b);

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
          }
        }
      }
    });
  }
}