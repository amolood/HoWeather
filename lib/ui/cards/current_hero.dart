import 'package:flutter/material.dart';

import '../../data/prefs_store.dart';
import '../../domain/models.dart';
import '../../domain/units.dart';
import '../../l10n/gen/app_localizations.dart';
import '../icons/glyphs.dart';
import '../sky/sky_palette.dart';
import '../typography.dart';
import 'glass_card.dart';
import 'metric_card.dart';

/// Big current temperature over the sky, in the "big number" layout:
/// condition label, giant temperature (small top-aligned degree sign), then
/// a bottom row with high/low and feels-like at the start and the AQI pill
/// at the end. Text is always white (sky palette) with a soft shadow.
class CurrentHero extends StatelessWidget {
  final WeatherBundle bundle;
  final Settings settings;
  const CurrentHero(this.bundle, this.settings, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = SkyPalette.of(context);
    final c = bundle.current;
    String t(double v) => roundedTemp(convertTemp(v, settings.temp));
    final today = bundle.daily.isEmpty ? null : bundle.daily.first;
    final epa = c.air?.epaIndex;
    final temp = '${convertTemp(c.tempC, settings.temp).round()}';
    TextStyle ink(TextStyle s) =>
        s.copyWith(color: p.ink, shadows: SkyPalette.textShadow);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(c.condition.text, style: ink(AppType.title)),
          Semantics(
            label: t(c.tempC),
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              // Number first, degree after it, in every locale ("9°").
              child: Row(
                textDirection: TextDirection.ltr,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(temp, style: ink(AppType.display)),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('°', style: ink(AppType.displayUnit)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (today != null)
                      Text(
                        '${l.high(t(today.maxC))} · ${l.low(t(today.minC))}',
                        style: ink(AppType.body),
                      ),
                    Text(
                      l.feelsLike(t(c.feelsLikeC)),
                      style: ink(AppType.body),
                    ),
                  ],
                ),
              ),
              if (epa != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: SkyPill(
                    '$epa · ${aqiLabel(l, epa)}',
                    key: const ValueKey('aqiPill'),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: aqiColor(epa),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GlyphView(Glyph.air, size: 14, color: p.ink),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
