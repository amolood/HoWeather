import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prefs_store.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../icons/glyphs.dart';
import '../theme.dart';

const appVersion = '1.0.0';

/// Settings, grouped into cards: language first (it changes everything
/// else on screen), then units, updates, appearance and about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    void update(Settings next) =>
        ref.read(settingsProvider.notifier).update(next);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settings),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.gutter,
          8,
          AppTokens.gutter,
          32,
        ),
        children: [
          _Group(
            glyph: Glyph.globe,
            title: l.language,
            children: [
              _Segments<AppLanguage>(
                key: const ValueKey('language'),
                value: s.language,
                onChanged: (v) => update(s.copyWith(language: v)),
                options: {
                  AppLanguage.system: l.languageSystem,
                  // Each language is named in itself.
                  AppLanguage.en: 'English',
                  AppLanguage.ar: 'العربية',
                },
              ),
              const SizedBox(height: 8),
              _Hint(l.languageHint),
            ],
          ),
          _Group(
            glyph: Glyph.thermometer,
            title: l.units,
            children: [
              _Label(l.temperatureUnit),
              _Segments<TempUnit>(
                key: const ValueKey('tempUnit'),
                value: s.temp,
                onChanged: (v) => update(s.copyWith(temp: v)),
                options: {
                  TempUnit.c: l.unitCelsius,
                  TempUnit.f: l.unitFahrenheit,
                },
              ),
              const SizedBox(height: 16),
              _Label(l.windUnit),
              _Segments<WindUnit>(
                key: const ValueKey('windUnit'),
                value: s.wind,
                onChanged: (v) => update(s.copyWith(wind: v)),
                options: {
                  WindUnit.kmh: l.unitKmh,
                  WindUnit.mph: l.unitMph,
                  WindUnit.ms: l.unitMs,
                },
              ),
            ],
          ),
          _Group(
            glyph: Glyph.refresh,
            title: l.autoUpdate,
            children: [
              _Segments<Duration>(
                key: const ValueKey('refresh'),
                value: s.refresh,
                onChanged: (v) => update(s.copyWith(refresh: v)),
                options: {
                  Duration.zero: l.manual,
                  for (final h in const [1, 3, 6])
                    Duration(hours: h): l.hoursShort(h),
                },
              ),
              const SizedBox(height: 8),
              _Hint(
                s.refresh == Duration.zero
                    ? l.refreshManualHint
                    : l.everyHours(s.refresh.inHours),
              ),
            ],
          ),
          _Group(
            glyph: Glyph.appearance,
            title: l.theme,
            children: [
              _Segments<ThemePref>(
                key: const ValueKey('themePref'),
                value: s.theme,
                onChanged: (v) => update(s.copyWith(theme: v)),
                options: {
                  ThemePref.system: l.themeSystem,
                  ThemePref.light: l.themeLight,
                  ThemePref.dark: l.themeDark,
                },
              ),
            ],
          ),
          _Group(
            glyph: Glyph.info,
            title: l.about,
            children: [
              _Row(l.appTitle, '${l.version} $appVersion'),
              const SizedBox(height: 12),
              _Hint(l.dataAttribution),
            ],
          ),
        ],
      ),
    );
  }
}

/// A titled glass card with a glyph badge.
class _Group extends StatelessWidget {
  final Glyph glyph;
  final String title;
  final List<Widget> children;
  const _Group({
    required this.glyph,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.cardGap),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GlyphView(glyph, size: 18, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width single-choice segmented control.
class _Segments<T> extends StatelessWidget {
  final T value;
  final ValueChanged<T> onChanged;
  final Map<T, String> options;
  const _Segments({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
    showSelectedIcon: false,
    expandedInsets: EdgeInsets.zero,
    segments: [
      for (final e in options.entries)
        ButtonSegment(
          value: e.key,
          label: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
    ],
    selected: {value},
    onSelectionChanged: (v) => onChanged(v.first),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodyLarge)),
        Text(
          value,
          style: text.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
