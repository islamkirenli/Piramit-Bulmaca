import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';

Future<void> showCoinPopup(BuildContext context) async {
  RewardedAd? _rewardedAd;

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
          GlobalProperties.coin.value += earnedCoins; // Coin ekleme
          (context as Element).markNeedsBuild(); // Güncelleme

          // Durumu kaydet
          saveGameData();
        },
      );

      // Reklam temizliği ve yeniden yükleme
      _rewardedAd = null;
      loadRewardedAd();
    } else {
      debugPrint('Rewarded ad is not ready yet.');
    }
  }

  // Popup açılmadan önce reklam yükleniyor
  loadRewardedAd();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        // Modern görünüm: beyaz arkaplan, yuvarlak kenar
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Coin Satın Al',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlığın hemen altında ince bir ayrım çizgisi
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: 12),

            // Yönlendirici metin
            Text(
              'Reklam izleyerek coin kazanabilirsiniz.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),

            // Ortada bir dairesel buton (reklam izleme)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: showRewardedAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    elevation: 4,
                  ),
                  child: const Icon(
                    Icons.video_library,
                    color: Colors.yellow,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reklam butonu ve satın alma seçenekleri arasında ayrım
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: 8),

            // Satın alma seçenekleri (her biri ayrı çerçevede gölgeyle gösteriliyor)
            _buildPurchaseCard(
              context,
              '100 Coin - \$1.99',
              Icons.monetization_on,
              onTap: () {
                // TODO: Burada in-app purchase veya benzer satın alma işlemini başlatın
                debugPrint('100 Coin satın alma tıklandı.');
              },
            ),
            const SizedBox(height: 12),
            _buildPurchaseCard(
              context,
              '500 Coin - \$7.99',
              Icons.monetization_on,
              onTap: () {
                // TODO: Burada in-app purchase veya benzer satın alma işlemini başlatın
                debugPrint('500 Coin satın alma tıklandı.');
              },
            ),
            const SizedBox(height: 12),
            _buildPurchaseCard(
              context,
              '1000 Coin - \$14.99',
              Icons.monetization_on,
              onTap: () {
                // TODO: Burada in-app purchase veya benzer satın alma işlemini başlatın
                debugPrint('1000 Coin satın alma tıklandı.');
              },
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.indigo, // Metin rengi
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Kapat'),
          ),
        ],
      );
    },
  );
}

/// Her satın alma satırını ayrı bir çerçevede gösteren widget
Widget _buildPurchaseCard(
  BuildContext context,
  String title,
  IconData icon, {
  required VoidCallback onTap,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.25),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.black87,
            ),
      ),
      trailing: Icon(icon, color: Colors.amber),
      onTap: onTap,
    ),
  );
}
