import 'dart:async';
import 'package:flutter/material.dart';

class HoldTimerIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const HoldTimerIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<HoldTimerIconButton> createState() => _HoldTimerIconButtonState();
}

class _HoldTimerIconButtonState extends State<HoldTimerIconButton> {
  Timer? _timer;
  Timer? _initialDelayTimer;

  void _startHolding() {
    widget.onPressed();
    _initialDelayTimer = Timer(const Duration(milliseconds: 400), () {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        widget.onPressed();
      });
    });
  }

  void _stopHolding() {
    _initialDelayTimer?.cancel();
    _timer?.cancel();
  }

  @override
  void dispose() {
    _initialDelayTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _stopHolding(),
      onTapCancel: () => _stopHolding(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(widget.icon, size: 24),
      ),
    );
  }
}
