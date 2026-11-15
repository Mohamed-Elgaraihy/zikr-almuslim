import 'dart:io';

import 'package:flutter/widgets.dart';

import 'mobile_banner.dart';

class PlacedAd extends StatelessWidget {
  const PlacedAd({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(16, 24, 16, 24),
    this.labeled = false,
  });

  final EdgeInsets margin;
  final bool labeled;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const SizedBox.shrink();
    }
    return MobileBanner(margin: margin, labeled: labeled);
  }
}
