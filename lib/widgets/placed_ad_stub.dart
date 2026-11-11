import 'package:flutter/widgets.dart';

import 'web_ad.dart';

class PlacedAd extends StatelessWidget {
  const PlacedAd({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(16, 24, 16, 24),
  });

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => WebAd(margin: margin);
}
