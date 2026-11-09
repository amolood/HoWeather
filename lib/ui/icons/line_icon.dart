import 'package:flutter/widgets.dart';

/// A line icon on a 24x24 grid: SVG-style path data plus optional circles.
@immutable
class LineShape {
  /// SVG path data (M m L l H h V v C c S s A a Z z). Arcs must have rx == ry.
  final List<String> paths;

  /// Circles as (cx, cy, r).
  final List<(double, double, double)> circles;
  const LineShape(this.paths, [this.circles = const []]);
}

final _token = RegExp(r'[MmLlHhVvCcSsAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?');

/// Parses the small subset of SVG path syntax used by our icon set.
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = _token.allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cmd = '';
  var cur = Offset.zero, start = Offset.zero;
  Offset? lastCtrl;
  double n() => double.parse(tokens[i++]);
  bool isCmd(String t) => RegExp(r'[A-Za-z]').hasMatch(t);

  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    final dx = rel ? cur.dx : 0.0, dy = rel ? cur.dy : 0.0;
    Offset? ctrl;
    switch (cmd.toUpperCase()) {
      case 'M':
        cur = Offset(dx + n(), dy + n());
        start = cur;
        path.moveTo(cur.dx, cur.dy);
        cmd = rel ? 'l' : 'L'; // implicit lineto after moveto
      case 'L':
        cur = Offset(dx + n(), dy + n());
        path.lineTo(cur.dx, cur.dy);
      case 'H':
        cur = Offset(dx + n(), cur.dy);
        path.lineTo(cur.dx, cur.dy);
      case 'V':
        cur = Offset(cur.dx, dy + n());
        path.lineTo(cur.dx, cur.dy);
      case 'C':
        final c1 = Offset(dx + n(), dy + n());
        final c2 = Offset(dx + n(), dy + n());
        final p = Offset(dx + n(), dy + n());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p.dx, p.dy);
        ctrl = c2;
        cur = p;
      case 'S':
        final c1 = lastCtrl == null ? cur : cur * 2 - lastCtrl;
        final c2 = Offset(dx + n(), dy + n());
        final p = Offset(dx + n(), dy + n());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p.dx, p.dy);
        ctrl = c2;
        cur = p;
      case 'A':
        final r = n();
        n(); // ry (equal to rx)
        n(); // x-axis rotation (unused)
        final large = n() != 0;
        final sweep = n() != 0;
        cur = Offset(dx + n(), dy + n());
        path.arcToPoint(
          cur,
          radius: Radius.circular(r),
          largeArc: large,
          clockwise: sweep,
        );
      case 'Z':
        path.close();
        cur = start;
      default:
        throw FormatException('Unsupported path command: $cmd');
    }
    lastCtrl = ctrl;
  }
  return path;
}

class LineIconPainter extends CustomPainter {
  final LineShape shape;
  final Color color;
  const LineIconPainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth =
          1.7 // in 24-grid units; canvas is scaled to size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.save();
    canvas.scale(s);
    for (final d in shape.paths) {
      canvas.drawPath(parseSvgPath(d), paint);
    }
    for (final (cx, cy, r) in shape.circles) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LineIconPainter old) =>
      old.shape != shape || old.color != color;
}

/// Shared widget body for [WxIconView] and [GlyphView].
class LineIconBox extends StatelessWidget {
  final LineShape shape;
  final double size;
  final Color? color;
  const LineIconBox({
    super.key,
    required this.shape,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return CustomPaint(
      size: Size.square(size),
      painter: LineIconPainter(shape, c),
    );
  }
}
