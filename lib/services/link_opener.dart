import 'link_opener_stub.dart'
    if (dart.library.js_interop) 'link_opener_web.dart'
    as opener;

Future<bool> openInBrowser(String url) => opener.openInBrowser(url);
