import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/life_index.dart';
import '../../domain/models.dart';
import '../../domain/units.dart';
import '../../l10n/gen/app_localizations.dart';
import '../icons/glyphs.dart';
import '../icons/line_icon.dart';
import '../sky/sky_palette.dart';
import 'glass_card.dart';

/// Where a reading sits on its range (0..1, start to end) and the
/// colours of that range, drawn as a thin bar under the big value.
class _Scale {
  final double position;
  final List<Color> colors;
  const _Scale(this.position, this.colors);
}

class _Metric {
  final String title, value, unit, info, pill;
  final Widget? pillLeading;
  final _Scale? scale;
  const _Metric(
    this.title,
    this.value, {
    this.unit = '',
    this.info = '',
    this.pill = '',
    this.pillLeading,
    this.scale,
  });
}

/// Localized EPA (US) category label, 1..6.
String aqiLabel(AppLocalizations l, int epa) => switch (epa) {
  1 => l.aqiGood,
  2 => l.aqiModerate,
  3 => l.aqiUnhealthySensitive,
  4 => l.aqiUnhealthy,
  5 => l.aqiVeryUnhealthy,
  6 => l.aqiHazardous,
  _ => l.noData,
};

/// Localized wind speed unit.
String windUnitText(AppLocalizations l, WindUnit u) => switch (u) {
  WindUnit.kmh => l.unitKmh,
  WindUnit.mph => l.unitMph,
  WindUnit.ms => l.unitMs,
};

/// Localized 16-point compass direction from the API's `wind_dir`
/// (e.g. "WSW"); anything unknown is shown as-is.
String windDirText(AppLocalizations l, String dir) => switch (dir) {
  'N' => l.dirN,
  'NNE' => l.dirNNE,
  'NE' => l.dirNE,
  'ENE' => l.dirENE,
  'E' => l.dirE,
  'ESE' => l.dirESE,
  'SE' => l.dirSE,
  'SSE' => l.dirSSE,
  'S' => l.dirS,
  'SSW' => l.dirSSW,
  'SW' => l.dirSW,
  'WSW' => l.dirWSW,
  'W' => l.dirW,
  'WNW' => l.dirWNW,
  'NW' => l.dirNW,
  'NNW' => l.dirNNW,
  _ => dir,
};

/// Our own swatch per EPA category.
Color aqiColor(int epa) => switch (epa) {
  1 => const Color(0xFF5BBF7A),
  2 => const Color(0xFFE8C93D),
  3 => const Color(0xFFE8A33D),
  4 => const Color(0xFFE0604A),
  5 => const Color(0xFF9B5BC0),
  _ => const Color(0xFF8A3A4A),
};

/// Relative humidity bands used for the humidity pill.
const humidityDryBelow = 30, humidityHumidAbove = 60;

/// Sea-level pressure bands (mb) used for the pressure pill.
const pressureLowBelow = 1009.0, pressureHighAbove = 1022.0;

String humidityLabel(AppLocalizations l, int h) => h < humidityDryBelow
    ? l.humidityDry
    : h > humidityHumidAbove
    ? l.humidityHumid
    : l.humidityComfortable;

String pressureLabel(AppLocalizations l, double mb) => mb < pressureLowBelow
    ? l.pressureLow
    : mb > pressureHighAbove
    ? l.pressureHigh
    : l.pressureNormal;

String visibilityLabel(AppLocalizations l, double km) => km < 1
    ? l.visPoor
    : km < 4
    ? l.visFair
    : km < 10
    ? l.visGood
    : l.visExcellent;

const _uvColors = [
  Color(0xFF5BBF7A),
  Color(0xFFE8C93D),
  Color(0xFFE8A33D),
  Color(0xFFE0604A),
  Color(0xFF9B5BC0),
];
const _humidityColors = [
  Color(0xFFE8C98A),
  Color(0xFF8CCBF5),
  Color(0xFF3F7FD6),
];
const _pressureColors = [
  Color(0xFF7FA6D9),
  Color(0xFFDDE6F2),
  Color(0xFFE8B86A),
];
const _visibilityColors = [Color(0xFF6B7A90), Color(0xFFDDE6F2)];

/// `12.0` -> `"12"`, `3.333` -> `"3.3"`.
String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

double _unit(double v) => v.clamp(0.0, 1.0).toDouble();

/// 2-up card in the "big number" layout: label top-start, one dominant
/// value with an optional range bar, then a bottom row with a secondary
/// line and a state pill.
class MetricCard extends StatelessWidget {
  final Glyph glyph;
  final _Metric Function(AppLocalizations l) _build;

  const MetricCard._(this.glyph, this._build, {super.key});

  MetricCard.aqi(AirQuality? air, {Key? key})
    : this._(Glyph.air, (l) {
        final epa = air?.epaIndex;
        if (epa == null) return _Metric(l.airQuality, '—', info: l.noData);
        final pm = air!.pm25;
        return _Metric(
          l.airQuality,
          '$epa',
          info: pm == null ? '' : 'PM2.5 ${pm.toStringAsFixed(1)}',
          pill: aqiLabel(l, epa),
          scale: _Scale(_unit((epa - 1) / 5), [
            for (var i = 1; i <= 6; i++) aqiColor(i),
          ]),
        );
      }, key: key);

  /// [peak] is today's forecast maximum; shown when it is above [uv].
  MetricCard.uv(double uv, {double? peak, Key? key})
    : this._(
        Glyph.uv,
        (l) => _Metric(
          l.uvIndex,
          '${uv.round()}',
          info: peak != null && peak.round() > uv.round()
              ? l.uvPeak('${peak.round()}')
              : '',
          pill: uv < uvModerateFrom
              ? l.uvLow
              : uv <= uvHighAbove
              ? l.uvModerate
              : l.uvHigh,
          scale: _Scale(_unit(uv / 11), _uvColors),
        ),
        key: key,
      );

  MetricCard.wind(CurrentWeather c, WindUnit unit, {Key? key})
    : this._(Glyph.wind, (l) {
        String fmt(double kph) {
          final v = convertWind(kph, unit);
          return unit == WindUnit.ms
              ? v.toStringAsFixed(1)
              : v.round().toString();
        }

        return _Metric(
          l.wind,
          fmt(c.windKph),
          unit: windUnitText(l, unit),
          info: l.gusts(fmt(c.gustKph)),
          pill: c.windDir.isEmpty ? '' : windDirText(l, c.windDir),
          // The API gives the direction the wind comes FROM; the arrow
          // points where it blows to.
          pillLeading: c.windDir.isEmpty ? null : _WindArrow(c.windDegree),
        );
      }, key: key);

  MetricCard.humidity(CurrentWeather c, TempUnit unit, {Key? key})
    : this._(
        Glyph.humidity,
        (l) => _Metric(
          l.humidity,
          '${c.humidity}',
          unit: l.unitPercent,
          info: l.dewPoint(roundedTemp(convertTemp(c.dewPointC, unit))),
          pill: humidityLabel(l, c.humidity),
          scale: _Scale(_unit(c.humidity / 100), _humidityColors),
        ),
        key: key,
      );

  MetricCard.pressure(double mb, {Key? key})
    : this._(
        Glyph.pressure,
        (l) => _Metric(
          l.pressure,
          '${mb.round()}',
          unit: l.unitMb,
          info: l.pressureInfo((mb * 0.02953).toStringAsFixed(2)),
          pill: pressureLabel(l, mb),
          scale: _Scale(_unit((mb - 980) / (1040 - 980)), _pressureColors),
        ),
        key: key,
      );

  MetricCard.visibility(double km, {Key? key})
    : this._(
        Glyph.visibility,
        (l) => _Metric(
          l.visibility,
          _num(km),
          unit: l.unitKm,
          info: l.visInfo(_num((km * 0.621371 * 10).round() / 10)),
          pill: visibilityLabel(l, km),
          scale: _Scale(_unit(km / 10), _visibilityColors),
        ),
        key: key,
      );

  @override
  Widget build(BuildContext context) {
    final m = _build(AppLocalizations.of(context));
    return GlassCard(
      title: m.title,
      glyph: glyph,
      footer: CardFooter(
        info: m.info,
        pill: m.pill,
        pillLeading: m.pillLeading,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BigValue(m.value, unit: m.unit),
          if (m.scale != null) ...[
            const SizedBox(height: 10),
            ScaleBar(position: m.scale!.position, colors: m.scale!.colors),
          ],
        ],
      ),
    );
  }
}

/// Thin gradient track with a marker at [position] (0 = start, 1 = end;
/// follows the reading direction).
class ScaleBar extends StatelessWidget {
  final double position;
  final List<Color> colors;
  const ScaleBar({super.key, required this.position, required this.colors});

  static const _track = 5.0, _marker = 11.0;

  @override
  Widget build(BuildContext context) {
    final p = SkyPalette.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Align (not LayoutBuilder) places the marker, so the bar still works
    // inside IntrinsicHeight (paired cards).
    return SizedBox(
      height: _marker,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: (_marker - _track) / 2,
            height: _track,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_track),
                gradient: LinearGradient(
                  colors: rtl ? colors.reversed.toList() : colors,
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional(position * 2 - 1, 0),
            child: SizedBox.square(
              dimension: _marker,
              child: DecoratedBox(
                key: const ValueKey('scaleMarker'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: p.glassLine, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindArrow extends StatelessWidget {
  /// Meteorological direction the wind comes from, in degrees.
  final int fromDegree;
  const _WindArrow(this.fromDegree);

  @override
  Widget build(BuildContext context) => Transform.rotate(
    key: const ValueKey('windArrow'),
    angle: (fromDegree + 180) * math.pi / 180,
    child: LineIconBox(
      shape: _arrow,
      size: 13,
      color: SkyPalette.of(context).ink,
    ),
  );
}

/// North-pointing navigation arrow on the 24 grid.
const _arrow = LineShape(['M12 3l7 18-7-4.5L5 21z']);
