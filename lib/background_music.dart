import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicBackground extends StatefulWidget {
  final Widget child;
  const MusicBackground({Key? key, required this.child}) : super(key: key);

  static _MusicBackgroundState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MusicBackgroundState>();
  }

  @override
  _MusicBackgroundState createState() => _MusicBackgroundState();
}

class _MusicBackgroundState extends State<MusicBackground> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  bool _isMusicOn = true;
  bool _hasPlayedBefore = false; 

  @override
  void initState() {
    super.initState();
    // Observer ekliyoruz:
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _loadMusicPreference();
  }

  Future<void> _loadMusicPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool savedMusicSetting = prefs.getBool('isMusicOn') ?? true;

    setState(() {
      _isMusicOn = savedMusicSetting;
    });

    // Eğer müzik açıksa başlatıyoruz:
    if (_isMusicOn) {
      _playBackgroundMusic();
    }
  }

  Future<void> _playBackgroundMusic() async {
    await _audioPlayer.play(AssetSource('audios/background_music.mp3'));
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _hasPlayedBefore = true;
  }

  @override
  void dispose() {
    // Observer'ı kaldırıyoruz:
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // İçerideki asıl widget döndürülüyor.
    return widget.child;
  }

  Future<void> setMusicOn(bool turnOn) async {
    setState(() {
      _isMusicOn = turnOn;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMusicOn', turnOn);

    if (turnOn) {
      if (_hasPlayedBefore) {
        _audioPlayer.resume();
      } else {
        _playBackgroundMusic();
      }
    } else {
      _audioPlayer.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana alındığında müziği durdur, geri geldiğinde devam ettiriyoruz.
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed && _isMusicOn) {
      _audioPlayer.resume();
    }
  }
}
