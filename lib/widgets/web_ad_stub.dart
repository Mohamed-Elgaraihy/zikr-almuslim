import 'package:flutter/material.dart';

class WebAd extends StatelessWidget {
  const WebAd({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(16, 24, 16, 24),
  });

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
