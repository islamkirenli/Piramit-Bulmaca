import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';

Future<void> showCoinPopup(BuildContext context) async {
  RewardedAd? _rewardedAd;

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

  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
    print("kaydedildi.");
  }

  // Reklamı gösterme ve coin ekleme fonksiyonu
  void showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // Kullanıcıya coin ekle
          int earnedCoins = 50; // Reklam başına kazanılan coin miktarı
          GlobalProperties.coin.value += earnedCoins; // Coin ekleme
          (context as Element).markNeedsBuild(); // AppBarStats'ı yenile

          // Durumu kaydet
          saveGameData();
        },
      );

      // Reklam temizliği ve yeniden yükleme
      _rewardedAd = null;
      loadRewardedAd();
    } else {
      print('Rewarded ad is not ready yet.');
    }
  }

  // Reklamı yükleyin
  loadRewardedAd();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Coin Satın Al'),
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.blue),
              onPressed: () {
                showRewardedAd(); // Reklamı göster ve coin kazandır
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Coin satın almak için seçenekler:'),
            SizedBox(height: 10),
            ListTile(
              title: Text('100 Coin - \$1.99'),
              trailing: Icon(Icons.monetization_on),
            ),
            ListTile(
              title: Text('500 Coin - \$7.99'),
              trailing: Icon(Icons.monetization_on),
            ),
            ListTile(
              title: Text('1000 Coin - \$14.99'),
              trailing: Icon(Icons.monetization_on),
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
