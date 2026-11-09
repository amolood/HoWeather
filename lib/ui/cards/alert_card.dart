import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/alerts.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../icons/glyphs.dart';
import '../sky/sky_palette.dart';
import '../typography.dart';
import 'glass_card.dart';

enum _State { ready, translated, translating, original }

/// An alert as it is shown: in the app language when possible.
class _Shown {
  final WeatherAlert alert;
  final _State state;
  const _Shown(this.alert, this.state);
}

/// Official weather alerts for the city, shown in the app's language.
/// Alerts arrive in the issuing agency's language (e.g. Persian marine
/// warnings); those are translated on device. Collapsed: the most severe
/// alert and how many more there are. Tap to read them all.
class AlertCard extends ConsumerStatefulWidget {
  final List<WeatherAlert> alerts;
  const AlertCard(this.alerts, {super.key});

  @override
  ConsumerState<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends ConsumerState<AlertCard> {
  var _open = false;

  _Shown _resolve(WeatherAlert a, String lang) {
    if (alertMatchesLanguage(a, lang)) return _Shown(a, _State.ready);
    return ref
        .watch(translatedAlertProvider((a, lang)))
        .when(
          data: (t) => _Shown(t, _State.translated),
          loading: () => _Shown(a, _State.translating),
          error: (_, _) => _Shown(a, _State.original),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = SkyPalette.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final alerts = [...widget.alerts]
      ..sort((a, b) => (isSevereAlert(b) ? 1 : 0) - (isSevereAlert(a) ? 1 : 0));
    final shown = [for (final a in alerts) _resolve(a, lang)];
    final first = shown.first;

    // Untranslated foreign text never becomes a title.
    String title(_Shown s) {
      final a = s.alert;
      if (s.state == _State.translating || s.state == _State.original) {
        return l.weatherAlert;
      }
      if (a.event.isNotEmpty) return a.event;
      return a.headline.isNotEmpty ? a.headline : l.weatherAlert;
    }

    final caption = AppType.caption.copyWith(color: p.inkSoft);
    final note = caption.copyWith(fontWeight: FontWeight.w600);
    final titleStyle = AppType.body.copyWith(
      color: p.ink,
      fontWeight: FontWeight.w600,
    );

    Widget sign(WeatherAlert a, double size) => Image.asset(
      isSevereAlert(a)
          ? 'assets/icons/alert_red.webp'
          : 'assets/icons/alert_yellow.webp',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );

    List<Widget> body(_Shown s) {
      if (s.state == _State.translating) {
        return [const SizedBox(height: 8), Text(l.translating, style: note)];
      }
      final a = s.alert;
      final text = [
        if (a.headline != title(s)) a.headline,
        a.desc,
      ].where((t) => t.isNotEmpty).join('\n\n');
      if (text.isEmpty) return const [];
      return [
        const SizedBox(height: 8),
        if (s.state == _State.original) ...[
          Text(l.alertOriginalText, style: note),
          const SizedBox(height: 4),
        ],
        Text(
          text,
          textDirection: isRtlText(text)
              ? TextDirection.rtl
              : TextDirection.ltr,
          style: caption.copyWith(height: 1.4),
        ),
        if (s.state == _State.translated) ...[
          const SizedBox(height: 6),
          Text(
            l.translatedAutomatically,
            style: caption.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ];
    }

    final subtitle = switch (first.state) {
      _State.translating => l.translating,
      _State.original => l.translationUnavailable,
      _ => first.alert.headline != title(first) ? first.alert.headline : '',
    };

    return Semantics(
      button: true,
      expanded: _open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _open = !_open),
        child: GlassCard(
          key: const ValueKey('alertCard'),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.topStart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sign(first.alert, 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title(first), style: titleStyle),
                          if (!_open && subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: isRtlText(subtitle)
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              style: caption,
                            ),
                          ],
                          if (!_open && shown.length > 1) ...[
                            const SizedBox(height: 4),
                            Text(l.alertsMore(shown.length - 1), style: note),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // The chevron glyph points right; a quarter turn points
                    // it down (closed), three quarters up (open).
                    AnimatedRotation(
                      turns: _open ? 0.75 : 0.25,
                      duration: const Duration(milliseconds: 200),
                      child: GlyphView(
                        Glyph.chevron,
                        size: 18,
                        color: p.inkSoft,
                      ),
                    ),
                  ],
                ),
                if (_open)
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) ...[
                      const SizedBox(height: 12),
                      Divider(height: 1, color: p.glassLine),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          sign(shown[i].alert, 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(title(shown[i]), style: titleStyle),
                          ),
                        ],
                      ),
                    ],
                    ...body(shown[i]),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
