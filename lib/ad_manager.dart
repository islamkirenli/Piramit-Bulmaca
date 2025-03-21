import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdManager {
  static RewardedAd? rewardedAd;
  static BannerAd? bannerAd;
  static InterstitialAd? interstitialAd;
  static bool isInterstitialAdReady = false;
  static bool isRewardedAdReady = false;
  static bool isBannerAdReady = false;

  static int _maxBannerLoadAttempts = 3;
  static int _currentBannerLoadAttempts = 0;

  /// Banner reklamı yükler
  static void loadBannerAd() {
    if (_currentBannerLoadAttempts >= _maxBannerLoadAttempts) {
      debugPrint("Maksimum banner yükleme denemesi aşıldı. Bir süre beklenecek.");
      Future.delayed(Duration(minutes: 1), () {
        _currentBannerLoadAttempts = 0;
        loadBannerAd();
      });
      return;
    }

    bannerAd?.dispose();
    bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint("Banner reklam yüklendi.");
          isBannerAdReady = true;
          _currentBannerLoadAttempts = 0;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint("Banner reklam yüklenemedi: $error");
          isBannerAdReady = false;
          ad.dispose();
          _currentBannerLoadAttempts++;
          if (_currentBannerLoadAttempts < _maxBannerLoadAttempts) {
            Future.delayed(Duration(seconds: 10), () {
              loadBannerAd();
            });
          }
        },
        onAdOpened: (Ad ad) {
          debugPrint('Banner reklam açıldı.');
        },
        onAdClosed: (Ad ad) {
          debugPrint("Banner reklam kapatıldı.");
          ad.dispose();
          loadBannerAd(); // Reklam kapatıldığında yeni reklam yükle
        },
      ),
    );
    bannerAd!.load();
  }

  /// Banner reklamını widget olarak döndürür
  static Widget getBannerAdWidget() {
    if (bannerAd != null && isBannerAdReady) {
      return Container(
        width: bannerAd!.size.width.toDouble(),
        height: bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: bannerAd!),
      );
    } else {
      return const SizedBox();
    }
  }

  /// Interstitial reklamı yükler
  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitialAd = ad;
          isInterstitialAdReady = true;
          debugPrint("Interstitial reklam yüklendi.");
          
          // Reklam kapatıldığında yapılacak işlemler
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              isInterstitialAdReady = false;
              ad.dispose();
              loadInterstitialAd(); // Yeni reklam yükle
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint("Interstitial reklam gösterilemedi: $error");
              isInterstitialAdReady = false;
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint("Interstitial reklam yüklenemedi: $error");
          isInterstitialAdReady = false;
          interstitialAd = null;
          // Belirli bir süre sonra tekrar dene
          Future.delayed(Duration(minutes: 1), () {
            loadInterstitialAd();
          });
        },
      ),
    );
  }

  /// Yüklü interstitial reklamı gösterir
  static void showInterstitialAd() {
    if (isInterstitialAdReady && interstitialAd != null) {
      interstitialAd!.show();
    } else {
      debugPrint("Interstitial reklam henüz hazır değil.");
      loadInterstitialAd();
    }
  }

  /// Rewarded reklamı yükler
  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          rewardedAd = ad;
          isRewardedAdReady = true;
          debugPrint("Rewarded reklam yüklendi.");
          
          // Reklam kapatıldığında yapılacak işlemler
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              isRewardedAdReady = false;
              ad.dispose();
              loadRewardedAd(); // Yeni reklam yükle
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint("Rewarded reklam gösterilemedi: $error");
              isRewardedAdReady = false;
              ad.dispose();
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded reklam yüklenemedi: $error');
          isRewardedAdReady = false;
          rewardedAd = null;
          // Belirli bir süre sonra tekrar dene
          Future.delayed(Duration(minutes: 1), () {
            loadRewardedAd();
          });
        },
      ),
    );
  }

  // Platform'a göre banner reklam ID'si
  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/2708723730';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/3606501307';
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }

  // Platform'a göre interstitial reklam ID'si
  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/2708723730';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/4071870318';
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }

  // Platform'a göre rewarded reklam ID'si
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/7482904195';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/6978473320';
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }
}