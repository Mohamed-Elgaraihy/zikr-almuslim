import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_unit.dart';
import '../ads/ads_bootstrap.dart';

class MobileBanner extends StatefulWidget {
  const MobileBanner({super.key});

  @override
  State<MobileBanner> createState() => _MobileBannerState();
}

class _MobileBannerState extends State<MobileBanner> {
  BannerAd? _banner;
  AdSize? _size;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || _closed || _banner != null) return;
    final ready = await startMobileAds();
    if (!ready || !mounted || _closed || _banner != null) return;
    final width = MediaQuery.sizeOf(context).width.truncate() - 32;
    if (width < 200) return;
    final requested = AdSize.getInlineAdaptiveBannerAdSize(width, 100);
    final banner = BannerAd(
      adUnitId: kAdMobBannerUnitId,
      size: requested,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          final loaded = ad as BannerAd;
          if (!mounted || _closed) return;
          AdSize? platformSize;
          try {
            platformSize = await loaded.getPlatformAdSize();
          } catch (_) {}
          if (!mounted || _closed) return;
          final height = platformSize?.height ?? 0;
          if (height < 40) {
            if (identical(_banner, loaded)) _banner = null;
            loaded.dispose();
            if (mounted) setState(() => _size = null);
            return;
          }
          setState(() {
            _banner = loaded;
            _size = AdSize(
              width: platformSize?.width ?? width,
              height: height,
            );
          });
        },
        onAdFailedToLoad: (ad, error) {
          if (_closed) return;
          if (identical(_banner, ad)) _banner = null;
          ad.dispose();
          if (!mounted) return;
          setState(() => _size = null);
        },
      ),
    );
    _banner = banner;
    try {
      await banner.load();
    } catch (_) {
      if (identical(_banner, banner)) _banner = null;
      banner.dispose();
      if (mounted && !_closed) setState(() => _size = null);
    }
  }

  @override
  void dispose() {
    _closed = true;
    _banner?.dispose();
    _banner = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    final size = _size;
    if (banner == null || size == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Center(
        child: SizedBox(
          width: size.width.toDouble(),
          height: size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
