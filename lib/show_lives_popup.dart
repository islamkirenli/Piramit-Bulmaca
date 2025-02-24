import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';
import 'in_app_purchase_service.dart';
import 'package:audioplayers/audioplayers.dart';

Future<void> showLivesPopup(BuildContext context) async {
  RewardedAd? _rewardedAd;
  AudioPlayer? _clickAudioPlayer = AudioPlayer();

  // InAppPurchaseService örneği (Ürünleri ve satın alma işlemini yönetmek için)
  final inAppPurchaseService = InAppPurchaseService();
  inAppPurchaseService.initialize();
  await inAppPurchaseService.loadProducts();

  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
    await prefs.setInt('deadlineTimestamp', GlobalProperties.deadlineTimestamp);
    debugPrint("Veri kaydedildi (saveGameData).");
  }

  // Reklamı yükleme fonksiyonu
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ID
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

  // Reklamı gösterme ve hak ekleme fonksiyonu
  void showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          GlobalProperties.remainingLives.value += 1; // Ekstra hak ekle
          (context as Element).markNeedsBuild();       // Arayüzü güncelle
          saveGameData();                              // Veriyi kaydet
        },
      );
      _rewardedAd = null;
      loadRewardedAd(); // Sonraki reklam için tekrar yükle
    } else {
      debugPrint('Rewarded ad is not ready yet.');
    }
  }

  // Popup açılmadan önce reklamı yükle
  loadRewardedAd();

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
                    'ÖZEL KAMPANYA! %20 BONUS HAK',
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
                  'Kalan Hak Satın Al',
                  style: GlobalProperties.globalTextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sınırlı süreli kampanya ile bugün ekstra haklar kazanın!',
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
                  'Reklam izleyerek can kazanabilirsiniz.',
                  style: GlobalProperties.globalTextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Reklam izleme butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                const SizedBox(height: 12),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 12),
                // Popüler Satın Alınan Bölümü (Reklam bölümünden hemen sonra)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Popüler Satın Alınan',
                    style: GlobalProperties.globalTextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPurchaseCard(
                  context,
                  'Bundle: Coin + 5 Hak + 3 İpucu - \$9.99',
                  Icons.shopping_bag,
                  onTap: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer.stop();
                      await _clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    final product = inAppPurchaseService.products.firstWhere(
                      (element) => element.id == InAppPurchaseService.bundleProductId,
                      orElse: () => throw Exception('Ürün bulunamadı, Bundle'),
                    );
                    await inAppPurchaseService.purchaseProduct(product);
                  },
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 12),
                // Can satın alma seçenekleri
                _buildPurchaseCard(
                  context,
                  '1 Hak - \$0.99',
                  Icons.favorite,
                  onTap: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer.stop();
                      await _clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    final product = inAppPurchaseService.products.firstWhere(
                      (element) => element.id == InAppPurchaseService.oneLifeProductId,
                      orElse: () => throw Exception('Ürün bulunamadı, 1 hak'),
                    );
                    await inAppPurchaseService.purchaseProduct(product);
                  },
                ),
                const SizedBox(height: 12),
                _buildPurchaseCard(
                  context,
                  '5 Hak - \$4.49\n(Kampanya Bonus: +20%)',
                  Icons.favorite,
                  onTap: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer.stop();
                      await _clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    final product = inAppPurchaseService.products.firstWhere(
                      (element) => element.id == InAppPurchaseService.fiveLivesProductId,
                      orElse: () => throw Exception('Ürün bulunamadı, 5 hak'),
                    );
                    await inAppPurchaseService.purchaseProduct(product);
                  },
                ),
                const SizedBox(height: 12),
                _buildPurchaseCard(
                  context,
                  '10 Hak - \$7.99\n(Kampanya Bonus: +20%)',
                  Icons.favorite,
                  onTap: () async {
                    if (GlobalProperties.isSoundOn) {
                      await _clickAudioPlayer.stop();
                      await _clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    final product = inAppPurchaseService.products.firstWhere(
                      (element) => element.id == InAppPurchaseService.tenLivesProductId,
                      orElse: () => throw Exception('Ürün bulunamadı, 10 hak'),
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
                    inAppPurchaseService.dispose();
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

/// Modern ve çekici tasarıma sahip satın alma kartını gösteren widget
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
        trailing: Icon(icon, color: Colors.redAccent),
      ),
    ),
  );
}
