import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'open_dua_map.dart';

/// Plays one bundled adhkar clip at a time, or the mapped clips in order.
class AdhkarPlayback extends ChangeNotifier {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _states;
  StreamSubscription<AudioInterruptionEvent>? _interruptions;
  bool _sessionReady = false;
  bool _expectingCompletion = false;

  String? categoryId;
  int? itemId;
  bool sequence = false;
  List<int> _ids = const [];
  int _index = 0;

  bool playingItem(String category, int id) =>
      categoryId == category && itemId == id;

  Future<void> toggle(String category, int id) async {
    if (openDuaAsset(category, id) == null) return;
    if (playingItem(category, id)) {
      await stop();
      return;
    }
    sequence = false;
    await _start(category, [id], 0);
  }

  Future<void> playAll(String category, List<int> orderedIds) async {
    if (sequence) {
      await stop();
      return;
    }
    final ids = [
      for (final id in orderedIds)
        if (openDuaAsset(category, id) != null) id,
    ];
    if (ids.isEmpty) return;
    sequence = true;
    await _start(category, ids, 0);
  }

  Future<void> stop() async {
    _expectingCompletion = false;
    sequence = false;
    _ids = const [];
    _index = 0;
    categoryId = null;
    itemId = null;
    notifyListeners();
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> close() async {
    await stop();
    await _states?.cancel();
    await _interruptions?.cancel();
    _states = null;
    _interruptions = null;
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } catch (_) {}
  }

  Future<void> _start(String category, List<int> ids, int index) async {
    final asset = openDuaAsset(category, ids[index]);
    if (asset == null) return;
    _expectingCompletion = false;
    categoryId = category;
    _ids = ids;
    _index = index;
    itemId = ids[index];
    notifyListeners();
    try {
      await _prepare();
      final player = _player!;
      await player.setAsset(asset);
      if (itemId != ids[index] || categoryId != category) return;
      _expectingCompletion = true;
      unawaited(
        player.play().catchError((Object _) {
          if (playingItem(category, ids[index])) unawaited(stop());
        }),
      );
    } catch (_) {
      if (playingItem(category, ids[index])) await stop();
    }
  }

  Future<void> _prepare() async {
    _player ??= AudioPlayer();
    _states ??= _player!.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        unawaited(_onCompleted());
      }
    });
    if (_sessionReady) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _interruptions ??= session.interruptionEventStream.listen((event) {
      if (event.begin) unawaited(stop());
    });
    _sessionReady = true;
  }

  Future<void> _onCompleted() async {
    if (!_expectingCompletion) return;
    _expectingCompletion = false;
    if (!sequence) {
      await stop();
      return;
    }
    final next = _index + 1;
    if (categoryId == null || next >= _ids.length) {
      await stop();
      return;
    }
    await _start(categoryId!, _ids, next);
  }
}
