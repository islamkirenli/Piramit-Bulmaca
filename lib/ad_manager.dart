import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdManager {
  static RewardedAd? rewardedAd;
  static BannerAd? bannerAd;
  static InterstitialAd? interstitialAd;
  static bool isInterstitialAdReady = false;

  /// Banner reklamı yükler. Daha önce varsa eski reklamı dispose eder.
  static void loadBannerAd() {
    bannerAd?.dispose();
    bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint("Banner ad yüklendi.");
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint("Banner ad yüklenemedi: $error");
          ad.dispose();
        },
      ),
    );
    bannerAd!.load();
  }

  /// Banner reklamını widget olarak döndürür.
  static Widget getBannerAdWidget() {
    if (bannerAd != null) {
      return Container(
        width: bannerAd!.size.width.toDouble(),
        height: bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: bannerAd!),
      );
    } else {
      return const SizedBox();
    }
  }

  /// Interstitial reklamı yükler.
  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitialAd = ad;
          isInterstitialAdReady = true;
          debugPrint("Interstitial ad yüklendi.");
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint("Interstitial ad yüklenemedi: $error");
          isInterstitialAdReady = false;
        },
      ),
    );
  }

  /// Yüklü interstitial reklamı gösterir.
  static void showInterstitialAd() {
    if (isInterstitialAdReady && interstitialAd != null) {
      interstitialAd!.show();
      isInterstitialAdReady = false;
      // Bir sonraki gösterim için yeniden yükleyelim.
      loadInterstitialAd();
    } else {
      debugPrint("Interstitial ad henüz hazır değil.");
    }
  }

  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId, // Yukarıdaki getter kullanılıyor
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          rewardedAd = ad;
          debugPrint("Rewarded ad yüklendi.");
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded ad yüklenemedi: $error');
          rewardedAd = null;
        },
      ),
    );
  }

  // Platforma göre banner reklam birimi ID'si
  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/2708723730'; // Android ad ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/3606501307'; // iOS ad ID 
      //return 'ca-app-pub-3940256099942544/2934735716'; // iOS test ad ID 
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }

  // Platforma göre interstitial reklam birimi ID'si
  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/2708723730'; // Android ad ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/4071870318'; // iOS ad ID 
      //return 'ca-app-pub-3940256099942544/4411468910'; // iOS test ad ID 
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }

  // Platforma göre farklı reklam birimi ID'si döndürür
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/7482904195'; // Android ad ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/6978473320'; // iOS ad ID
      //return 'ca-app-pub-3940256099942544/1712485313'; // iOS test ad ID 
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }
}