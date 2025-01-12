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

class _MusicBackgroundState extends State<MusicBackground> {
  // YENİ: AudioPlayer nesnesi
  late AudioPlayer _audioPlayer;

  bool _isMusicOn = true;
  bool _hasPlayedBefore = false; 

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadMusicPreference();
  }

  Future<void> _loadMusicPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool savedMusicSetting = prefs.getBool('isMusicOn') ?? true;

    setState(() {
      _isMusicOn = savedMusicSetting;
    });

    // Eğer açılacaksa müziği başlat
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
    // Uygulama tamamen kapatıldığında müziği durdur
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // İçerideki asıl widget (MaterialApp) döndürülüyor
    return widget.child;
  }

  Future<void> setMusicOn(bool turnOn) async {
    setState(() {
      _isMusicOn = turnOn;
    });

    // SharedPreferences'e kaydet
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMusicOn', turnOn);

    if (turnOn) {
      // Eğer daha önce hiç çalmadıysa _playBackgroundMusic() çağır
      if (_hasPlayedBefore) {
        _audioPlayer.resume();
      } else {
        _playBackgroundMusic();
      }
    } else {
      _audioPlayer.pause();
    }
  }
}
