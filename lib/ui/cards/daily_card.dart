import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/prefs_store.dart';
import '../../domain/condition_map.dart';
import '../../domain/models.dart';
import '../../domain/units.dart';
import '../../l10n/gen/app_localizations.dart';
import '../icons/wx_icons.dart';
import '../sky/sky_palette.dart';
import 'glass_card.dart';

/// One row per returned day; the range bars share a min/max scale across
/// all shown days. The first row is labelled "Today" only when [firstIsToday].
class DailyCard extends StatelessWidget {
  final List<DailyPoint> days;
  final Settings settings;
  final bool firstIsToday;
  const DailyCard(
    this.days,
    this.settings, {
    super.key,
    this.firstIsToday = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final line = SkyPalette.of(context).glassLine;
    final lo = days.isEmpty ? 0.0 : days.map((d) => d.minC).reduce(math.min);
    final hi = days.isEmpty ? 0.0 : days.map((d) => d.maxC).reduce(math.max);
    return GlassCard(
      title: l.forecastDays(days.length),
      child: Column(
        children: [
          for (var i = 0; i < days.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: line)),
              ),
              child: DailyRow(
                day: days[i],
                name: i == 0 && firstIsToday
                    ? l.today
                    : DateFormat.E(locale).format(days[i].date),
                unit: settings.temp,
                scaleMin: lo,
                scaleMax: hi,
              ),
            ),
        ],
      ),
    );
  }
}

class DailyRow extends StatelessWidget {
  final DailyPoint day;
  final String name;
  final TempUnit unit;
  final double scaleMin, scaleMax;
  const DailyRow({
    super.key,
    required this.day,
    required this.name,
    required this.unit,
    required this.scaleMin,
    required this.scaleMax,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkyPalette.of(context);
    final soft = p.inkSoft;
    const tab = [FontFeature.tabularFigures()];
    String t(double c) => roundedTemp(convertTemp(c, unit));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                name,
                style: TextStyle(
                  color: p.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          WxIconView(iconFor(day.condition), size: 30, color: p.ink),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              t(day.minC),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 15, color: soft, fontFeatures: tab),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RangeBar(
              min: day.minC,
              max: day.maxC,
              scaleMin: scaleMin,
              scaleMax: scaleMax,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              t(day.maxC),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: p.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFeatures: tab,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Track with a gradient segment from [min] to [max] on the
/// [scaleMin]..[scaleMax] scale. Mirrors in RTL.
class RangeBar extends StatelessWidget {
  final double min, max, scaleMin, scaleMax;
  const RangeBar({
    super.key,
    required this.min,
    required this.max,
    required this.scaleMin,
    required this.scaleMax,
  });

  @override
  Widget build(BuildContext context) {
    final line = SkyPalette.of(context).glassLine;
    final span = scaleMax - scaleMin == 0 ? 1.0 : scaleMax - scaleMin;
    final start = ((min - scaleMin) / span).clamp(0.0, 1.0);
    final end = ((max - scaleMin) / span).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final width = math.min(w, math.max(5.0, (end - start) * w));
        final left = math.min(start * w, w - width);
        return Container(
          height: 5,
          decoration: BoxDecoration(
            color: line,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                start: left,
                width: width,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: const [
                        Color(0xFF6FB1E6),
                        Color(0xFFFFD264),
                        Color(0xFFFF9A56),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
