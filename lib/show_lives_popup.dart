import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:in_app_purchase/in_app_purchase.dart';
import 'global_properties.dart';
import 'in_app_purchase_service.dart';

Future<void> showLivesPopup(BuildContext context) async {
  RewardedAd? _rewardedAd;

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
          GlobalProperties.remainingLives.value += 1; // Hak ekle
          (context as Element).markNeedsBuild();       // Arayüzü yenile
          saveGameData();                             // Veriyi kaydet
        },
      );

      _rewardedAd = null;
      loadRewardedAd(); // Bir sonraki reklam için tekrar yükle
    } else {
      debugPrint('Rewarded ad is not ready yet.');
    }
  }

  // Popup açıldığında reklamı yükle
  loadRewardedAd();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        // Modern görünüm için arka plan ve kenar yuvarlama
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Kalan Hak Satın Al',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlığın hemen altında bir ince ayracı (divider)
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: 12),

            // Reklam butonunun üzerinde yönlendirici bir metin
            Text(
              'Reklam izleyerek can kazanabilirsiniz.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),

            // Reklam izleme butonu (Merkezde dairesel buton)
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
            // İkinci bir divider
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: 8),

            // Satın alma seçeneklerini dikey olarak sıralıyoruz
            // Her seçenek kendi çerçevesi içinde, aralarında mesafe
            _buildPurchaseCard(
              context,
              '1 Hak - \$0.99',
              Icons.favorite,
              onTap: () async {
                final product = inAppPurchaseService.products.firstWhere(
                  (element) => element.id == InAppPurchaseService.oneLifeProductId,
                  orElse: () => throw Exception('Ürün bulunamadı'),
                );
                await inAppPurchaseService.purchaseProduct(product);
              },
            ),
            const SizedBox(height: 12),
            _buildPurchaseCard(
              context,
              '5 Hak - \$4.49',
              Icons.favorite,
              onTap: () async {
                final product = inAppPurchaseService.products.firstWhere(
                  (element) => element.id == InAppPurchaseService.fiveLivesProductId,
                  orElse: () => throw Exception('Ürün bulunamadı'),
                );
                await inAppPurchaseService.purchaseProduct(product);
              },
            ),
            const SizedBox(height: 12),
            _buildPurchaseCard(
              context,
              '10 Hak - \$7.99',
              Icons.favorite,
              onTap: () async {
                final product = inAppPurchaseService.products.firstWhere(
                  (element) => element.id == InAppPurchaseService.tenLivesProductId,
                  orElse: () => throw Exception('Ürün bulunamadı'),
                );
                await inAppPurchaseService.purchaseProduct(product);
              },
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              inAppPurchaseService.dispose();
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

/// Satın alma seçeneğini tek başına bir çerçeve içinde gösteren widget
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
      trailing: Icon(icon, color: Colors.redAccent),
      onTap: onTap,
    ),
  );
}
