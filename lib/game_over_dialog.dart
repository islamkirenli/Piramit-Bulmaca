import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Lottie paketini dahil edin
import 'main.dart';

void showGameOverDialog(BuildContext context, VoidCallback onRestart, VoidCallback onGainLife, VoidCallback onGoHome) {
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Tüm haklarınızı kaybettiniz.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Pop-up'ı kapat
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => HomePage()), // HomePage'e yönlendir
                    (route) => false,
                  ); // Ana sayfaya yönlendir
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
                onPressed: () {
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

