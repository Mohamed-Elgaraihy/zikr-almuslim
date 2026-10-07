import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/info_copy.dart';
import '../services/link_opener.dart';
import '../theme/app_theme.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.kind});

  final InfoKind kind;

  Future<void> _openSite(BuildContext context) async {
    var opened = await openInBrowser(kDeveloperSite);
    if (!opened) {
      try {
        opened =
            await const MethodChannel('zikr/links')
                .invokeMethod<bool>('open', {'url': kDeveloperSite}) ??
            false;
      } on PlatformException {
        opened = false;
      } on MissingPluginException {
        opened = false;
      }
    }
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تعذّر فتح الموقع. الرابط أعلاه يمكن نسخه.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(kind.title)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              for (final block in kind.blocks) ...[
                if (block.heading != null) ...[
                  Text(
                    block.heading!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.palette.greenDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  block.body,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.85,
                    color: context.palette.ink,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (kind.showsWebsite) ...[
                SelectableText(
                  kDeveloperSite,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.palette.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _openSite(context),
                  icon: const Icon(Icons.language_rounded),
                  label: const Text('الموقع الشخصي'),
                ),
              ],
              if (kind == InfoKind.about) ...[
                const SizedBox(height: 18),
                Text(
                  'الإصدار $kAppVersionLabel',
                  style: TextStyle(
                    color: context.palette.inkSoft,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
