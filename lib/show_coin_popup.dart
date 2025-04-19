import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';
import 'package:audioplayers/audioplayers.dart';
import 'ad_manager.dart';

Future<void> showCoinPopup(BuildContext context) async {
  AudioPlayer _clickAudioPlayer = AudioPlayer();

  // Coin ve diğer verilerin kaydedilmesi
  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
    debugPrint("Veri kaydedildi (saveGameData).");
  }

  // Reklamı gösterme ve coin ekleme fonksiyonu
  void showRewardedAd() {
    if (AdManager.rewardedAd != null) {
      AdManager.rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // Kullanıcıya coin ekle
          int earnedCoins = 75; // Reklam başına kazanılan coin miktarı
          GlobalProperties.coin.value += earnedCoins;
          (context as Element).markNeedsBuild();
          // Durumu kaydet
          saveGameData();
        },
      );
      AdManager.rewardedAd = null;
      AdManager.loadRewardedAd();
    } else {
      debugPrint('Rewarded ad is not ready yet.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reklam henüz hazır değil, lütfen tekrar deneyin!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey[50]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Açıklama metni
                    Text(
                      'Reklam izleyerek coin kazanabilirsiniz.',
                      style: GlobalProperties.globalTextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Ödüllü reklam butonu
                    ElevatedButton(
                      onPressed: () async {
                        if (GlobalProperties.isSoundOn) {
                          await _clickAudioPlayer.stop();
                          await _clickAudioPlayer.play(
                            AssetSource('audios/click_audio.mp3'),
                          );
                        }
                        showRewardedAd();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                        elevation: 6,
                      ),
                      child: const Icon(
                        Icons.video_library,
                        color: Colors.yellow,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sağ üstte çarpı butonu
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      );
    },
  ).then((_) {
    _clickAudioPlayer.dispose();
  });
}

