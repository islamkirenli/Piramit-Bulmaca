import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Lottie paketini dahil edin
import 'global_properties.dart';

void showTimeCompletedDialog(BuildContext context, VoidCallback onContinue) {
  showDialog(
    context: context,
    barrierDismissible: false, // Kullanıcı pop-up dışına tıklayarak kapatamasın
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie animasyonu
            Lottie.asset(
              'assets/animations/time_completed_animation.json', // Animasyon dosyasının yolu
              height: 150, // Yükseklik
              repeat: true, // Animasyonun tekrarlanması
            ),
            SizedBox(height: 10), // Animasyon ile başlık arasında boşluk
            Text(
              'Yeni Haklarınız Yüklendi!',
              style: GlobalProperties.globalTextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Haklarınız yenilendi, tekrar oynamaya devam edebilirsiniz.',
          style: GlobalProperties.globalTextStyle(),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Pop-up'ı kapat
                onContinue(); // Devam etme işlemine yönlendirme
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.blueAccent,
              ),
              child: Text(
                'Devam Et',
                style: GlobalProperties.globalTextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    },
  );
}
