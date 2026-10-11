import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../navigation/app_route_observer.dart';

@JS('zikrPushAd')
external void _zikrPushAd();

const _client = 'ca-pub-2232586275729296';
const _slot = '8566138658';

Future<void>? _scriptReady;
int _adSerial = 0;
_WebAdState? _visibleAd;

Future<void> _ensureAdScript() {
  final pending = _scriptReady;
  if (pending != null) return pending;
  final done = Completer<void>();
  _scriptReady = done.future;
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  final existing = html.document.querySelector('script[src*="adsbygoogle.js"]');
  Timer(const Duration(seconds: 10), finish);
  if (existing is html.ScriptElement) {
    existing.onLoad.first.then((_) => finish());
    existing.onError.first.then((_) => finish());
    return done.future;
  }
  final script = html.ScriptElement()
    ..async = true
    ..src =
        'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=$_client'
    ..crossOrigin = 'anonymous';
  script.onLoad.first.then((_) => finish());
  script.onError.first.then((_) => finish());
  html.document.head!.append(script);
  return done.future;
}

class WebAd extends StatefulWidget {
  const WebAd({super.key});

  @override
  State<WebAd> createState() => _WebAdState();
}

class _WebAdState extends State<WebAd> with RouteAware {
  String? _viewType;
  html.DivElement? _wrap;
  html.Element? _ins;
  Timer? _watch;
  bool _onTop = true;
  bool _pushed = false;
  double _height = 100;
  int _tries = 0;
  int _fills = 0;

  @override
  void initState() {
    super.initState();
    _prepareSlot();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestFill());
  }

  void _prepareSlot() {
    _watch?.cancel();
    _pushed = false;
    _tries = 0;
    _height = 100;
    final viewType = 'zikr-ad-${_adSerial++}';
    _viewType = viewType;
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final wrap = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden';
      final ins = html.Element.tag('ins')
        ..classes.add('adsbygoogle')
        ..style.display = 'block'
        ..style.width = '100%'
        ..style.height = '100%'
        ..attributes['data-ad-client'] = _client
        ..attributes['data-ad-slot'] = _slot
        ..attributes['data-ad-format'] = 'auto'
        ..attributes['data-full-width-responsive'] = 'true';
      wrap.append(ins);
      _wrap = wrap;
      _ins = ins;
      return wrap;
    });
  }

  void _dropDom() {
    _watch?.cancel();
    _pushed = false;
    _wrap?.remove();
    _wrap = null;
    _ins = null;
    if (identical(_visibleAd, this)) _visibleAd = null;
  }

  void _claim() {
    final previous = _visibleAd;
    if (identical(previous, this)) return;
    previous?._dropDom();
    _visibleAd = this;
  }

  Future<void> _requestFill() async {
    if (!mounted || !_onTop || _pushed) return;
    final ins = _ins;
    if (ins == null || ins.isConnected != true || ins.offsetWidth < 200) {
      _tries++;
      if (_tries < 50) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _requestFill());
      }
      return;
    }
    _claim();
    if (!identical(_visibleAd, this) || ins.isConnected != true) return;
    await _ensureAdScript();
    if (!mounted || !_onTop || _pushed || ins.isConnected != true) return;
    if (!identical(_visibleAd, this)) return;
    try {
      _zikrPushAd();
      _pushed = true;
      _fills++;
    } catch (_) {}
    _watchStatus(ins);
  }

  void _watchStatus(html.Element ins) {
    var ticks = 0;
    _watch = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      ticks++;
      if (!mounted || !_onTop) {
        timer.cancel();
        return;
      }
      final status = ins.getAttribute('data-ad-status');
      final measured = _measuredHeight(ins);
      final filled = status == 'filled' || ins.querySelector('iframe') != null;
      if (filled && measured > 40) {
        _fit(measured);
        if (status == 'filled' || ticks > 8) timer.cancel();
      } else if (status == 'unfilled') {
        timer.cancel();
        _retryOrHide();
      } else if (ticks >= 30) {
        timer.cancel();
        if (measured > 40) {
          _fit(measured);
        } else {
          _retryOrHide();
        }
      }
    });
  }

  double _measuredHeight(html.Element ins) {
    var best = ins.offsetHeight.toDouble();
    final styled = _px(ins.style.height);
    if (styled != null && styled > best) best = styled;
    final frame = ins.querySelector('iframe');
    if (frame is html.Element) {
      final frameHeight = frame.offsetHeight.toDouble();
      if (frameHeight > best) best = frameHeight;
      final frameStyled = _px(frame.style.height);
      if (frameStyled != null && frameStyled > best) best = frameStyled;
    }
    return best;
  }

  double? _px(String value) {
    if (!value.endsWith('px')) return null;
    return double.tryParse(value.substring(0, value.length - 2));
  }

  void _fit(double measured) {
    final next = measured.clamp(60, 320).toDouble();
    if (!mounted || (next - _height).abs() < 2) return;
    setState(() => _height = next);
  }

  void _retryOrHide() {
    if (!mounted || !_onTop) return;
    if (_fills < 2) {
      _recycle();
      return;
    }
    setState(() => _height = 0);
  }

  void _recycle() {
    _dropDom();
    _prepareSlot();
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestFill());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    appRouteObserver.unsubscribe(this);
    if (route is ModalRoute<void>) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _dropDom();
    setState(() => _onTop = false);
  }

  @override
  void didPopNext() {
    _viewType = null;
    setState(() => _onTop = true);
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || !_onTop) return;
      _fills = 0;
      _recycle();
    });
  }

  @override
  void dispose() {
    _watch?.cancel();
    _dropDom();
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    if (!_onTop || viewType == null || _height < 40) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        key: ValueKey(viewType),
        height: _height,
        width: double.infinity,
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}
