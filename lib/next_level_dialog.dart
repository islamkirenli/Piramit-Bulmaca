import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:math'; // Rastgele seçim için
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
//import 'in_app_purchase_service.dart';
import 'global_properties.dart';
import 'package:audioplayers/audioplayers.dart';
import 'info_messages.dart'; // Dictionary'nin bulunduğu dosya

void showNextLevelDialog(
  BuildContext context,
  String mainSection,
  String subSection,
  VoidCallback onNextLevel,
  VoidCallback onGoHome,
  Function(int, VoidCallback) incrementScore, // Skor artırma fonksiyonu
  saveGameData
) {
  AudioPlayer? clickAudioPlayer = AudioPlayer();

  // Tamamlanan bölümü kaydet
  updateCompletionStatus(mainSection, subSection);

  /*bool showRemoveAds = true;
  if (mainSection == "Ana Bölüm 1") {
    int subSecNumber = int.tryParse(subSection) ?? 0;
    if (subSecNumber <= 10) {
      showRemoveAds = false;
    }
  }*/

  showDialog(
    context: context,
    barrierDismissible: false, // Kullanıcı dışına tıklayarak kapatamaz
    builder: (BuildContext context) {
      final random = Random();
      final infoMessage = infoMessages[random.nextInt(infoMessages.length)];

      Future.delayed(const Duration(seconds: 1), () {
        final overlay = Overlay.of(context);
        // overlayEntry'yi önce tanımlayın
        late OverlayEntry overlayEntry;

        overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            top: 80,
            left: -18,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Lottie.asset(
                'assets/animations/coin_up_animation.json', // Animasyon dosyası
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  // Coin artırmayı animasyon süresi ile senkronize et
                  incrementScore(50, () {
                    saveGameData(); // Skor artışı tamamlandığında veriyi kaydet
                  });
                  Future.delayed(composition.duration, () {
                    overlayEntry.remove(); // Animasyon bittiğinde kaldır
                  });
                },
              ),
            ),
          ),
        );

        // overlay'i ekledikten sonra çağırın
        overlay.insert(overlayEntry);
      });

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFfef7ff),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En üstte Lottie animasyonu
            Lottie.asset(
              'assets/animations/next_level_animation.json',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    'Tebrikler!',
                    style: GlobalProperties.globalTextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bölümü başarıyla tamamladınız!',
                    style: GlobalProperties.globalTextStyle(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Bilgi Köşesi: ',
                      style: GlobalProperties.globalTextStyle(
                        fontWeight: FontWeight.bold, // Sadece "Bilgi:" kalın
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: infoMessage,
                          style: GlobalProperties.globalTextStyle(
                            fontWeight: FontWeight.normal, // Geri kalan normal font
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    if (GlobalProperties.isSoundOn) {
                      // İlk önce tıklama sesini çal
                      await clickAudioPlayer.stop();
                      await clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                      // Kısa bir gecikme verelim
                      await Future.delayed(Duration(milliseconds: 200));
                      // Ardından geçiş sesini çal
                      await clickAudioPlayer.play(
                        AssetSource('audios/transition_sound.mp3'),
                      );
                    }
                    // Lottie animasyon ekranını göster
                    await showGeneralDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.transparent,
                      pageBuilder: (context, _, __) {
                        return Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Stack(
                            children: [
                              Positioned.fill(
                                child: Center(
                                  child: Transform.scale(
                                    scale: 1,
                                    child: Transform.translate(
                                      offset: Offset(0, 0),
                                      child: Lottie.asset(
                                        'assets/animations/screen_transition_animation.json',
                                        width: MediaQuery.of(context).size.width,
                                        height: MediaQuery.of(context).size.height,
                                        fit: BoxFit.fill,
                                        repeat: false,
                                        onLoaded: (composition) {
                                          Future.delayed(
                                            composition.duration,
                                            () {
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pushAndRemoveUntil(
                                                MaterialPageRoute(builder: (context) => HomePage()),
                                                (route) => false,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                  ),
                  child: Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (GlobalProperties.isSoundOn) {
                      await clickAudioPlayer.stop();
                      await clickAudioPlayer.play(
                        AssetSource('audios/click_audio.mp3'),
                      );
                    }
                    Navigator.of(context).pop();
                    onNextLevel();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(
                    Icons.fast_forward,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
            /*if (showRemoveAds) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reklamları Kaldır',
                textAlign: TextAlign.center,
                style: GlobalProperties.globalTextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  if (GlobalProperties.isSoundOn) {
                    await clickAudioPlayer.stop();
                    await clickAudioPlayer.play(
                      AssetSource('audios/click_audio.mp3'),
                    );
                  }
                  final iapService = InAppPurchaseService();
                  iapService.initialize();
                  await iapService.loadProducts();
                  final candidates = iapService.products.where((p) => p.id == 'remove_ads');
                  final removeAdsProduct = candidates.isNotEmpty ? candidates.first : null;

                  if (removeAdsProduct != null) {
                    await iapService.purchaseProduct(removeAdsProduct);
                  } else {
                    debugPrint("remove_ads ürünü bulunamadı veya yüklenemedi.");
                  }
                },
                child: Image.asset(
                  'assets/images/ads_block.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ],*/
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

Future<void> updateCompletionStatus(String mainSection, String subSection) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> completedSections = prefs.getStringList('completedSections') ?? [];
  String completedKey = "$mainSection-$subSection";

  if (!completedSections.contains(completedKey)) {
    completedSections.add(completedKey);
    await prefs.setStringList('completedSections', completedSections);
  }
}

