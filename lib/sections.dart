import 'package:flutter/material.dart';
import 'puzzle_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_game.dart';
import 'global_properties.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:ui';

Future<Set<String>> getCompletedSections() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> completedSections = prefs.getStringList('completedSections') ?? [];
  return completedSections.toSet();
}

Future<void> markSectionAsCompleted(String sectionKey) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> completedSections = prefs.getStringList('completedSections') ?? [];
  if (!completedSections.contains(sectionKey)) {
    completedSections.add(sectionKey);
    await prefs.setStringList('completedSections', completedSections);
  }
}

String displaySectionName(String originalName) {
  final Map<String, String> sectionNames = {
    'Ana Bölüm 1': 'KEOPS PİRAMİDİ',
    'Ana Bölüm 2': 'KHAFRE PİRAMİDİ',
    'Ana Bölüm 3': 'MENKAURE PİRAMİDİ',
    'Ana Bölüm 4': 'DJOSER PİRAMİDİ',
    'Ana Bölüm 5': 'BENT PİRAMİT',
    'Ana Bölüm 6': 'MEİDUM PİRAMİDİ',
    'Ana Bölüm 7': 'MEİDUM PİRAMİDİ',
    'Ana Bölüm 8': 'GÜNEŞ PİRAMİDİ',
    'Ana Bölüm 9': 'TİKAL PİRAMİDİ',
    'Ana Bölüm 10': 'PALENQUE PİRAMİDİ',
    'Ana Bölüm 11': 'CALAKMUL PİRAMİDİ',
    'Ana Bölüm 12': 'EL CASTİLLO',
    'Ana Bölüm 13': 'CESTİUS PİRAMİDİ',

  };
  return sectionNames[originalName] ?? originalName;
}


class SectionsPage extends StatefulWidget {
  @override
  _SectionsPageState createState() => _SectionsPageState();
}

/// --- ANA BÖLÜMLER ---
class _SectionsPageState extends State<SectionsPage> {
  AudioPlayer? _clickAudioPlayer;

  final List<String> imageList = [
    'assets/images/button_images/keops_button.jpg',
    'assets/images/button_images/khafre_button.jpg',
    'assets/images/button_images/menkaure_button.jpg',
    'assets/images/button_images/djoser_button.jpg',
    'assets/images/button_images/bent_button.jpg',
    'assets/images/button_images/meidum_button.jpg',
    'assets/images/button_images/meroe_button.jpg',
    'assets/images/button_images/gunes_button.jpg',
    'assets/images/button_images/tikal_button.jpg',
    'assets/images/button_images/palenque_button.jpg',
    'assets/images/button_images/calakmul_button.jpg',
    'assets/images/button_images/elcastillo_button.jpg',
    'assets/images/button_images/cestius_button.jpg',

  ];

  @override
  void initState() {
    super.initState();
    _clickAudioPlayer = AudioPlayer(); // AudioPlayer örneği oluştur
  }

  @override
  void dispose() {
    _clickAudioPlayer?.dispose(); // AudioPlayer'ı serbest bırak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "BÖLÜMLER",
          style: GlobalProperties.globalTextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/piramit_background.jpg',
              fit: BoxFit.cover,
            ),
          ), 
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5, // Yatay blur miktarı
                sigmaY: 5, // Dikey blur miktarı
              ),
              // Renk katmanı (opaklığı 0 bırakırsanız sadece blur uygulanır)
              child: Container(color: Colors.black.withOpacity(0)),
            ),
          ),
          SafeArea(
            child: FutureBuilder<Set<String>>(
              future: getCompletedSections(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                Set<String> completedSections = snapshot.data ?? {};
                List<String> allSections = puzzleSections.keys.toList();

                return ListView.builder(
                  itemCount: allSections.length,
                  itemBuilder: (context, index) {
                    String sectionName = allSections[index];

                    bool isUnlocked = (index == 0) ||
                        completedSections.contains("MAIN:${allSections[index - 1]}") ||
                        completedSections.contains("${allSections[index - 1]}-20");
                    
                    String imagePath = imageList[index % imageList.length];

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () async {
                              if (GlobalProperties.isSoundOn) {
                                await _clickAudioPlayer?.stop();
                                await _clickAudioPlayer?.play(
                                  AssetSource('audios/click_audio.mp3'),
                                );
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubSectionsPage(
                                    sectionName: sectionName,
                                    subSections: puzzleSections[sectionName]!,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Stack(
                        children: [
                          // Görsel arka plan
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all( // Kenar çizgisi ekleme
                                color: Colors.white, // Çizgi rengi
                                width: 2.0, // Çizgi kalınlığı
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3), // Gölge rengi
                                  offset: Offset(4, 4), // Gölgenin x ve y eksenindeki uzaklığı
                                  blurRadius: 8, // Gölgenin bulanıklık derecesi
                                  spreadRadius: 1, // Gölgenin yayılma derecesi
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: Image.asset(
                                    imagePath,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Metin veya saydam katman
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            height: 80,
                            decoration: BoxDecoration(
                              color: isUnlocked ? Colors.transparent : Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              displaySectionName(sectionName),
                              style: GlobalProperties.globalTextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// --- ALT BÖLÜMLER ---
class SubSectionsPage extends StatefulWidget {
  final String sectionName;
  final Map<String, List<Map<String, String>>> subSections;

  SubSectionsPage({
    required this.sectionName,
    required this.subSections,
  });

  @override
  _SubSectionsPageState createState() => _SubSectionsPageState();
}

class _SubSectionsPageState extends State<SubSectionsPage> {
  late Future<Set<String>> _completedSectionsFuture;
  AudioPlayer? _clickAudioPlayer;

  @override
  void initState() {
    super.initState();
    _completedSectionsFuture = getCompletedSections();
    _clickAudioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _clickAudioPlayer?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          displaySectionName(widget.sectionName),
          style: GlobalProperties.globalTextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Arka planı tüm ekrana yerleştiriyoruz
          Positioned.fill(
            child: Image.asset(
              'assets/images/piramit_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5, // Yatay blur miktarı
                sigmaY: 5, // Dikey blur miktarı
              ),
              // Renk katmanı (opaklığı 0 bırakırsanız sadece blur uygulanır)
              child: Container(color: Colors.black.withOpacity(0)),
            ),
          ), 
          // İçeriği SafeArea ile sarıyoruz
          SafeArea(
            child: FutureBuilder<Set<String>>(
              future: _completedSectionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                Set<String> completedSections = snapshot.data ?? {};
                List<String> allSubSections = widget.subSections.keys.toList();

                return ValueListenableBuilder<int>(
                  valueListenable: GlobalProperties.remainingLives,
                  builder: (context, remainingLives, _) {
                    return GridView.builder(
                      padding: EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: allSubSections.length,
                      itemBuilder: (context, index) {
                        String subSectionKey = allSubSections[index];
                        String fullKey = "${widget.sectionName}-$subSectionKey";

                        bool isUnlocked = (index < 3) ||
                            completedSections.contains(
                              "${widget.sectionName}-${allSubSections[index - 1]}",
                            );
                        bool isCompleted = completedSections.contains(fullKey);

                        return GestureDetector(
                          onTap: isUnlocked && remainingLives > 0
                              ? () async {
                                  if (GlobalProperties.isSoundOn) {
                                    await _clickAudioPlayer?.stop();
                                    await _clickAudioPlayer?.play(
                                      AssetSource('audios/click_audio.mp3'),
                                    );
                                  }
                                  // Oyun sayfasına git
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PuzzleGame(
                                        initialMainSection: widget.sectionName,
                                        initialSubSection: subSectionKey,
                                        isCompleted: isCompleted,
                                      ),
                                    ),
                                  );

                                  // Geri dönünce bu alt bölümü completedSections'a ekle
                                  await markSectionAsCompleted(fullKey);

                                  // SharedPreferences'ı yeniden oku ve sayfayı güncelle
                                  setState(() {
                                    _completedSectionsFuture = getCompletedSections();
                                  });
                                }
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? (isCompleted ? Colors.green : Colors.blueAccent)
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: isUnlocked
                                  ? Text(
                                      subSectionKey,
                                      textAlign: TextAlign.center,
                                      style: GlobalProperties.globalTextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// --- Uygulama başlangıcı ---
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SectionsPage(),
  ));
}