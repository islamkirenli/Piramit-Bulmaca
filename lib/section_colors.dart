import 'package:flutter/material.dart';

/// Her bölüm için renk tanımları (pastel tonlarda)
final Map<int, Map<String, Color>> sectionColors = {
  0: {"inside": Color(0xFFB3E5FC), "border": Color(0xFF0288D1)}, // Pastel açık mavi ve koyu mavi
  1: {"inside": Color(0xFFFFCCBC), "border": Color(0xFFBF360C)}, // Pastel açık turuncu ve koyu turuncu
  2: {"inside": Color(0xFFC8E6C9), "border": Color(0xFF2E7D32)}, // Pastel açık yeşil ve koyu yeşil
  3: {"inside": Color(0xFFD1C4E9), "border": Color(0xFF512DA8)}, // Pastel lavanta ve koyu mor
  4: {"inside": Color(0xFFCFD8DC), "border": Color(0xFF455A64)}, // Pastel gri ve koyu gri
  5: {"inside": Color(0xFFF8BBD0), "border": Color(0xFFC2185B)}, // Pastel pembe ve koyu pembe
  6: {"inside": Color(0xFFBBDEFB), "border": Color(0xFF1976D2)}, // Pastel mavi ve koyu mavi
  7: {"inside": Color(0xFFFFE0B2), "border": Color(0xFFF57C00)}, // Pastel açık turuncu ve koyu turuncu
  8: {"inside": Color(0xFFC5CAE9), "border": Color(0xFF3F51B5)}, // Pastel açık mor ve koyu mor
  9: {"inside": Color.fromARGB(255, 232, 243, 112), "border": Color(0xFF827717)}, // Pastel sarı-yeşil ve koyu sarımsı yeşil
  10: {"inside": Color(0xFFFFCDD2), "border": Color(0xFFD32F2F)}, // Pastel pembe ve koyu kırmızı
  11: {"inside": Color(0xFFD7CCC8), "border": Color(0xFF5D4037)}, // Pastel kahverengi ve koyu kahverengi
  12: {"inside": Color(0xFFE1BEE7), "border": Color(0xFF7B1FA2)}, // Pastel mor ve koyu mor
  13: {"inside": Color(0xFFDCEDC8), "border": Color(0xFF388E3C)}, // Pastel açık yeşil ve koyu yeşil
  14: {"inside": Color.fromARGB(255, 241, 229, 119), "border": Color(0xFFFBC02D)}, // Pastel açık sarı ve koyu sarı
  15: {"inside": Color(0xFFB0BEC5), "border": Color(0xFF37474F)}, // Pastel gri mavi ve koyu gri mavi
  16: {"inside": Color(0xFF81D4FA), "border": Color(0xFF0288D1)}, // Pastel açık mavi ve koyu mavi
  17: {"inside": Color(0xFFFFAB91), "border": Color(0xFFBF360C)}, // Pastel turuncu ve koyu turuncu
  18: {"inside": Color(0xFFA5D6A7), "border": Color(0xFF2E7D32)}, // Pastel açık yeşil ve koyu yeşil
  19: {"inside": Color.fromARGB(255, 247, 232, 100), "border": Color(0xFFF9A825)}, // Pastel sarı ve koyu sarı
  20: {"inside": Color(0xFFCE93D8), "border": Color(0xFF512DA8)}, // Pastel mor ve koyu mor
  21: {"inside": Color(0xFFB0BEC5), "border": Color(0xFF455A64)}, // Pastel gri mavi ve koyu gri
  22: {"inside": Color(0xFFF48FB1), "border": Color(0xFFC2185B)}, // Pastel pembe ve koyu pembe
  23: {"inside": Color.fromARGB(255, 158, 233, 243), "border": Color(0xFF006064)}, // Pastel teal ve koyu teal
  24: {"inside": Color(0xFF64B5F6), "border": Color(0xFF1976D2)}, // Pastel mavi ve koyu mavi
  25: {"inside": Color(0xFFFFCC80), "border": Color(0xFFF57C00)}, // Pastel açık turuncu ve koyu turuncu
  26: {"inside": Color(0xFF9FA8DA), "border": Color(0xFF3F51B5)}, // Pastel lavanta ve koyu lavanta
  27: {"inside": Color(0xFFDCE775), "border": Color(0xFF827717)}, // Pastel açık yeşil-sarı ve koyu yeşil
  28: {"inside": Color(0xFFE57373), "border": Color(0xFFD32F2F)}, // Pastel kırmızı ve koyu kırmızı
  29: {"inside": Color(0xFFBCAAA4), "border": Color(0xFF5D4037)}, // Pastel kahverengi ve koyu kahverengi
  30: {"inside": Color(0xFFD1C4E9), "border": Color(0xFF7B1FA2)}, // Pastel mor ve koyu mor
  31: {"inside": Color(0xFFC5E1A5), "border": Color(0xFF388E3C)}, // Pastel açık yeşil ve koyu yeşil
  32: {"inside": Color.fromARGB(255, 240, 229, 106), "border": Color(0xFFFBC02D)}, // Pastel sarı ve koyu sarı
  33: {"inside": Color(0xFF90A4AE), "border": Color(0xFF37474F)}, // Pastel gri mavi ve koyu gri mavi
  34: {"inside": Color(0xFF4FC3F7), "border": Color(0xFF0288D1)}, // Pastel mavi ve koyu mavi
  35: {"inside": Color(0xFFFF8A65), "border": Color(0xFFBF360C)}, // Pastel turuncu ve koyu turuncu
  36: {"inside": Color(0xFF81C784), "border": Color(0xFF2E7D32)}, // Pastel açık yeşil ve koyu yeşil
  37: {"inside": Color.fromARGB(255, 255, 238, 86), "border": Color(0xFFF9A825)}, // Pastel sarı ve koyu sarı
  38: {"inside": Color(0xFF9575CD), "border": Color(0xFF512DA8)}, // Pastel mor ve koyu mor
  39: {"inside": Color(0xFFB0BEC5), "border": Color(0xFF455A64)}, // Pastel gri ve koyu gri
  40: {"inside": Color(0xFFF06292), "border": Color(0xFFC2185B)}, // Pastel pembe ve koyu pembe
  41: {"inside": Color(0xFF80DEEA), "border": Color(0xFF006064)}, // Pastel açık teal ve koyu teal
  42: {"inside": Color(0xFF2196F3), "border": Color(0xFF1565C0)}, // Orta mavi ve koyu mavi
  43: {"inside": Color(0xFFFFA726), "border": Color(0xFFF57C00)}, // Pastel turuncu ve koyu turuncu
  44: {"inside": Color(0xFF673AB7), "border": Color(0xFF512DA8)}, // Orta mor ve koyu mor
  45: {"inside": Color(0xFF8BC34A), "border": Color(0xFF33691E)}, // Pastel yeşil ve koyu yeşil
  46: {"inside": Color(0xFFFFEB3B), "border": Color(0xFFFBC02D)}, // Pastel sarı ve koyu sarı
  47: {"inside": Color(0xFF607D8B), "border": Color(0xFF455A64)}, // Gri mavi ve koyu gri
};
