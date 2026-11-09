import 'package:flutter/material.dart';

import '../../domain/life_index.dart';
import '../../l10n/gen/app_localizations.dart';
import '../icons/glyphs.dart';
import '../theme.dart';
import '../sky/sky_palette.dart';
import 'glass_card.dart';

/// Localized text for a [LifeIndex.key] (a member of [lifeIndexKeys]).
String lifeIndexText(AppLocalizations l, String key) => switch (key) {
  'dressWarm' => l.dressWarm,
  'dressLight' => l.dressLight,
  'dressCool' => l.dressCool,
  'carWashGood' => l.carWashGood,
  'carWashPoor' => l.carWashPoor,
  'sportIdeal' => l.sportIdeal,
  'sportPoor' => l.sportPoor,
  'umbrellaYes' => l.umbrellaYes,
  'umbrellaNo' => l.umbrellaNo,
  'uvLow' => l.uvLow,
  'uvModerate' => l.uvModerate,
  'uvHigh' => l.uvHigh,
  'allergyLow' => l.allergyLow,
  'allergyModerate' => l.allergyModerate,
  'allergyHigh' => l.allergyHigh,
  _ => '',
};

String lifeKindLabel(AppLocalizations l, LifeKind k) => switch (k) {
  LifeKind.dress => l.lifeDress,
  LifeKind.carWash => l.lifeCarWash,
  LifeKind.sport => l.lifeSport,
  LifeKind.umbrella => l.lifeUmbrella,
  LifeKind.sunCream => l.lifeSunCream,
  LifeKind.allergy => l.lifeAllergy,
};

/// 3 x 2 grid of daily-brief tiles.
class BriefCard extends StatelessWidget {
  final List<LifeIndex> indices;
  const BriefCard(this.indices, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = [
      for (var i = 0; i < indices.length; i += 3)
        indices.sublist(i, i + 3 > indices.length ? indices.length : i + 3),
    ];
    return GlassCard(
      title: l.dailyBrief,
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: i < rows[r].length
                          ? BriefTile(rows[r][i])
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BriefTile extends StatelessWidget {
  final LifeIndex index;
  const BriefTile(this.index, {super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = SkyPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: p.pill,
        borderRadius: BorderRadius.circular(AppTokens.radiusTile),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: 0.85,
            child: GlyphView(
              Glyph.values.byName(index.kind.name),
              size: 24,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            lifeKindLabel(l, index.kind),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: p.inkSoft),
          ),
          const SizedBox(height: 5),
          Text(
            lifeIndexText(l, index.key),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
