import 'package:flutter/material.dart';
import 'main.dart';

void showGameOverDialog(BuildContext context, VoidCallback onRestart, VoidCallback onGainLife, VoidCallback onGoHome) {
  showDialog(
    context: context,
    barrierDismissible: false, // Pop-up dışına tıklanınca kapanmasın
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Center(
          child: Text('Oyun Bitti!'),
        ),
        content: Text('Tüm haklarınızı kaybettiniz.'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Butonları yan yana hizalar
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Pop-up'ı kapat
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => HomePage()), // HomePage'e yönlendir
                    (route) => false, // Önceki tüm sayfaları kaldır
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
                  size: 30, // İkon boyutu
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
                  size: 30, // İkon boyutu
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
