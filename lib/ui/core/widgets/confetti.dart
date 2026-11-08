import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Piece {
  _Piece({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.color,
    required this.round,
  });

  double x; // pixels
  double y; // pixels
  double vx; // px / s
  double vy; // px / s
  final double size;
  double rotation;
  final double spin;
  final Color color;
  final bool round;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 620 * dt; // gravity
    final drag = math.pow(0.985, dt * 60).toDouble();
    vx *= drag;
    vy *= drag;
    rotation += spin * dt;
  }
}

/// Bursts coloured confetti from the middle of the screen when
/// [trigger] changes from false to true.
class ConfettiExplosion extends StatefulWidget {
  const ConfettiExplosion({super.key, required this.trigger});

  final bool trigger;

  @override
  State<ConfettiExplosion> createState() => _ConfettiExplosionState();
}

class _ConfettiExplosionState extends State<ConfettiExplosion>
    with SingleTickerProviderStateMixin {
  static const double _seconds = 3.2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..addListener(_tick);

  final List<_Piece> _pieces = [];
  final math.Random _rng = math.Random();
  double _lastValue = 0;

  static const List<Color> _colors = [
    Color(0xFFFF5252),
    Color(0xFFFFC107),
    Color(0xFF69F0AE),
    Color(0xFF40C4FF),
    Color(0xFFE040FB),
    Color(0xFFFF9100),
  ];

  @override
  void didUpdateWidget(covariant ConfettiExplosion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _burst(MediaQuery.sizeOf(context));
    }
  }

  void _burst(Size size) {
    _pieces.clear();
    final cx = size.width / 2;
    final cy = size.height * 0.38;
    for (var i = 0; i < 110; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 260 + _rng.nextDouble() * 520;
      _pieces.add(
        _Piece(
          x: cx,
          y: cy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 260,
          size: 7 + _rng.nextDouble() * 9,
          rotation: _rng.nextDouble() * 2 * math.pi,
          spin: (_rng.nextDouble() - 0.5) * 14,
          color: _colors[_rng.nextInt(_colors.length)],
          round: _rng.nextBool(),
        ),
      );
    }
    _lastValue = 0;
    _controller.forward(from: 0.0);
  }

  void _tick() {
    final v = _controller.value;
    final dt = ((v - _lastValue) * _seconds).clamp(0.0, 0.05);
    _lastValue = v;
    for (final p in _pieces) {
      p.update(dt);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating) return const SizedBox.shrink();
    final fade = (1.0 - ((_controller.value - 0.75) / 0.25)).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Opacity(
        opacity: fade,
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces);

  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      if (p.y > size.height + 20 || p.x < -20 || p.x > size.width + 20) {
        continue;
      }
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
