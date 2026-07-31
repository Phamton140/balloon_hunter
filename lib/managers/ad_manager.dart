// lib/managers/ad_manager.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager extends ChangeNotifier {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // MODO DE PRUEBA: Cambiar a false cuando vayas a compilar la versión de producción
  bool isTestMode = true;

  // -- BANNER AD --
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  // -- REWARDED AD --
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  // IDs Reales
  final String _realBannerAdUnitId = 'ca-app-pub-8257738486901222/2122434711';
  final String _realRewardedAdUnitId = 'ca-app-pub-8257738486901222/3782880605';

  // IDs de Prueba (Google)
  final String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  final String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (isTestMode) return _testBannerId;
    return Platform.isAndroid || Platform.isIOS ? _realBannerAdUnitId : '';
  }

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (isTestMode) return _testRewardedId;
    return Platform.isAndroid || Platform.isIOS ? _realRewardedAdUnitId : '';
  }

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdManager] Error initializing AdMob: $e');
    }
  }

  bool _isLoadingBanner = false;

  Future<void> loadBannerAd(BuildContext context) async {
    if (bannerAdUnitId.isEmpty || _isBannerAdLoaded || _isLoadingBanner) return;
    _isLoadingBanner = true;
    
    AdSize adSize = AdSize.banner;
    
    // Intentar obtener el tamaño adaptativo basado en el ancho de la pantalla
    try {
      final width = MediaQuery.of(context).size.width.truncate();
      if (width > 0) {
        final adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
          Orientation.portrait,
          width,
        );
        if (adaptiveSize != null) {
          adSize = adaptiveSize;
        }
      }
    } catch (_) {
      // Ignorar, se usa el AdSize.banner por defecto
    }

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdManager] Banner ad loaded successfully.');
          _isBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdManager] Banner ad failed to load: $error');
          ad.dispose();
          _isBannerAdLoaded = false;
          _isLoadingBanner = false;
          notifyListeners();
        },
      ),
    );
    await _bannerAd?.load();
  }

  void loadRewardedAd() {
    if (rewardedAdUnitId.isEmpty) return;
    
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdManager] Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdManager] Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          notifyListeners();
        },
      ),
    );
  }

  void showRewardedAd({required VoidCallback onRewardEarned}) {
    if (_rewardedAd == null) {
      debugPrint('[AdManager] Warning: attempt to show rewarded before loaded.');
      return;
    }
    
    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('[AdManager] Rewarded ad showed.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdManager] Rewarded ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        loadRewardedAd(); // Cargar otro para el futuro
        notifyListeners();
        
        if (rewardEarned) {
          onRewardEarned();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdManager] Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        loadRewardedAd();
        notifyListeners();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      debugPrint('[AdManager] Reward earned: ${reward.amount} ${reward.type}');
      rewardEarned = true;
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
