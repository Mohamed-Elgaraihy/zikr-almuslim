import 'dart:io';

import 'package:flutter/widgets.dart';

import 'mobile_banner.dart';

class PlacedAd extends StatelessWidget {
  const PlacedAd({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const SizedBox.shrink();
    }
    return const MobileBanner();
  }
}
