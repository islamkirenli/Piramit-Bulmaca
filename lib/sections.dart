import 'package:flutter/material.dart';
import 'puzzle_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_game.dart';
import 'global_properties.dart';

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

class SectionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bölümler"),
      ),
      body: FutureBuilder<Set<String>>(
        future: getCompletedSections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          Set<String> completedSections = snapshot.data ?? {};
          return ListView.builder(
            itemCount: puzzleSections.keys.length,
            itemBuilder: (context, index) {
              String sectionName = puzzleSections.keys.elementAt(index);
              bool isUnlocked = index == 0 || completedSections.contains(puzzleSections.keys.elementAt(index - 1));

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
                    child: Text(
                      sectionName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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


class SubSectionsPage extends StatelessWidget {
  final String sectionName;
  final Map<String, List<Map<String, String>>> subSections;

  SubSectionsPage({required this.sectionName, required this.subSections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sectionName),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<Set<String>>(
        future: getCompletedSections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          Set<String> completedSections = snapshot.data ?? {};
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
                itemCount: subSections.keys.length,
                itemBuilder: (context, index) {
                  String subSectionKey = subSections.keys.elementAt(index);
                  String sectionKey = "$sectionName-$subSectionKey";

                  bool isUnlocked = index == 0 ||
                      completedSections.contains("$sectionName-${subSections.keys.elementAt(index - 1)}");

                  bool isCompleted = completedSections.contains(sectionKey);

                  return GestureDetector(
                    onTap: isUnlocked && remainingLives > 0
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PuzzleGame(
                                  initialMainSection: sectionName,
                                  initialSubSection: subSectionKey,
                                ),
                              ),
                            ).then((_) {
                              markSectionAsCompleted(sectionKey);
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
                        child: Text(
                          "$subSectionKey",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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


void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SectionsPage(),
  ));
}

