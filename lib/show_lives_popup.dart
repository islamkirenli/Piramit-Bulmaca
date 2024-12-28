import 'package:flutter/material.dart';

Future<void> showLivesPopup(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Kalan Hak Satın Al'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Kalan haklar satın almak için seçenekler:'),
            SizedBox(height: 10),
            ListTile(
              title: Text('1 Hak - \$0.99'),
              trailing: Icon(Icons.favorite),
            ),
            ListTile(
              title: Text('5 Hak - \$4.49'),
              trailing: Icon(Icons.favorite),
            ),
            ListTile(
              title: Text('10 Hak - \$7.99'),
              trailing: Icon(Icons.favorite),
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
