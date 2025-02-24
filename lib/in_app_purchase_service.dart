import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Mağazadan gelecek ürün bilgileri
  List<ProductDetails> products = [];

  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Mevcut ürün kimlikleri (hak satın alma, reklam kaldırma vs.)
  static const String oneLifeProductId = 'one_life';
  static const String fiveLivesProductId = 'five_lives';
  static const String tenLivesProductId = 'ten_lives';

  // Reklamları kaldır
  static const String removeAdsProductId = 'remove_ads';

  // *** YENİ: Coin ürün kimlikleri ekleniyor ***
  static const String coin100ProductId = 'coin_100';
  static const String coin500ProductId = 'coin_500';
  static const String coin1000ProductId = 'coin_1000';

static const String bundleProductId = 'bundle_product_id';


  void initialize() {
    final purchaseUpdateStream = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdateStream.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        debugPrint('Purchase Stream Error: $error');
      },
    );
  }

  Future<void> loadProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('Store mevcut değil (Store is not available).');
      return;
    }

    // Ürün kimlikleri set’i (hak, reklam kaldırma, coin paketleri)
    const Set<String> ids = {
      oneLifeProductId,
      fiveLivesProductId,
      tenLivesProductId,
      removeAdsProductId,
      coin100ProductId,
      coin500ProductId,
      coin1000ProductId,
    };

    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(ids);

    if (response.error != null) {
      debugPrint('Ürün bilgisi sorgularken hata oluştu: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('Ürün bilgisi boş döndü.');
      return;
    }

    products = response.productDetails;
  }

  // Satın alma işlemini başlatma (consumable vs. non-consumable)
  Future<void> purchaseProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    if (product.id == removeAdsProductId) {
      // Reklam kaldırma ürünü (non-consumable)
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      // Diğer ürünleriniz (canlar ve coin paketleri) -> consumable
      await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
          await _handleSuccessfulPurchase(purchase);
          _inAppPurchase.completePurchase(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('Satın alma hatası: ${purchase.error}');
          break;
        case PurchaseStatus.restored:
          _inAppPurchase.completePurchase(purchase);
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  // Satın alma tamamlanınca yapılacaklar
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    // 1) Hak (can) satın alımı
    if (purchase.productID == oneLifeProductId) {
      GlobalProperties.remainingLives.value += 1;
    } else if (purchase.productID == fiveLivesProductId) {
      GlobalProperties.remainingLives.value += 5;
    } else if (purchase.productID == tenLivesProductId) {
      GlobalProperties.remainingLives.value += 10;
    } 
    // 2) Reklam kaldırma
    else if (purchase.productID == removeAdsProductId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('adsRemoved', true);
      debugPrint("Reklamlar kalıcı olarak kaldırıldı (adsRemoved=true).");
    }
    // 3) Coin satın alımı
    else if (purchase.productID == coin100ProductId) {
      GlobalProperties.coin.value += 100;
    } else if (purchase.productID == coin500ProductId) {
      GlobalProperties.coin.value += 500;
    } else if (purchase.productID == coin1000ProductId) {
      GlobalProperties.coin.value += 1000;
    }

    // Hak veya coin güncellediysek kaydedelim
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coin', GlobalProperties.coin.value);
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);

    debugPrint(
      'Satın alma başarılı! Coin: ${GlobalProperties.coin.value}, Hak: ${GlobalProperties.remainingLives.value}',
    );
  }

  void dispose() {
    _subscription.cancel();
  }
}
