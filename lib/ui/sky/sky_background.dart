import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/condition_map.dart';

/// Our own sky palette: one top-to-bottom gradient per [SkyScene].
class SkyColors {
  SkyColors._();

  static const Map<SkyScene, List<Color>> _gradients = {
    SkyScene.clearDay: [
      Color(0xFF2F7EC4),
      Color(0xFF5FA8DD),
      Color(0xFF9FD0EF),
    ],
    SkyScene.clearNight: [
      Color(0xFF0B1F38),
      Color(0xFF132C4B),
      Color(0xFF1C3A5C),
    ],
    SkyScene.cloudyDay: [
      Color(0xFF5E7E9C),
      Color(0xFF8AA3BA),
      Color(0xFFB8C8D6),
    ],
    SkyScene.cloudyNight: [
      Color(0xFF141F2E),
      Color(0xFF213042),
      Color(0xFF2E4057),
    ],
    SkyScene.rainDay: [Color(0xFF3F5468), Color(0xFF5B7085), Color(0xFF8295A7)],
    SkyScene.rainNight: [
      Color(0xFF0E1824),
      Color(0xFF18273A),
      Color(0xFF24364B),
    ],
    SkyScene.snowDay: [Color(0xFF8FB0CC), Color(0xFFB7CDDF), Color(0xFFE2ECF4)],
    SkyScene.snowNight: [
      Color(0xFF1A2940),
      Color(0xFF2A3D58),
      Color(0xFF3C5270),
    ],
    SkyScene.fogDay: [Color(0xFF8C98A3), Color(0xFFA9B3BB), Color(0xFFC9CFD3)],
    SkyScene.fogNight: [
      Color(0xFF1F262E),
      Color(0xFF2D363F),
      Color(0xFF3C4650),
    ],
    SkyScene.stormDay: [
      Color(0xFF262B4A),
      Color(0xFF3A3F63),
      Color(0xFF555B7C),
    ],
    SkyScene.stormNight: [
      Color(0xFF0D0F22),
      Color(0xFF181B36),
      Color(0xFF25294A),
    ],
  };

  static List<Color> gradient(SkyScene s) => _gradients[s]!;
}

/// Full-bleed animated sky: gradient plus a painted layer (sun, moon, clouds,
/// rain, snow, haze). Renders a static frame when animations are disabled.
class SkyBackground extends StatefulWidget {
  const SkyBackground(this.scene, {super.key});

  final SkyScene scene;

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: SkyColors.gradient(widget.scene),
        ),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SkyPainter(widget.scene, _c),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// Motion helpers. `v` is the controller value in [0, 1); every element moves
// a whole number of cycles per loop so v = 0 and v = 1 give the same frame.

/// Fixed pseudo-random positions (unit square) for stars, rain and snow.
@visibleForTesting
final List<Offset> skySeeds = () {
  final r = math.Random(7);
  return List.generate(70, (_) => Offset(r.nextDouble(), r.nextDouble()));
}();

/// Clouds: x, y, scale (fractions of size) and whole laps per loop.
@visibleForTesting
const List<List<double>> cloudSpecs = [
  [0.10, 0.10, 1.00, 1],
  [0.60, 0.20, 1.30, 1],
  [0.30, 0.32, 0.80, 2],
  [0.85, 0.06, 0.90, 1],
];

/// Centre x of cloud [i]; it wraps across a span of 1.6 widths.
@visibleForTesting
double cloudX(int i, double v, double width) {
  final s = cloudSpecs[i];
  final span = width * 1.6;
  return ((s[0] * width + v * span * s[3]) % span) - width * 0.3;
}

/// Vertical phase in [0, 1) of a rain streak: 14 to 17 falls per loop.
@visibleForTesting
double rainPhase(Offset seed, double v) =>
    (seed.dy + v * (14 + (seed.dx * 4).floor())) % 1.0;

/// Vertical phase in [0, 1) of a snowflake: 2 or 3 falls per loop.
@visibleForTesting
double snowPhase(Offset seed, double v) =>
    (seed.dy + v * (2 + (seed.dx * 2).floor())) % 1.0;

/// Horizontal sway of a snowflake in logical pixels: 8 sways per loop.
@visibleForTesting
double snowSway(Offset seed, double v) =>
    math.sin((v * 8 + seed.dy) * 2 * math.pi) * 8;

enum _Precip { none, rain, snow }

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.scene, this.t) : super(repaint: t);

  final SkyScene scene;
  final Animation<double> t;

  Size? _moonSize;
  Path? _moonPath;

  bool get _night => scene.name.endsWith('Night');

  bool get _clouds => switch (scene) {
    SkyScene.clearDay || SkyScene.clearNight => false,
    SkyScene.fogDay || SkyScene.fogNight => false,
    _ => true,
  };

  _Precip get _precip => switch (scene) {
    SkyScene.rainDay ||
    SkyScene.rainNight ||
    SkyScene.stormDay ||
    SkyScene.stormNight => _Precip.rain,
    SkyScene.snowDay || SkyScene.snowNight => _Precip.snow,
    _ => _Precip.none,
  };

  bool get _storm => scene == SkyScene.stormDay || scene == SkyScene.stormNight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final v = t.value;
    if (scene == SkyScene.clearDay) _sun(canvas, size, v);
    if (scene == SkyScene.clearNight) _moon(canvas, size, v);
    if (_clouds) _cloudLayer(canvas, size, v);
    if (scene == SkyScene.fogDay || scene == SkyScene.fogNight) {
      _haze(canvas, size, v);
    }
    switch (_precip) {
      case _Precip.rain:
        _rain(canvas, size, v);
      case _Precip.snow:
        _snow(canvas, size, v);
      case _Precip.none:
        break;
    }
    if (_storm) _flash(canvas, size, v);
  }

  void _sun(Canvas canvas, Size size, double v) {
    final c = Offset(size.width * 0.78, size.height * 0.16);
    final r = math.min(size.width, size.height) * 0.14;
    final pulse = 1 + 0.06 * math.sin(v * 2 * math.pi * 4);
    canvas.drawCircle(
      c,
      r * 1.9 * pulse,
      Paint()
        ..color = const Color(0x8CFFCD5A)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.7),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.16, -0.24),
          colors: const [
            Color(0xFFFFF2C4),
            Color(0xFFFFD264),
            Color(0xFFFFB347),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _moon(Canvas canvas, Size size, double v) {
    final c = Offset(size.width * 0.76, size.height * 0.15);
    final r = math.min(size.width, size.height) * 0.09;
    // Stars twinkle gently.
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 28; i++) {
      final s = skySeeds[i];
      final a = 0.35 + 0.35 * math.sin((v * 6 + s.dx * 5) * 2 * math.pi);
      star.color = Colors.white.withValues(alpha: a.clamp(0.1, 0.8));
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height * 0.55),
        0.6 + s.dy,
        star,
      );
    }
    canvas.drawCircle(
      c,
      r * 2.2,
      Paint()
        ..color = const Color(0x33DDE8FF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
    );
    if (_moonSize != size) {
      final disc = Path()..addOval(Rect.fromCircle(center: c, radius: r));
      final bite = Path()
        ..addOval(
          Rect.fromCircle(center: c.translate(r * 0.45, -r * 0.2), radius: r),
        );
      _moonPath = Path.combine(PathOperation.difference, disc, bite);
      _moonSize = size;
    }
    canvas.drawPath(_moonPath!, Paint()..color = const Color(0xFFEEF3FB));
  }

  void _cloudLayer(Canvas canvas, Size size, double v) {
    final base = _night ? 0x2A : (_precip == _Precip.none ? 0x80 : 0x5C);
    final paint = Paint()
      ..color = Color.fromARGB(base, 255, 255, 255)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final w = size.width;
    for (var i = 0; i < cloudSpecs.length; i++) {
      final s = cloudSpecs[i];
      final x = cloudX(i, v, w);
      final y = s[1] * size.height;
      final k = s[2] * w * 0.22;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: k * 2.4, height: k),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + k * 0.5, y - k * 0.35),
          width: k * 1.4,
          height: k,
        ),
        paint,
      );
    }
  }

  void _haze(Canvas canvas, Size size, double v) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: _night ? 0.10 : 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    for (var i = 0; i < 3; i++) {
      final dx = math.sin((v + i / 3) * 2 * math.pi) * size.width * 0.08;
      final y = size.height * (0.22 + i * 0.16);
      canvas.drawRect(
        Rect.fromLTWH(
          -size.width * 0.2 + dx,
          y,
          size.width * 1.4,
          size.height * 0.07,
        ),
        paint,
      );
    }
  }

  void _rain(Canvas canvas, Size size, double v) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: _night ? 0.22 : 0.35)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final len = size.height * 0.035;
    for (final s in skySeeds) {
      final y = rainPhase(s, v) * (size.height + len) - len;
      final x = s.dx * size.width;
      canvas.drawLine(Offset(x, y), Offset(x - len * 0.18, y + len), paint);
    }
  }

  void _snow(Canvas canvas, Size size, double v) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (final s in skySeeds.take(50)) {
      final y = snowPhase(s, v) * size.height;
      final x = s.dx * size.width + snowSway(s, v);
      canvas.drawCircle(Offset(x, y), 1.4 + s.dy * 1.8, paint);
    }
  }

  void _flash(Canvas canvas, Size size, double v) {
    // One soft flash per cycle, ~0.6 s long.
    const at = 0.62, width = 0.015;
    final d = (v - at).abs();
    if (d > width) return;
    final a = (1 - d / width) * 0.12;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: a),
    );
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.scene != scene || old.t != t;
}
