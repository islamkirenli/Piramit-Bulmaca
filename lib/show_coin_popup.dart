import 'package:flutter/material.dart';

Future<void> showCoinPopup(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Coin Satın Al'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Coin satın almak için seçenekler:'),
            SizedBox(height: 10),
            ListTile(
              title: Text('100 Coin - \$1.99'),
              trailing: Icon(Icons.monetization_on),
            ),
            ListTile(
              title: Text('500 Coin - \$7.99'),
              trailing: Icon(Icons.monetization_on),
            ),
            ListTile(
              title: Text('1000 Coin - \$14.99'),
              trailing: Icon(Icons.monetization_on),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Kapat'),
          ),
        ],
      );
    },
  );
}
