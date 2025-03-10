import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pyramid_puzzle/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';

class LevelCompleteDialog extends StatefulWidget {
  final String sourcePage; // Hangi ekrandan çağrıldığını belirten parametre

  const LevelCompleteDialog({Key? key, required this.sourcePage}) : super(key: key);

  @override
  _LevelCompleteDialogState createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool isAnimationStarted = false; // Kullanıcı dokunana kadar animasyon tamamen başlamayacak
  late AnimationController _textAnimationController;
  late Animation<double> _textOpacity;
  bool isTextVisible = true;
  bool isCloseButtonVisible = false;
  late AnimationController _coinFlipController;
  late AnimationController _heartBeatController;
  bool showRewardAnimations = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Tam animasyon süresi
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          isCloseButtonVisible = true; // Animasyon bitince çarpı butonunu göster
          showRewardAnimations = true;

          if (widget.sourcePage == 'daily_puzzle_game') {
            GlobalProperties.remainingLives.value += 2;  
            GlobalProperties.coin.value += 80;           
            GlobalProperties.wordHintCount.value += 1;     
            GlobalProperties.singleHintCount.value += 1;     
          } else {
            GlobalProperties.remainingLives.value += 2;
            GlobalProperties.coin.value += 150;
            GlobalProperties.wordHintCount.value += 2;   
            GlobalProperties.singleHintCount.value += 2;
          }
          saveGameData();
        });
        _slideController.forward();
      }
    });

    _playSlowLoop();

    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // 500ms içinde kayarak gelecek
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut, // Daha yumuşak geçiş efekti
      ),
    );

    _coinFlipController = AnimationController(vsync: this, duration: Duration(seconds: 1))..repeat();
    _heartBeatController = AnimationController(vsync: this, duration: Duration(seconds: 1))..repeat();

    // Yeni eklenen yanıp sönme animasyonu için kontrolcü
    _textAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // 1 saniyede bir yanıp sönecek
    )..repeat(reverse: true); // Sürekli tersine çevirerek tekrarla
    
    _textOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(_textAnimationController);
  }

  void _playSlowLoop() {
    double loopEnd = 0.5 / 2.0; 
    _animationController.duration = Duration(milliseconds: (1 * 1000).toInt()); 
    _animationController.repeat(min: 0.0, max: loopEnd, period: Duration(milliseconds: (1 * 1000).toInt()));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textAnimationController.dispose(); // Yeni eklenen animasyonu da temizle
    _coinFlipController.dispose();
    _heartBeatController.dispose();
    _slideController.dispose();    
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  // Sandık animasyonunun sabit yüksekliği (300)
  double chestHeight = 300.0;
  // Sandık animasyonunun ekranın dikey merkezindeki üst konumu
  double chestTop = (MediaQuery.of(context).size.height - chestHeight) / 2;
  // Ödül animasyonlarını sandığın 60 piksel üstüne yerleştirmek için hesaplanan top değeri
  double rewardTop = chestTop - 90;

  return Scaffold(
    backgroundColor: Colors.black.withOpacity(0.7),
    body: GestureDetector(
      onTap: () {
        if (!isAnimationStarted) {
          setState(() {
            isAnimationStarted = true;
            isTextVisible = false;
          });
          _animationController.duration = Duration(seconds: 2);
          _animationController.forward(from: 0);
        }
      },
      child: Stack(
        children: [
          // Ödül animasyonlarının Positioned widget'ı:
          if (showRewardAnimations)
            Positioned(
              top: rewardTop,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // İlk satır: Coin ve Can ödülleri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                      children: [
                        // Coin ödülü
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/coin_flip_animation.json',
                              width: 50,
                              height: 50,
                              controller: _coinFlipController,
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.sourcePage == 'daily_puzzle_game' ? "+80" : "+150",
                              style: GlobalProperties.globalTextStyle(
                                color: Colors.yellow,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 20),
                        // Can ödülü
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/heart_beat_animation.json',
                              width: 50,
                              height: 50,
                              controller: _heartBeatController,
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.sourcePage == 'daily_puzzle_game' ? "+2" : "+2",
                              style: GlobalProperties.globalTextStyle(
                                color: Colors.red,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    // İkinci satır: Kelime ipucu ve Tek ipucu ödülleri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
                      children: [
                        // Kelime ipucu ödülü
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_fix_high,
                              color: Colors.white,
                              size: 50,
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.sourcePage == 'daily_puzzle_game' ? "+1" : "+2",
                              style: GlobalProperties.globalTextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 30),
                        // Tek ipucu ödülü
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Colors.white,
                              size: 50,
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.sourcePage == 'daily_puzzle_game' ? "+1" : "+2",
                              style: GlobalProperties.globalTextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // Diğer widget'lar (chest spotlight, chest animasyonu, kapatma butonu vs.) aynı kalıyor.
          Center(
            child: Lottie.asset(
              'assets/animations/chest_spotlight_animation.json',
              width: 500,
              height: 500,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          Center(
            child: Lottie.asset(
              'assets/animations/chest_animation.json',
              width: chestHeight, // 300 olarak ayarlandı
              height: chestHeight,
              fit: BoxFit.contain,
              controller: _animationController,
            ),
          ),
          // Sağ üstteki kapatma butonu ve diğer widget'lar...
          if (isCloseButtonVisible)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  if (widget.sourcePage == 'daily_puzzle_game') {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomePage()),
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          if (isTextVisible)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Text(
                  "Açmak için sandığa tıklayın",
                  textAlign: TextAlign.center,
                  style: GlobalProperties.globalTextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}


  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
    await prefs.setInt('wordHintCount', GlobalProperties.wordHintCount.value);
    await prefs.setInt('singleHintCount', GlobalProperties.singleHintCount.value);
  }
}

// Bu fonksiyon, popup'ı çağırmak için kullanılacak
void showLevelCompleteDialog(BuildContext context, {required String sourcePage}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    pageBuilder: (context, _, __) => LevelCompleteDialog(sourcePage: sourcePage),
  );
}