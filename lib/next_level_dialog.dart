import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

void showNextLevelDialog(
  BuildContext context,
  String mainSection,
  String subSection,
  VoidCallback onNextLevel,
  VoidCallback onGoHome,
  Function(int, VoidCallback) incrementScore, // Skor artırma fonksiyonu parametre olarak ekleniyor
  saveGameData
) {
  // Tamamlanan bölümü kaydet
  updateCompletionStatus(mainSection, subSection);

  showDialog(
    context: context,
    barrierDismissible: false, // Kullanıcı dışına tıklayarak kapatamaz
    builder: (BuildContext context) {
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
                  incrementScore(15000, () {
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
        backgroundColor: const Color(0xFFfef7ff), // Arka plan rengini ayarlayın
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    'Tebrikler!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bölümü başarıyla tamamladınız!',
                    textAlign: TextAlign.center,
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
                    // Lottie animasyon ekranını göster
                    await showGeneralDialog(
                      context: context,
                      barrierDismissible: false, // Kullanıcı animasyonu kapatamaz
                      barrierColor: Colors.transparent, // Hafif siyah arka plan
                      pageBuilder: (context, _, __) {
                        return Scaffold(
                          backgroundColor: Colors.transparent, // Arka plan rengini siyah yap
                          body: Stack(
                            children: [
                              Positioned.fill(
                                child: Center( // Animasyonu ekranın tam ortasına hizala
                                  child: Transform.scale(
                                    scale: 1, // Animasyonu büyütüp tam ortalamak için
                                    child: Transform.translate(
                                      offset: Offset(0, 0), // Animasyonun dikey ve yatay ofsetini ayarla
                                      child: Lottie.asset(
                                        'assets/animations/screen_transition_animation.json',
                                        width: MediaQuery.of(context).size.width, // Ekran genişliği
                                        height: MediaQuery.of(context).size.height, // Ekran yüksekliği
                                        fit: BoxFit.fill, // Ekranı tamamen kapla
                                        repeat: false, // Animasyonu bir kez oynat
                                        onLoaded: (composition) {
                                          Future.delayed(
                                            composition.duration, // Animasyon süresince bekle
                                            () {
                                              Navigator.of(context).pop(); // Animasyon bitince dialog kapat
                                              Navigator.of(context).pushAndRemoveUntil(
                                                MaterialPageRoute(builder: (context) => HomePage()), // HomePage'e yönlendir
                                                (route) => false, // Önceki tüm sayfaları kaldır
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
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
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