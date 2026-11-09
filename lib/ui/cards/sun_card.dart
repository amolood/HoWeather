import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../icons/glyphs.dart';
import '../theme.dart';
import '../sky/sky_palette.dart';
import '../typography.dart';
import 'glass_card.dart';

int? _minutes(String hhmm) {
  final p = hhmm.split(':');
  if (p.length != 2) return null;
  final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
  return h == null || m == null ? null : h * 60 + m;
}

/// Position of [cityNow] (city wall-clock, from `bundle.toCityTime`)
/// between [today]'s sunrise and sunset, clamped to 0..1.
double sunProgress(DailyPoint today, DateTime cityNow) {
  final rise = _minutes(today.sunrise), set = _minutes(today.sunset);
  if (rise == null || set == null || set <= rise) return 0;
  final now = cityNow.hour * 60 + cityNow.minute;
  return ((now - rise) / (set - rise)).clamp(0.0, 1.0).toDouble();
}

/// Minutes between [today]'s sunrise and sunset, or null when unknown.
int? daylightMinutes(DailyPoint today) {
  final rise = _minutes(today.sunrise), set = _minutes(today.sunset);
  if (rise == null || set == null || set <= rise) return null;
  return set - rise;
}

/// Moon phases, each with its image in assets/icons/.
enum MoonPhase {
  newMoon('new_moon'),
  waxingCrescent('waxing_crescent'),
  firstQuarter('first_quarter'),
  waxingGibbous('waxing_gibbous'),
  fullMoon('full_moon'),
  waningGibbous('waning_gibbous'),
  lastQuarter('last_quarter'),
  waningCrescent('waning_crescent');

  final String _file;
  const MoonPhase(this._file);
  String get asset => 'assets/icons/moon_$_file.webp';
}

/// The API's `moon_phase` text ("Waxing Gibbous", "Third Quarter", ...).
MoonPhase? moonPhaseOf(String text) => switch (text.trim().toLowerCase()) {
  'new moon' => MoonPhase.newMoon,
  'waxing crescent' => MoonPhase.waxingCrescent,
  'first quarter' => MoonPhase.firstQuarter,
  'waxing gibbous' => MoonPhase.waxingGibbous,
  'full moon' => MoonPhase.fullMoon,
  'waning gibbous' => MoonPhase.waningGibbous,
  'last quarter' || 'third quarter' => MoonPhase.lastQuarter,
  'waning crescent' => MoonPhase.waningCrescent,
  _ => null,
};

String moonPhaseText(AppLocalizations l, MoonPhase m) => switch (m) {
  MoonPhase.newMoon => l.moonNew,
  MoonPhase.waxingCrescent => l.moonWaxingCrescent,
  MoonPhase.firstQuarter => l.moonFirstQuarter,
  MoonPhase.waxingGibbous => l.moonWaxingGibbous,
  MoonPhase.fullMoon => l.moonFull,
  MoonPhase.waningGibbous => l.moonWaningGibbous,
  MoonPhase.lastQuarter => l.moonLastQuarter,
  MoonPhase.waningCrescent => l.moonWaningCrescent,
};

/// Sunrise and sunset with an arc showing how far the sun has travelled.
/// [now] must be city time (`bundle.toCityTime(...)`).
class SunCard extends StatelessWidget {
  final DailyPoint today;
  final DateTime now;
  const SunCard(this.today, this.now, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = SkyPalette.of(context);
    final length = daylightMinutes(today);
    final moon = moonPhaseOf(today.moonPhase);
    final caption = AppType.caption.copyWith(color: p.inkSoft);
    return GlassCard(
      title: l.sunriseSunset,
      glyph: Glyph.sunrise,
      footer: length == null && moon == null
          ? null
          : Row(
              children: [
                Expanded(
                  child: length == null
                      ? const SizedBox()
                      : Text(
                          l.daylight(l.durationHm(length ~/ 60, length % 60)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: caption,
                        ),
                ),
                if (moon != null) ...[
                  const SizedBox(width: 8),
                  Image.asset(
                    moon.asset,
                    key: const ValueKey('moonPhaseIcon'),
                    width: 20,
                    height: 20,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      moonPhaseText(l, moon),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: caption.copyWith(
                        color: p.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
      child: Row(
        children: [
          Expanded(child: _Side(l.sunrise, today.sunrise)),
          SizedBox(
            width: 140,
            height: 56,
            child: CustomPaint(
              painter: SunArcPainter(
                progress: sunProgress(today, now),
                track: SkyPalette.of(context).glassLine,
                accent: AppTokens.accent,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
          Expanded(child: _Side(l.sunset, today.sunset, end: true)),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final String label, time;
  final bool end;
  const _Side(this.label, this.time, {this.end = false});

  @override
  Widget build(BuildContext context) {
    final soft = SkyPalette.of(context).inkSoft;
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          AppType.labelText(context, label),
          style: AppType.labelOf(context).copyWith(fontSize: 11, color: soft),
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class SunArcPainter extends CustomPainter {
  final double progress;
  final Color track, accent;
  final bool rtl;
  const SunArcPainter({
    required this.progress,
    required this.track,
    required this.accent,
    required this.rtl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    // Upper half of an ellipse from the bottom-left to the bottom-right.
    final rect = Rect.fromLTRB(6, 6, size.width - 6, (size.height - 4) * 2 - 6);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dashes = 18;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        rect,
        math.pi + i * math.pi / dashes,
        math.pi / dashes / 2,
        false,
        trackPaint,
      );
    }
    final sweep = math.pi * progress;
    canvas.drawArc(
      rect,
      math.pi,
      sweep,
      false,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final a = math.pi + sweep;
    final dot = Offset(
      rect.center.dx + rect.width / 2 * math.cos(a),
      rect.center.dy + rect.height / 2 * math.sin(a),
    );
    canvas.drawCircle(dot, 6, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(SunArcPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.accent != accent ||
      old.rtl != rtl;
}
