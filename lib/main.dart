import 'package:flutter/material.dart';
import 'puzzle_game.dart'; // Oyun sayfası dosyasını dahil edin
import 'settings.dart';
import 'sections.dart';
import 'app_bar_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bulmaca Oyunu',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(), // Giriş ekranı
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int score = 0; // Varsayılan değer
  int remainingLives = 5; // Varsayılan değer

  @override
  void initState() {
    super.initState();
    loadGameData();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Arka plan görseli
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/piramit_background.jpg'),
              fit: BoxFit.cover, // Görsel tüm alanı kaplar
            ),
          ),
        ),
        // İçerik
        Scaffold(
          backgroundColor: Colors.transparent, // Scaffold arka planı şeffaf yapılır
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: AppBarStats(
              score: score,
              remainingLives: remainingLives,
              onTimerEnd: () {
                setState(() {
                  remainingLives = 5; // Hakları sıfırla
                  saveGameData();
                });
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Oyun ekranına geçiş
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PuzzleGame()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(40),
                    shape: CircleBorder(),
                    backgroundColor: Colors.blueAccent,
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.4),
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Bölüm-1",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 60.0),
                  child: FloatingActionButton(
                    heroTag: 'settingsButton',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => SettingsDialog(sourcePage: 'main'),
                      );
                    },
                    backgroundColor: Colors.blueAccent,
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                    ),
                    shape: CircleBorder(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: FloatingActionButton(
                    heroTag: 'sectionsButton',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SectionsPage()),
                      );
                    },
                    backgroundColor: Colors.blueAccent,
                    child: Icon(
                      Icons.format_list_bulleted,
                      color: Colors.white,
                    ),
                    shape: CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> loadGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      score = prefs.getInt('score') ?? 0;
      remainingLives = prefs.getInt('remainingLives') ?? 5;
    });
  }

  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', score); // Skoru kaydeder
    await prefs.setInt('remainingLives', remainingLives); // Kalan hakları kaydeder
  }
}