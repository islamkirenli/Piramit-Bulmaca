import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main.dart';
import 'global_properties.dart';
import 'package:audioplayers/audioplayers.dart';

void showAllSectionsCompletedDialog(BuildContext context) {
  AudioPlayer? clickAudioPlayer = AudioPlayer();

  showDialog(
    context: context,
    barrierDismissible: false, // Pop-up dışında dokunarak kapatılamaz
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text(
              'Tebrikler!',
              style: GlobalProperties.globalTextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Muhteşem! Tüm bölümleri başarıyla tamamladınız. Sanki piramitlerin sırlarını çözmek için doğmuşsunuz gibi! \n\nŞimdi bir nefes alın, belki bir kahve molası verin ve bu inanılmaz hayatın tadını çıkarın. Dünya sizin, keyfine bakın!',
          style: GlobalProperties.globalTextStyle(),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                if (GlobalProperties.isSoundOn) {
                  // Tıklama sesini çal
                  await clickAudioPlayer.stop();
                  await clickAudioPlayer.play(AssetSource('audios/click_audio.mp3'));
                  // Kısa gecikme sonrası geçiş sesini de çalabilirsiniz
                  await Future.delayed(Duration(milliseconds: 200));
                  await clickAudioPlayer.play(AssetSource('audios/transition_sound.mp3'));
                }
                // Geçiş animasyonunu gösteren general dialog
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
                                          Navigator.of(context).pop(); // geçiş animasyonunu kapat
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
          ),
        ],
      );
    },
  );
}
