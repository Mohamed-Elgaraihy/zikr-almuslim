import 'package:flutter/widgets.dart';

/// Web and desktop builds have no Play in-app update API.
class PlayUpdateGuard extends StatelessWidget {
  const PlayUpdateGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
