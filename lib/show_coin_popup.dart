import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';
import 'in_app_purchase_service.dart';
import 'package:audioplayers/audioplayers.dart';

Future<void> showCoinPopup(BuildContext context) async {
  RewardedAd? _rewardedAd;
  AudioPlayer? _clickAudioPlayer = AudioPlayer();

  // Reklamı yükleme fonksiyonu
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test reklam ID'si
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  // Coin vb. verilerin kaydedilmesi
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
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          // Kullanıcıya coin ekle
          int earnedCoins = 50; // Reklam başına kazanılan coin miktarı
          GlobalProperties.coin.value += earnedCoins;
          (context as Element).markNeedsBuild();
          // Durumu kaydet
          saveGameData();
        },
      );
      _rewardedAd = null;
      loadRewardedAd();
    } else {
      debugPrint('Rewarded ad is not ready yet.');
    }
  }

  // Popup açılmadan önce reklam yükleniyor
  loadRewardedAd();

  // In-app purchase service örneği
  final inAppPurchaseService = InAppPurchaseService();
  inAppPurchaseService.initialize();
  await inAppPurchaseService.loadProducts();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kampanya bannerı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ÖZEL KAMPANYA! %20 BONUS COİN',
                    style: GlobalProperties.globalTextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Coin Satın Al',
                  style: GlobalProperties.globalTextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sınırlı süreli özel kampanya! Bugün yapacağınız satın alımlarda ekstra bonus coin kazanma fırsatını kaçırmayın.',
                  style: GlobalProperties.globalTextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 12),
                Text(
                  'Reklam izleyerek coin kazanabilirsiniz.',
                  style: GlobalProperties.globalTextStyle(
                    color: Colors.black87,
                    fontSize: 16,
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
                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 12),
                // Satın alma kartları
                _buildPurchaseCard(
                  context,
                  '100 Coin - \$1.99',
                  Icons.monetization_on,
                  onTap: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer.stop();
                      await _clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    final product = inAppPurchaseService.products.firstWhere(
                      (element) =>
                          element.id == InAppPurchaseService.coin100ProductId,
                      orElse: () =>
                          throw Exception('Ürün bulunamadı, 100 coin'),
                    );
                    await inAppPurchaseService.purchaseProduct(product);
                  },
                ),
                const SizedBox(height: 12),
                _buildPurchaseCard(
                  context,
                  '500 Coin - \$7.99\n(Kampanya Bonus: +20%)',
                  Icons.monetization_on,
                  onTap: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer.stop();
                      await _clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    final product = inAppPurchaseService.products.firstWhere(
                      (element) =>
                          element.id == InAppPurchaseService.coin500ProductId,
                      orElse: () =>
                          throw Exception('Ürün bulunamadı, 500 coin'),
                    );
                    await inAppPurchaseService.purchaseProduct(product);
                  },
                ),
                const SizedBox(height: 12),
                _buildPurchaseCard(
                  context,
                  '1000 Coin - \$14.99\n(Kampanya Bonus: +20%)',
                  Icons.monetization_on,
                  onTap: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer.stop();
                      await _clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    final product = inAppPurchaseService.products.firstWhere(
                      (element) =>
                          element.id == InAppPurchaseService.coin1000ProductId,
                      orElse: () =>
                          throw Exception('Ürün bulunamadı, 1000 coin'),
                    );
                    await inAppPurchaseService.purchaseProduct(product);
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer.stop();
                      await _clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    textStyle: GlobalProperties.globalTextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(
                    'Kapat',
                    style: GlobalProperties.globalTextStyle(
                      color: Colors.indigo,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).then((_) {
    _clickAudioPlayer.dispose();
  });
}

/// Modern tasarıma sahip satın alma kartını gösteren widget
Widget _buildPurchaseCard(
  BuildContext context,
  String title,
  IconData icon, {
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: GlobalProperties.globalTextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        trailing: Icon(icon, color: Colors.amber),
      ),
    ),
  );
}
