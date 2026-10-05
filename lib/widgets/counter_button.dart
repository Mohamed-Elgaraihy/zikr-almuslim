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
    required this.label,
  });

  final int remaining;
  final bool done;
  final bool Function() onTap;
  final String label;

  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _rapid;
  Timer? _rapidStart;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.94,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _stopRapid();
    _pulse.dispose();
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
    _pulse.forward(from: 0.94);
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.done;
    return Semantics(
      button: true,
      label: done ? 'اكتمل. ${widget.label}' : 'المتبقي ${widget.remaining}. ${widget.label}',
      child: GestureDetector(
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
        child: ScaleTransition(
          scale: _pulse,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.green : AppColors.card,
              border: Border.all(
                color: done ? AppColors.green : AppColors.green,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: done ? 0.25 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 34)
                : Text(
                    formatCount(widget.remaining),
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDark,
                      height: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
