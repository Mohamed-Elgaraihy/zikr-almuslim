import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/progress_logic.dart';
import '../theme/app_theme.dart';

class CounterButton extends StatefulWidget {
  const CounterButton({
    super.key,
    required this.remaining,
    required this.done,
    required this.onTap,
    required this.onReset,
    required this.index,
    required this.label,
    this.haptics = true,
  });

  final int remaining;
  final bool done;
  final bool haptics;
  final bool Function() onTap;
  final VoidCallback onReset;
  final int index;
  final String label;

  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton>
    with SingleTickerProviderStateMixin {
  Timer? _rapid;
  Timer? _rapidStart;
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final CurvedAnimation _scale = CurvedAnimation(
    parent: _pop,
    curve: Curves.easeOutBack,
  );

  @override
  void initState() {
    super.initState();
    if (widget.done) _pop.value = 1;
  }

  @override
  void didUpdateWidget(CounterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.done && widget.done) {
      _pop.forward(from: 0);
    } else if (oldWidget.done && !widget.done) {
      _pop.value = 1;
    }
  }

  @override
  void dispose() {
    _stopRapid();
    _scale.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _stopRapid() {
    _rapidStart?.cancel();
    _rapid?.cancel();
    _rapidStart = null;
    _rapid = null;
  }

  void _tick() {
    final finishing = widget.remaining <= 1;
    if (!widget.onTap()) {
      _stopRapid();
      return;
    }
    if (!widget.haptics) return;
    if (finishing) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.done;
    return Semantics(
      button: true,
      label: done
          ? 'اكتمل. ${widget.label}'
          : 'المتبقي ${widget.remaining}. ${widget.label}',
      child: SizedBox(
        height: 76,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: done ? null : _tick,
                onLongPressStart: done
                    ? null
                    : (_) {
                        _tick();
                        _rapidStart = Timer(
                          const Duration(milliseconds: 280),
                          () {
                            _rapid = Timer.periodic(
                              const Duration(milliseconds: 70),
                              (_) => _tick(),
                            );
                          },
                        );
                      },
                onLongPressEnd: (_) => _stopRapid(),
                onLongPressCancel: _stopRapid,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: done ? AppColors.greenDark : AppColors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: done
                      ? FadeTransition(
                          opacity: _pop.drive(Tween(begin: 0.45, end: 1)),
                          child: ScaleTransition(
                            scale: _scale.drive(Tween(begin: 0.72, end: 1)),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                Text(
                                  'تم',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Text(
                          formatCount(widget.remaining),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: IconButton(
                tooltip: 'إعادة',
                onPressed: widget.onReset,
                icon: Icon(
                  Icons.replay_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 6,
              child: Text(
                '${widget.index}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
