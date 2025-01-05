import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_properties.dart';

class InAppPurchaseService {
  // in_app_purchase paketi için temel instance
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // Store’dan gelecek product listesi
  List<ProductDetails> products = [];

  // Satın alma güncellemelerini dinlemek için stream subscription
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Uygulamada tanımlı ürün kimlikleri
  static const String oneLifeProductId = 'one_life';
  static const String fiveLivesProductId = 'five_lives';
  static const String tenLivesProductId = 'ten_lives';

  // Satın alma güncellemelerini dinlemeye başla
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
        // Hata yönetimi
        debugPrint('Purchase Stream Error: $error');
      },
    );
  }

  // Store’dan ürün bilgilerini çek
  Future<void> loadProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('Store mevcut değil (Store is not available).');
      return;
    }

    // Sorgulanacak ürün kimlikleri
    const Set<String> ids = {
      oneLifeProductId,
      fiveLivesProductId,
      tenLivesProductId,
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

  // Ürünü satın alma işlemini başlat
  Future<void> purchaseProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    // Hak (can) gibi tüketilebilir ürünler için buyConsumable:
    await _inAppPurchase.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true, // Android için otomatik tüketim
    );
  }

  // Satın alma güncellemelerini dinle
  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Ödeme işlemi beklemede
          break;
        case PurchaseStatus.purchased:
          // Satın alma başarılı
          // -> Hak ekleme, veri kaydetme vb. işlemlerinizi yapın
          await _handleSuccessfulPurchase(purchase);

          // Satın almayı tamamlayın (özellikle iOS için önemli)
          _inAppPurchase.completePurchase(purchase);
          break;
        case PurchaseStatus.error:
          // Satın alma hatası
          debugPrint('Satın alma hatası: ${purchase.error}');
          break;
        case PurchaseStatus.restored:
          // Önceden satın alınmış ürünü geri yükleme
          _inAppPurchase.completePurchase(purchase);
          break;
        case PurchaseStatus.canceled:
          // Kullanıcı satın almayı iptal etti
          break;
      }
    }
  }

  // Başarılı satın alma sonrası hak ekleme
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == oneLifeProductId) {
      GlobalProperties.remainingLives.value += 1;
    } else if (purchase.productID == fiveLivesProductId) {
      GlobalProperties.remainingLives.value += 5;
    } else if (purchase.productID == tenLivesProductId) {
      GlobalProperties.remainingLives.value += 10;
    }

    // Satın alma sonrası veriyi kaydet
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remainingLives', GlobalProperties.remainingLives.value);

    debugPrint('Satın alma başarılı! Mevcut hak: ${GlobalProperties.remainingLives.value}');
  }

  // Abonelik iptali vb. durumlarda stream dinlemeyi bırakın
  void dispose() {
    _subscription.cancel();
  }
}
