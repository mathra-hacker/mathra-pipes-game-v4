import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pipes/domain/models/app_settings.dart';

class _Drop {
  _Drop({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.swayAmp,
    required this.swayFreq,
    required this.phase,
    required this.emojiIndex,
    required this.spin,
  });

  double x; // 0..1 of width
  double y; // pixels
  double size;
  double speed; // px / second
  double swayAmp;
  double swayFreq;
  double phase;
  int emojiIndex;
  double spin;
}

/// Falling emoji overlay. Set [active] to start / stop the rain.
/// [speed] chooses slow (gentle) or fast (heavy) falling.
class EmojiRain extends StatefulWidget {
  const EmojiRain({
    super.key,
    required this.active,
    required this.emojis,
    this.speed = EmojiSpeed.slow,
  });

  final bool active;
  final List<String> emojis;
  final EmojiSpeed speed;

  @override
  State<EmojiRain> createState() => _EmojiRainState();
}

class _EmojiRainState extends State<EmojiRain>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  final List<_Drop> _drops = [];
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _time = 0;
  double _spawnAcc = 0;
  Size _size = Size.zero;
  List<TextPainter> _painters = [];

  static const double _glyphSize = 40;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _buildPainters();
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant EmojiRain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emojis != widget.emojis) {
      _buildPainters();
      _drops.clear();
    }
    if (widget.active && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _buildPainters() {
    for (final p in _painters) {
      p.dispose();
    }
    _painters = widget.emojis.map((e) {
      final tp = TextPainter(
        text: TextSpan(text: e, style: const TextStyle(fontSize: _glyphSize)),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp;
    }).toList();
  }

  void _spawn() {
    if (_painters.isEmpty) return;
    final fast = widget.speed == EmojiSpeed.fast;
    final size = 18 + _rng.nextDouble() * 22;
    final speed = fast
        ? 380 + _rng.nextDouble() * 360
        : 55 + _rng.nextDouble() * 70;
    _drops.add(_Drop(
      x: _rng.nextDouble(),
      y: -size * 1.5,
      size: size,
      speed: speed,
      swayAmp: fast ? 6 + _rng.nextDouble() * 8 : 14 + _rng.nextDouble() * 22,
      swayFreq: 0.8 + _rng.nextDouble() * 1.6,
      phase: _rng.nextDouble() * math.pi * 2,
      emojiIndex: _rng.nextInt(_painters.length),
      spin: (_rng.nextDouble() - 0.5) * (fast ? 4.0 : 1.2),
    ));
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt;

    if (widget.active && _size.height > 0) {
      final fast = widget.speed == EmojiSpeed.fast;
      final perSecond = fast ? 26.0 : 7.0;
      _spawnAcc += dt * perSecond;
      while (_spawnAcc >= 1) {
        _spawnAcc -= 1;
        _spawn();
      }
    }

    for (final d in _drops) {
      d.y += d.speed * dt;
    }
    _drops.removeWhere((d) => d.y > _size.height + d.size * 2);

    if (!widget.active && _drops.isEmpty) {
      _ticker.stop();
      _last = Duration.zero;
    }
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    for (final p in _painters) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = Size(constraints.maxWidth, constraints.maxHeight);
          return CustomPaint(
            size: Size.infinite,
            painter: _RainPainter(
              drops: _drops,
              painters: _painters,
              time: () => _time,
              repaint: _repaint,
            ),
          );
        },
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.drops,
    required this.painters,
    required this.time,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<_Drop> drops;
  final List<TextPainter> painters;
  final double Function() time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time();
    for (final d in drops) {
      if (d.emojiIndex >= painters.length) continue;
      final tp = painters[d.emojiIndex];
      final cx = d.x * size.width + math.sin(t * d.swayFreq + d.phase) * d.swayAmp;
      final scale = d.size / _EmojiRainState._glyphSize;
      canvas.save();
      canvas.translate(cx, d.y);
      canvas.rotate(math.sin(t * d.swayFreq + d.phase) * 0.35 + d.spin * 0.1 * t);
      canvas.scale(scale);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}

/// Small preview box for the Settings page.
class EmojiRainPreview extends StatefulWidget {
  const EmojiRainPreview({
    super.key,
    required this.emojis,
    required this.speed,
    required this.button,
  });

  final List<String> emojis;
  final EmojiSpeed speed;
  final Widget Function(bool running, VoidCallback toggle) button;

  @override
  State<EmojiRainPreview> createState() => _EmojiRainPreviewState();
}

class _EmojiRainPreviewState extends State<EmojiRainPreview> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: EmojiRain(
                    active: _running,
                    emojis: widget.emojis,
                    speed: widget.speed,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        widget.button(_running, () => setState(() => _running = !_running)),
      ],
    );
  }
}
