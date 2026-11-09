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

/// Horizontal strip of the next hours. Pass `bundle.toCityTime` so the
/// hour labels show the city's wall-clock time. The first hour is labelled
/// "Now" only when [firstIsNow].
class HourlyCard extends StatelessWidget {
  final List<HourlyPoint> hours;
  final Settings settings;
  final DateTime Function(DateTime utcInstant) toCityTime;
  final bool firstIsNow;
  const HourlyCard(
    this.hours,
    this.settings, {
    super.key,
    required this.toCityTime,
    this.firstIsNow = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final p = SkyPalette.of(context);
    final fmt = DateFormat('HH', locale);
    // Columns widen with the text scale; height shrink-wraps the content.
    final itemWidth = MediaQuery.textScalerOf(context).scale(56);
    return GlassCard(
      title: l.hourly,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < hours.length; i++)
              _hour(l, fmt, p, hours[i], i, itemWidth),
          ],
        ),
      ),
    );
  }

  Widget _hour(
    AppLocalizations l,
    DateFormat fmt,
    SkyPalette p,
    HourlyPoint h,
    int i,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            i == 0 && firstIsNow ? l.now : fmt.format(toCityTime(h.time)),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.inkSoft,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 5),
          WxIconView(iconFor(h.condition), size: 34, color: p.ink),
          const SizedBox(height: 5),
          Text(
            roundedTemp(convertTemp(h.tempC, settings.temp)),
            style: TextStyle(
              color: p.ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            h.chanceOfRain > 0 ? '${h.chanceOfRain}${l.unitPercent}' : '',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8CCBF5),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
