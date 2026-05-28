import 'package:flutter/material.dart';

/// A widget that pulses [phase] from 0..1 and back. Drives all flash effects.
class FlashPulse extends StatefulWidget {
  const FlashPulse({super.key, required this.enabled, required this.builder});

  final bool enabled;
  final Widget Function(BuildContext context, double phase) builder;

  @override
  State<FlashPulse> createState() => _FlashPulseState();
}

class _FlashPulseState extends State<FlashPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..addListener(() => setState(() {}));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant FlashPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.enabled) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _controller.value);
}
