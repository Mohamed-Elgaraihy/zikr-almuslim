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
  });

  final int remaining;
  final bool done;
  final bool Function() onTap;
  final VoidCallback onReset;
  final int index;
  final String label;

  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton> {
  Timer? _rapid;
  Timer? _rapidStart;

  @override
  void dispose() {
    _stopRapid();
    super.dispose();
  }

  void _stopRapid() {
    _rapidStart?.cancel();
    _rapid?.cancel();
    _rapidStart = null;
    _rapid = null;
  }

  void _tick() {
    if (!widget.onTap()) {
      _stopRapid();
      return;
    }
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.done;
    return Semantics(
      button: true,
      label: done ? 'اكتمل. ${widget.label}' : 'المتبقي ${widget.remaining}. ${widget.label}',
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
                        _rapidStart = Timer(const Duration(milliseconds: 280), () {
                          _rapid = Timer.periodic(
                            const Duration(milliseconds: 70),
                            (_) => _tick(),
                          );
                        });
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
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 36)
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
