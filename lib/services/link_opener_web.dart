import 'dart:js_interop';

@JS('window.open')
external JSAny? _open(JSString url, JSString target);

Future<bool> openInBrowser(String url) async {
  final opened = _open(url.toJS, '_blank'.toJS);
  return opened != null;
}
