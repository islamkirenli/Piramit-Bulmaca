import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';

Future<void> showLivesPopup(BuildContext context) async {
  RewardedAd? _rewardedAd;

  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
    print("kaydedildi.");
  }

  // Reklamı yükleme fonksiyonu
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // AdMob rewarded ad birimi kimliği
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  // Reklamı gösterme ve hak ekleme fonksiyonu
  void showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          GlobalProperties.remainingLives.value += 1; // Hak ekle
          (context as Element).markNeedsBuild(); // AppBarStats'ı yenile
          saveGameData(); // Veriyi kaydet
        },
      );

      _rewardedAd = null;
      loadRewardedAd(); // Reklamı yeniden yükle
    } else {
      print('Rewarded ad is not ready yet.');
    }
  }

  // Popup açıldığında reklamı yükle
  loadRewardedAd();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Kalan Hak Satın Al'),
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.blue),
              onPressed: () {
                showRewardedAd(); // Reklamı göster
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Kalan haklar satın almak için seçenekler:'),
            SizedBox(height: 10),
            ListTile(
              title: Text('1 Hak - \$0.99'),
              trailing: Icon(Icons.favorite),
            ),
            ListTile(
              title: Text('5 Hak - \$4.49'),
              trailing: Icon(Icons.favorite),
            ),
            ListTile(
              title: Text('10 Hak - \$7.99'),
              trailing: Icon(Icons.favorite),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Kapat'),
          ),
        ],
      );
    },
  );
}
