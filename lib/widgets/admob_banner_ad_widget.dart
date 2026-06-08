// File: admob_banner_ad_widget.dart (AdMob 배너 광고 위젯)
// Last Modified: 2026-06-05 00:00 KST (작성자: ChatGPT)
// Insert Location: G:\stockmarket_frontend\lib\widgets\admob_banner_ad_widget.dart 새 파일 생성

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobBannerAdWidget extends StatefulWidget {
  const AdMobBannerAdWidget({
    super.key,
    required this.realAdUnitId,
  });

  final String realAdUnitId;

  @override
  State<AdMobBannerAdWidget> createState() => _AdMobBannerAdWidgetState();
}

class _AdMobBannerAdWidgetState extends State<AdMobBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  String get _adUnitId {
    if (kReleaseMode) {
      return widget.realAdUnitId;
    }

    // Google 공식 Android 테스트 배너 광고 ID
    // (Google official Android test banner ad unit ID)
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  @override
  void initState() {
    super.initState();

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;

          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (!mounted) return;

          setState(() {
            _isAdLoaded = false;
          });

          debugPrint('AdMob banner failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}