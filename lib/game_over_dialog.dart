import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Lottie paketini dahil edin
import 'main.dart';
import 'global_properties.dart';
import 'package:audioplayers/audioplayers.dart';

void showGameOverDialog(BuildContext context, VoidCallback onRestart, VoidCallback onGainLife, VoidCallback onGoHome) {
  AudioPlayer? clickAudioPlayer = AudioPlayer();

  showDialog(
    context: context,
    barrierDismissible: false, // Pop-up dışına tıklanınca kapanmasın
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animasyonu
            Lottie.asset(
              'assets/animations/game_over_animation.json', // Animasyon dosyasının yolu
              height: 150, // Yükseklik
              repeat: true, // Animasyonun tekrarlanması
            ),
            SizedBox(height: 10),
            Text(
              'Oyun Bitti!',
              style: GlobalProperties.globalTextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Tüm haklarınızı kaybettiniz.',
          style: GlobalProperties.globalTextStyle(),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (GlobalProperties.isSoundOn) {
                    await clickAudioPlayer.stop();
                    await clickAudioPlayer.play(
                      AssetSource('audios/click_audio.mp3'),
                    );
                  }
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
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                ),
                child: Icon(
                  Icons.home, // Ana sayfa ikonu
                  color: Colors.white,
                  size: 30,
                ),
              ),
              ElevatedButton(
                onPressed: () async{
                  if (GlobalProperties.isSoundOn) {
                    await clickAudioPlayer.stop();
                    await clickAudioPlayer.play(
                      AssetSource('audios/click_audio.mp3'),
                    );
                  }
                  Navigator.of(context).pop(); // Pop-up'ı kapat
                  onGainLife(); // Kullanıcıya bir hak daha ver
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                ),
                child: Icon(
                  Icons.video_library, // Video film ikonu
                  color: Colors.yellow,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}