import 'package:flutter/material.dart';
import 'puzzle_game.dart'; // Oyun sayfası dosyasını dahil edin
import 'settings.dart';
import 'sections.dart';
import 'app_bar_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';

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
  bool isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    loadGameData().then((_) {
      setState(() {
        isDataLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isDataLoaded) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              onTimerEnd: () {
                setState(() {
                  GlobalProperties.remainingLives.value = 3; // Hakları sıfırla
                  GlobalProperties.countdownSeconds.value = 15;
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
                ValueListenableBuilder<int>(
                  valueListenable: GlobalProperties.remainingLives,
                  builder: (context, remainingLives, _) {
                    return ElevatedButton(
                      onPressed: remainingLives > 0
                          ? () {
                              // Oyun ekranına geçiş
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PuzzleGame()),
                              );
                            }
                          : null, // Eğer hak yoksa buton devre dışı
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(40),
                        shape: CircleBorder(),
                        backgroundColor: remainingLives > 0
                            ? Colors.blueAccent
                            : Colors.grey, // Aktif değilse gri
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.4),
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 60,
                      ),
                    );
                  },
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

  Future<void> saveGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score', GlobalProperties.score.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);
    await prefs.setInt('countdownSeconds', GlobalProperties.countdownSeconds.value);
    await prefs.setBool('isTimerRunning', GlobalProperties.isTimerRunning.value);
  }

  Future<void> loadGameData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    GlobalProperties.score.value = prefs.getInt('score') ?? 0;
    GlobalProperties.remainingLives.value = prefs.getInt('remainingLives') ?? 3;
    GlobalProperties.countdownSeconds.value = prefs.getInt('countdownSeconds') ?? 15;
    GlobalProperties.isTimerRunning.value = prefs.getBool('isTimerRunning') ?? false;
  }
}