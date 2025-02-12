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
                    // Önce tıklama sesini çal
                    await clickAudioPlayer.stop();
                    await clickAudioPlayer.play(AssetSource('audios/click_audio.mp3'));
                    // Tıklama sesinin bitmesi için kısa bir gecikme verelim (örn. 200ms)
                    await Future.delayed(Duration(milliseconds: 200));
                    // Ardından geçiş sesini çal
                    await clickAudioPlayer.play(AssetSource('audios/transition_sound.mp3'));
                  }
                  // Ardından ekran geçiş animasyonunu gösteren dialog açılıyor
                  await showGeneralDialog(
                    context: context,
                    barrierDismissible: false, // Kullanıcı animasyonu kapatamaz
                    barrierColor: Colors.transparent, // Hafif siyah arka plan
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