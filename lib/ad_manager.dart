import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdManager {
  static InterstitialAd? interstitialAd;
  static BannerAd? bannerAd;
  static RewardedAd? rewardedAd;

  static void loadBannerAd({required VoidCallback adLoaded}) async {
    bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          bannerAd = ad as BannerAd;
          adLoaded();
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }
  
  static void loadInterstitialAd() {
    InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('$ad loaded.');
            interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }
  
  static void showInterstitialAd(){
    if(interstitialAd != null){
      interstitialAd!.show();
      loadInterstitialAd();
    }
  }

  static void loadRewardedAd() {
    RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                loadRewardedAd(); // Yeni reklam yükle
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint("Rewarded reklam gösterilemedi: $error");
                ad.dispose();
                loadRewardedAd();
              },
            );
            debugPrint('$ad loaded.');
            rewardedAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('RewardedAd failed to load: $error');
          },
        ));
  }
  
  // Platform'a göre banner reklam ID'si
  static String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/2708723730';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/3606501307'; // ios ad id
      //return 'ca-app-pub-3915721961755607/3606501307'; // ios test ad id
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }

  // Platform'a göre interstitial reklam ID'si
  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/2708723730';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/4071870318'; // ios ad id
      //return 'ca-app-pub-3940256099942544/4411468910'; // ios test ad id
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }

  // Platform'a göre rewarded reklam ID'si
  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3915721961755607/7482904195';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3915721961755607/6978473320'; // ios ad id
      //return 'ca-app-pub-3940256099942544/1712485313'; // ios test ad id
    } else {
      throw UnsupportedError("Desteklenmeyen platform");
    }
  }
}