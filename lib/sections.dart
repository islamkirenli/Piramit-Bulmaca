import 'package:flutter/material.dart';
import 'puzzle_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_game.dart';
import 'global_properties.dart';

/// --- Değiştirmeden kullanabilirsiniz ---
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

/// --- ANA BÖLÜMLER ---
class SectionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bölümler", style: GlobalProperties.globalTextStyle(),),
      ),
      body: FutureBuilder<Set<String>>(
        future: getCompletedSections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          Set<String> completedSections = snapshot.data ?? {};
          // puzzleSections.keys => Ana bölüm isimleri (ör. ["Bölüm 1", "Bölüm 2", ...])
          List<String> allSections = puzzleSections.keys.toList();

          return ListView.builder(
            itemCount: allSections.length,
            itemBuilder: (context, index) {
              String sectionName = allSections[index];

              bool isUnlocked = (index == 0) ||
                  completedSections.contains("MAIN:${allSections[index - 1]}") ||
                  completedSections.contains("${allSections[index - 1]}-20");

              return GestureDetector(
                onTap: isUnlocked
                    ? () {
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
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  height: 80,
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.blueAccent : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: isUnlocked
                        ? Text(
                            sectionName,
                            style: GlobalProperties.globalTextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
              );
            },
          );
        },
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

  @override
  void initState() {
    super.initState();
    _completedSectionsFuture = getCompletedSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionName, style: GlobalProperties.globalTextStyle(),),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<Set<String>>(
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

                  // Örnek: İlk 3 alt bölüm direkt açık, sonrakiler bir önceki tamamlandıysa açık.
                  bool isUnlocked = (index < 3) ||
                      completedSections.contains(
                        "${widget.sectionName}-${allSubSections[index - 1]}",
                      );

                  bool isCompleted = completedSections.contains(fullKey);

                  return GestureDetector(
                    onTap: isUnlocked && remainingLives > 0
                        ? () async {
                            // Oyun sayfasına git
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PuzzleGame(
                                  initialMainSection: widget.sectionName,
                                  initialSubSection: subSectionKey,
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