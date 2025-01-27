import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'global_properties.dart';

class SpecialDayPopup extends StatelessWidget {
  final VoidCallback onClose;

  const SpecialDayPopup({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  "SÜRPRİZ!",
                  style: GlobalProperties.globalTextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200, // Animasyon boyutu
            width: 200,
            child: Lottie.asset('assets/animations/birthday_animation.json'),
          ),
          const SizedBox(height: 10),
          Text(
            "Bugün çok özel ve güzel birinin doğum gününe özel olarak herkese sonsuz can veriyoruz!\n\n\n"
            "Bu özel günü bizimle kutladığınız için teşekkür ederiz :)",
            textAlign: TextAlign.center,
            style: GlobalProperties.globalTextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}