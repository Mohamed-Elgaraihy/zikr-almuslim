import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_unit.dart';
import '../ads/ads_bootstrap.dart';
import '../theme/app_theme.dart';

/// Height, in dp, of an anchored adaptive banner for [width].
///
/// Reserved before the creative arrives so the page does not jump when the
/// ad fills. Matches the size AdMob uses for anchored adaptive banners.
int anchoredBannerHeight(int width) {
  if (width <= 0) return 50;
  final height = (width / 6.4).round();
  if (height < 50) return 50;
  if (height > 90) return 90;
  return height;
}

class MobileBanner extends StatefulWidget {
  const MobileBanner({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(16, 24, 16, 24),
    this.labeled = false,
  });

  final EdgeInsets margin;

  /// Reading-list slot: fixed height, an «إعلان» label, and no collapse.
  final bool labeled;

  @override
  State<MobileBanner> createState() => _MobileBannerState();
}

class _MobileBannerState extends State<MobileBanner> {
  BannerAd? _banner;
  int? _width;
  int? _reservedHeight;
  Orientation? _orientation;
  bool _loaded = false;
  bool _failed = false;
  bool _closed = false;
  bool _loading = false;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    final width = (MediaQuery.sizeOf(context).width - widget.margin.horizontal)
        .truncate();
    if (width < 200) return;
    if (_width == width &&
        _orientation == orientation &&
        (_banner != null || _failed || _loading)) {
      return;
    }
    _orientation = orientation;
    _width = width;
    _reservedHeight = anchoredBannerHeight(width);
    _loaded = false;
    _failed = false;
    _loading = true;
    _load(width, orientation);
  }

  Future<void> _load(int width, Orientation orientation) async {
    final request = ++_request;
    final previous = _banner;
    _banner = null;
    previous?.dispose();
    if (!mounted || _closed) return;
    final ready = await startMobileAds();
    if (!mounted || _closed || request != _request) return;
    if (!ready) {
      setState(() {
        _failed = true;
        _loading = false;
      });
      return;
    }
    if (_width != width || _orientation != orientation) return;
    if (widget.labeled) {
      await _loadFixed(width, request);
      return;
    }
    final adaptive =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
          orientation,
          width,
        );
    if (!mounted || _closed || request != _request) return;
    if (_width != width || _orientation != orientation) return;
    final estimated = _reservedHeight ?? anchoredBannerHeight(width);
    final size = adaptive ?? AdSize(width: width, height: estimated);
    // Lock the slot to the size we request, still before the creative loads.
    if (_reservedHeight != size.height && mounted) {
      setState(() => _reservedHeight = size.height);
    }
    final banner = BannerAd(
      adUnitId: kAdMobBannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || _closed || !identical(_banner, ad)) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (identical(_banner, ad)) _banner = null;
          if (!mounted || _closed) return;
          setState(() {
            _failed = true;
            _loaded = false;
          });
        },
      ),
    );
    _banner = banner;
    try {
      await banner.load();
    } catch (_) {
      if (identical(_banner, banner)) _banner = null;
      banner.dispose();
      if (mounted && !_closed && request == _request) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted && request == _request) {
        _loading = false;
      }
    }
  }

  Future<void> _loadFixed(int width, int request) async {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final maxHeight = landscape ? 50 : 64;
    final size = AdSize.getInlineAdaptiveBannerAdSize(width, maxHeight);
    if (_reservedHeight != maxHeight && mounted) {
      setState(() => _reservedHeight = maxHeight);
    }
    final banner = BannerAd(
      adUnitId: kAdMobBannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || _closed || !identical(_banner, ad)) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (identical(_banner, ad)) _banner = null;
          if (!mounted || _closed) return;
          setState(() {
            _failed = true;
            _loaded = false;
          });
        },
      ),
    );
    _banner = banner;
    try {
      await banner.load();
    } catch (_) {
      if (identical(_banner, banner)) _banner = null;
      banner.dispose();
      if (mounted && !_closed && request == _request) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted && request == _request) _loading = false;
    }
  }

  @override
  void dispose() {
    _closed = true;
    _request++;
    _banner?.dispose();
    _banner = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final width = (MediaQuery.sizeOf(context).width - widget.margin.horizontal)
        .truncate();
    if (width < 200) return const SizedBox.shrink();
    final fixedHeight = landscape ? 50.0 : 64.0;
    final height = widget.labeled
        ? fixedHeight
        : (_reservedHeight ?? anchoredBannerHeight(width)).toDouble();
    if (!widget.labeled && _failed) return const SizedBox.shrink();
    final banner = _banner;
    final creative = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: _loaded && banner != null && !_failed
            ? Center(
                child: SizedBox(
                  width: banner.size.width.toDouble(),
                  height: height,
                  child: AdWidget(ad: banner),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
    if (!widget.labeled) {
      return Padding(padding: widget.margin, child: creative);
    }
    final label = Text(
      'إعلان',
      style: TextStyle(
        color: Theme.of(context).extension<AppPalette>()?.inkSoft,
        fontSize: landscape ? 13 : 14,
        fontWeight: FontWeight.w700,
      ),
    );
    return Padding(
      padding: widget.margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).extension<AppPalette>()?.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                Theme.of(context).extension<AppPalette>()?.line ??
                const Color(0xFFE4D9C4),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, landscape ? 8 : 12, 12, 12),
          child: landscape
              ? Row(
                  children: [
                    label,
                    const SizedBox(width: 12),
                    Expanded(child: creative),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: label,
                    ),
                    const SizedBox(height: 8),
                    creative,
                  ],
                ),
        ),
      ),
    );
  }
}
