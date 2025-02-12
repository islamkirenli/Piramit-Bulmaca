/*import 'package:flutter/material.dart';
import 'package:pyramid_puzzle/background_music.dart';
import 'package:pyramid_puzzle/global_properties.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'in_app_purchase_service.dart';
import 'package:audioplayers/audioplayers.dart';

class SettingsDialog extends StatefulWidget {
  final String sourcePage; // Hangi sayfadan çağrıldığını belirten parametre

  SettingsDialog({required this.sourcePage});

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  AudioPlayer? _clickAudioPlayer;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Ayarları yükle
    _clickAudioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _clickAudioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      GlobalProperties.isSoundOn = prefs.getBool('isSoundOn') ?? true;
      GlobalProperties.isMusicOn = prefs.getBool('isMusicOn') ?? true;
      GlobalProperties.isVibrationOn = prefs.getBool('isVibrationOn') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isSoundOn', GlobalProperties.isSoundOn);
    prefs.setBool('isMusicOn', GlobalProperties.isMusicOn);
    prefs.setBool('isVibrationOn', GlobalProperties.isVibrationOn);
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
              onPressed: () async{
                if (GlobalProperties.isSoundOn) {
                  await _clickAudioPlayer?.stop();
                  await _clickAudioPlayer?.play(
                    AssetSource('audios/click_audio.mp3'),
                  );
                }
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
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
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
          icon: GlobalProperties.isSoundOn ? Icons.volume_up : Icons.volume_off,
          label: 'Ses',
          color: GlobalProperties.isSoundOn ? Colors.green : Colors.grey,
          onPressed: () async{
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
            setState(() {
              GlobalProperties.isSoundOn = !GlobalProperties.isSoundOn; // Durumu değiştir
            });
            _saveSettings(); // Değişikliği kaydet
          },
        ),
        _buildButtonWithLabel(
          context: context,
          icon: GlobalProperties.isMusicOn ? Icons.music_note : Icons.music_off,
          label: 'Müzik',
          color: GlobalProperties.isMusicOn ? Colors.orange : Colors.grey,
          onPressed: () async{
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
            setState(() {
              GlobalProperties.isMusicOn = !GlobalProperties.isMusicOn; // Durumu değiştir
            });
            _saveSettings(); // Değişikliği kaydet
            MusicBackground.of(context)?.setMusicOn(GlobalProperties.isMusicOn);
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
              icon: GlobalProperties.isMusicOn ? Icons.music_note : Icons.music_off,
              label: 'Müzik',
              color: GlobalProperties.isMusicOn ? Colors.orange : Colors.grey,
              onPressed: () async{
                if (GlobalProperties.isSoundOn) {
                  await _clickAudioPlayer?.stop();
                  await _clickAudioPlayer?.play(
                    AssetSource('audios/click_audio.mp3'),
                  );
                }
                setState(() {
                  GlobalProperties.isMusicOn = !GlobalProperties.isMusicOn; // Durumu değiştir
                });
                _saveSettings(); // Değişikliği kaydet
                MusicBackground.of(context)?.setMusicOn(GlobalProperties.isMusicOn);
              },
            ),
            _buildButtonWithLabel(
              context: context,
              icon: GlobalProperties.isSoundOn ? Icons.volume_up : Icons.volume_off,
              label: 'Ses',
              color: GlobalProperties.isSoundOn ? Colors.green : Colors.grey,
              onPressed: () async{
                if (GlobalProperties.isSoundOn) {
                  await _clickAudioPlayer?.stop();
                  await _clickAudioPlayer?.play(
                    AssetSource('audios/click_audio.mp3'),
                  );
                }
                setState(() {
                  GlobalProperties.isSoundOn = !GlobalProperties.isSoundOn; // Durumu değiştir
                });
                _saveSettings(); // Değişikliği kaydet
              },
            ),
            _buildButtonWithLabel(
              context: context,
              icon: GlobalProperties.isVibrationOn ? Icons.vibration : Icons.smartphone,
              label: 'Titreşim',
              color: GlobalProperties.isVibrationOn ? Colors.blue : Colors.grey,
              onPressed: () async{
                if (GlobalProperties.isSoundOn) {
                  await _clickAudioPlayer?.stop();
                  await _clickAudioPlayer?.play(
                    AssetSource('audios/click_audio.mp3'),
                  );
                }
                setState(() {
                  GlobalProperties.isVibrationOn = !GlobalProperties.isVibrationOn; // Durumu değiştir
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
          onPressed: () async{
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
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
          onPressed: () async{
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
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
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
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
}*/

import 'package:flutter/material.dart';
import 'package:pyramid_puzzle/background_music.dart';
import 'package:pyramid_puzzle/global_properties.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'in_app_purchase_service.dart';
import 'package:audioplayers/audioplayers.dart';

class SettingsDialog extends StatefulWidget {
  final String sourcePage; // Hangi sayfadan çağrıldığını belirten parametre

  SettingsDialog({required this.sourcePage});

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  AudioPlayer? _clickAudioPlayer;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Ayarları yükle
    _clickAudioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _clickAudioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      GlobalProperties.isSoundOn = prefs.getBool('isSoundOn') ?? true;
      GlobalProperties.isMusicOn = prefs.getBool('isMusicOn') ?? true;
      GlobalProperties.isVibrationOn = prefs.getBool('isVibrationOn') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isSoundOn', GlobalProperties.isSoundOn);
    prefs.setBool('isMusicOn', GlobalProperties.isMusicOn);
    prefs.setBool('isVibrationOn', GlobalProperties.isVibrationOn);
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
              onPressed: () async{
                if (GlobalProperties.isSoundOn) {
                  await _clickAudioPlayer?.stop();
                  await _clickAudioPlayer?.play(
                    AssetSource('audios/click_audio.mp3'),
                  );
                }
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
            if (GlobalProperties.isSoundOn) {
              // Önce tıklama sesini çal
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
              // Kısa bir gecikme (örn. 200 ms) ver
              await Future.delayed(Duration(milliseconds: 200));
              // Ardından geçiş sesini çal
              await _clickAudioPlayer?.play(
                AssetSource('audios/transition_sound.mp3'),
              );
            }
            // Lottie animasyon ekranını göster
            await showGeneralDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.transparent,
              pageBuilder: (context, _, __) {
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: Transform.scale(
                            scale: 1,
                            child: Transform.translate(
                              offset: Offset(0, 0),
                              child: Lottie.asset(
                                'assets/animations/screen_transition_animation.json',
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                fit: BoxFit.fill,
                                repeat: false,
                                onLoaded: (composition) {
                                  Future.delayed(
                                    composition.duration,
                                    () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (context) => HomePage()),
                                        (route) => false,
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
          icon: GlobalProperties.isSoundOn ? Icons.volume_up : Icons.volume_off,
          label: 'Ses',
          color: GlobalProperties.isSoundOn ? Colors.green : Colors.grey,
          onPressed: () async{
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
            setState(() {
              GlobalProperties.isSoundOn = !GlobalProperties.isSoundOn; // Durumu değiştir
            });
            _saveSettings(); // Değişikliği kaydet
          },
        ),
        _buildButtonWithLabel(
          context: context,
          icon: GlobalProperties.isMusicOn ? Icons.music_note : Icons.music_off,
          label: 'Müzik',
          color: GlobalProperties.isMusicOn ? Colors.orange : Colors.grey,
          onPressed: () async{
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
            setState(() {
              GlobalProperties.isMusicOn = !GlobalProperties.isMusicOn; // Durumu değiştir
            });
            _saveSettings(); // Değişikliği kaydet
            MusicBackground.of(context)?.setMusicOn(GlobalProperties.isMusicOn);
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
              icon: GlobalProperties.isMusicOn ? Icons.music_note : Icons.music_off,
              label: 'Müzik',
              color: GlobalProperties.isMusicOn ? Colors.orange : Colors.grey,
              onPressed: () async{
                if (GlobalProperties.isSoundOn) {
                  await _clickAudioPlayer?.stop();
                  await _clickAudioPlayer?.play(
                    AssetSource('audios/click_audio.mp3'),
                  );
                }
                setState(() {
                  GlobalProperties.isMusicOn = !GlobalProperties.isMusicOn; // Durumu değiştir
                });
                _saveSettings(); // Değişikliği kaydet
                MusicBackground.of(context)?.setMusicOn(GlobalProperties.isMusicOn);
              },
            ),
            _buildButtonWithLabel(
              context: context,
              icon: GlobalProperties.isSoundOn ? Icons.volume_up : Icons.volume_off,
              label: 'Ses',
              color: GlobalProperties.isSoundOn ? Colors.green : Colors.grey,
              onPressed: () async{
                if (GlobalProperties.isSoundOn) {
                  await _clickAudioPlayer?.stop();
                  await _clickAudioPlayer?.play(
                    AssetSource('audios/click_audio.mp3'),
                  );
                }
                setState(() {
                  GlobalProperties.isSoundOn = !GlobalProperties.isSoundOn; // Durumu değiştir
                });
                _saveSettings(); // Değişikliği kaydet
              },
            ),
            _buildButtonWithLabel(
              context: context,
              icon: GlobalProperties.isVibrationOn ? Icons.vibration : Icons.smartphone,
              label: 'Titreşim',
              color: GlobalProperties.isVibrationOn ? Colors.blue : Colors.grey,
              onPressed: () async{
                if (GlobalProperties.isSoundOn) {
                  await _clickAudioPlayer?.stop();
                  await _clickAudioPlayer?.play(
                    AssetSource('audios/click_audio.mp3'),
                  );
                }
                setState(() {
                  GlobalProperties.isVibrationOn = !GlobalProperties.isVibrationOn; // Durumu değiştir
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
          onPressed: () async{
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
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
          onPressed: () async{
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
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
            if (GlobalProperties.isSoundOn) {
              await _clickAudioPlayer?.stop();
              await _clickAudioPlayer?.play(
                AssetSource('audios/click_audio.mp3'),
              );
            }
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