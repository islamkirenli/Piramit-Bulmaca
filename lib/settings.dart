import 'package:flutter/material.dart';
import 'package:pyramid_puzzle/background_music.dart';
import 'package:pyramid_puzzle/global_properties.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'in_app_purchase_service.dart';

class SettingsDialog extends StatefulWidget {
  final String sourcePage; // Hangi sayfadan çağrıldığını belirten parametre

  SettingsDialog({required this.sourcePage});

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool isSoundOn = true; // Ses durumu
  bool isMusicOn = true; // Müzik durumu
  bool isVibrationOn = true; // Titreşim durumu

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Ayarları yükle
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isSoundOn = prefs.getBool('isSoundOn') ?? true;
      isMusicOn = prefs.getBool('isMusicOn') ?? true;
      isVibrationOn = prefs.getBool('isVibrationOn') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isSoundOn', isSoundOn);
    prefs.setBool('isMusicOn', isMusicOn);
    prefs.setBool('isVibrationOn', isVibrationOn);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding:
          EdgeInsets.zero, // İçerik ile kenarlar arasındaki boşlukları sıfırla
      content: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Text(
                    'Ayarlar',
                    style: GlobalProperties.globalTextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Divider(thickness: 1, height: 1), // Başlık altına bir çizgi ekler
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: widget.sourcePage == 'puzzle_game'
                    ? _buildPuzzleGameSettings(context)
                    : _buildMainSettings(context),
              ),
              SizedBox(height: 16),
            ],
          ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: Icon(Icons.close), // Çarpı ikonu
              onPressed: () {
                Navigator.of(context).pop(); // Pop-up'ı kapat
              },
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(10.0), // Pop-up kenarlarını yuvarlatır
      ),
    );
  }

  // Puzzle Game'den çağrıldığında gösterilecek ayarlar
  Widget _buildPuzzleGameSettings(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildButtonWithLabel(
          context: context,
          icon: Icons.home,
          label: 'Menü',
          color: Colors.blue,
          onPressed: () async {
            // Lottie animasyon ekranını göster
            await showGeneralDialog(
              context: context,
              barrierDismissible: false, // Kullanıcı animasyonu kapatamaz
              barrierColor: Colors.transparent, // Hafif siyah arka plan
              pageBuilder: (context, _, __) {
                return Scaffold(
                  backgroundColor:
                      Colors.transparent, // Arka plan rengini siyah yap
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: Center(
                          // Animasyonu ekranın tam ortasına hizala
                          child: Transform.scale(
                            scale: 1, // Animasyonu büyütüp tam ortalamak için
                            child: Transform.translate(
                              offset: Offset(0,
                                  0), // Animasyonun dikey ve yatay ofsetini ayarla
                              child: Lottie.asset(
                                'assets/animations/screen_transition_animation.json',
                                width: MediaQuery.of(context)
                                    .size
                                    .width, // Ekran genişliği
                                height: MediaQuery.of(context)
                                    .size
                                    .height, // Ekran yüksekliği
                                fit: BoxFit.fill, // Ekranı tamamen kapla
                                repeat: false, // Animasyonu bir kez oynat
                                onLoaded: (composition) {
                                  Future.delayed(
                                    composition
                                        .duration, // Animasyon süresince bekle
                                    () {
                                      Navigator.of(context)
                                          .pop(); // Animasyon bitince dialog kapat
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                HomePage()), // HomePage'e yönlendir
                                        (route) =>
                                            false, // Önceki tüm sayfaları kaldır
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        _buildButtonWithLabel(
          context: context,
          icon: isSoundOn ? Icons.volume_up : Icons.volume_off,
          label: 'Ses',
          color: isSoundOn ? Colors.green : Colors.grey,
          onPressed: () {
            setState(() {
              isSoundOn = !isSoundOn; // Durumu değiştir
            });
            _saveSettings(); // Değişikliği kaydet
          },
        ),
        _buildButtonWithLabel(
          context: context,
          icon: isMusicOn ? Icons.music_note : Icons.music_off,
          label: 'Müzik',
          color: isMusicOn ? Colors.orange : Colors.grey,
          onPressed: () {
            setState(() {
              isMusicOn = !isMusicOn; // Durumu değiştir
            });
            _saveSettings(); // Değişikliği kaydet
            MusicBackground.of(context)?.setMusicOn(isMusicOn);
          },
        ),
      ],
    );
  }

  // Main Page'den çağrıldığında gösterilecek ayarlar
  Widget _buildMainSettings(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildButtonWithLabel(
              context: context,
              icon: isMusicOn ? Icons.music_note : Icons.music_off,
              label: 'Müzik',
              color: isMusicOn ? Colors.orange : Colors.grey,
              onPressed: () {
                setState(() {
                  isMusicOn = !isMusicOn; // Durumu değiştir
                });
                _saveSettings(); // Değişikliği kaydet
                MusicBackground.of(context)?.setMusicOn(isMusicOn);
              },
            ),
            _buildButtonWithLabel(
              context: context,
              icon: isSoundOn ? Icons.volume_up : Icons.volume_off,
              label: 'Ses',
              color: isSoundOn ? Colors.green : Colors.grey,
              onPressed: () {
                setState(() {
                  isSoundOn = !isSoundOn; // Durumu değiştir
                });
                _saveSettings(); // Değişikliği kaydet
              },
            ),
            _buildButtonWithLabel(
              context: context,
              icon: isVibrationOn ? Icons.vibration : Icons.smartphone,
              label: 'Titreşim',
              color: isVibrationOn ? Colors.blue : Colors.grey,
              onPressed: () {
                setState(() {
                  isVibrationOn = !isVibrationOn; // Durumu değiştir
                });
                _saveSettings(); // Değişikliği kaydet
              },
            ),
          ],
        ),
        SizedBox(height: 16), // Üstteki butonlar ile separator arasında boşluk
        Divider(
          thickness: 1, // Çizginin kalınlığı
          color: Colors.grey, // Çizginin rengi
          height: 1, // Çizgi yüksekliği
        ),
        SizedBox(height: 16), // Separator ile yardım butonu arasına boşluk
        ElevatedButton.icon(
          onPressed: () {
            // Yardım butonuna basıldığında yapılacak işlemler
          },
          icon: Icon(Icons.mail, color: Colors.white), // Mail ikonu
          label: Text(
            'Yardım',
            style: GlobalProperties.globalTextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Buton rengi
            minimumSize: Size(double.infinity, 48), // Uzun ve geniş buton
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Yuvarlak köşe
            ),
          ),
        ),
        SizedBox(
            height: 16), // Yardım butonu ile takip et butonu arasına boşluk
        ElevatedButton.icon(
          onPressed: () {
            // Takip et butonuna basıldığında yapılacak işlemler
          },
          icon: Icon(Icons.star, color: Colors.white), // Takip ikonu
          label: Text(
            'Puanla',
            style: GlobalProperties.globalTextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green, // Buton rengi
            minimumSize: Size(double.infinity, 48), // Uzun ve geniş buton
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Yuvarlak köşe
            ),
          ),
        ),
        // EKLENEN KISIMLAR BAŞLANGICI
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ),
        const SizedBox(height: 8),

        // Üst tarafa kısa bir açıklama metni
        Text(
          'Reklamları Kaldır',
          textAlign: TextAlign.center,
          style: GlobalProperties.globalTextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Sadece görselin kendisini buton olarak kullanan GestureDetector
        GestureDetector(
          onTap: () async {
            // 1) InAppPurchaseService örneğinizi oluşturun veya elde edin
            final iapService = InAppPurchaseService();
            iapService.initialize();
            // Eğer uygulamanızda bu service daha önce initialize edildiyse,
            // tekrar initialize etmeye gerek olmayabilir.

            // 2) Ürünleri yükle (remove_ads ürününü de sorgular)
            await iapService.loadProducts();

            // 3) remove_ads product'ını bul
            final candidates =
                iapService.products.where((p) => p.id == 'remove_ads');
            final removeAdsProduct =
                candidates.isNotEmpty ? candidates.first : null;

            if (removeAdsProduct != null) {
              // Ürünü satın alma işlemini başlat
              await iapService.purchaseProduct(removeAdsProduct);
            } else {
              debugPrint("remove_ads ürünü bulunamadı veya yüklenemedi.");
            }
          },
          child: Image.asset(
            'assets/images/ads_block.png',
            width: 80,
            height: 80,
          ),
        ),
        // EKLENEN KISIMLAR SONU
      ],
    );
  }

  Widget _buildButtonWithLabel({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(), // Daire şeklinde buton
            padding: EdgeInsets.all(16), // İçerik için boşluk
            backgroundColor: color, // Butonun arka plan rengi
          ),
          child: Icon(icon, size: 28, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GlobalProperties.globalTextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
