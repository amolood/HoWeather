import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/condition_map.dart';
import '../../domain/models.dart';
import '../../domain/units.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../cards/glass_card.dart';
import '../icons/glyphs.dart';
import '../icons/wx_icons.dart';

const _rowRadius = 18.0;

/// Saved cities: reorder, swipe to delete, tap to jump to a city.
class CitiesScreen extends ConsumerStatefulWidget {
  const CitiesScreen({super.key});

  @override
  ConsumerState<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends ConsumerState<CitiesScreen> {
  // Dismissed rows must leave the tree synchronously; the saved list updates
  // a moment later (after the prefs write).
  final _removing = <String>{};
  // Bumped when a failed delete restores a row, so it gets a fresh
  // (not dismissed) Dismissible.
  final _restored = <String, int>{};

  Future<void> _remove(City c) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorText = AppLocalizations.of(context).errorGeneric;
    setState(() => _removing.add(c.id));
    try {
      await ref.read(citiesProvider.notifier).remove(c.id);
    } catch (_) {
      if (!mounted) return;
      _restored[c.id] = (_restored[c.id] ?? 0) + 1;
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
    } finally {
      if (mounted) setState(() => _removing.remove(c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(citiesProvider).value ?? const <City>[];
    final cities = [
      for (final c in all)
        if (!_removing.contains(c.id)) c,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.cities),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: l.settings,
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const GlyphView(Glyph.settings, size: 22),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.addCity,
        onPressed: () => Navigator.of(context).pushNamed('/search'),
        child: const GlyphView(Glyph.plus, size: 24),
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: cities.length,
        onReorderItem: (from, to) =>
            ref.read(citiesProvider.notifier).move(from, to),
        itemBuilder: (context, i) {
          final c = cities[i];
          final row = _CityRow(
            c,
            onTap: () {
              ref.read(pageIndexProvider.notifier).set(i);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            handle: c.isCurrentLocation
                ? null
                : ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: GlyphView(Glyph.dragHandle, size: 22),
                    ),
                  ),
          );
          return Padding(
            key: ValueKey(c.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: c.isCurrentLocation
                ? row
                : Dismissible(
                    key: ValueKey('dismiss-${c.id}-${_restored[c.id] ?? 0}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsetsDirectional.only(end: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(_rowRadius),
                      ),
                      child: const GlyphView(
                        Glyph.trash,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (_) => _remove(c),
                    child: row,
                  ),
          );
        },
      ),
    );
  }
}

class _CityRow extends ConsumerWidget {
  final City city;
  final VoidCallback onTap;
  final Widget? handle;
  const _CityRow(this.city, {required this.onTap, this.handle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final name = city.isCurrentLocation && city.name.isEmpty
        ? l.myLocation
        : placeName(ref, city.name, locale);
    final sub = [
      for (final part in [city.region, city.country])
        if (part.isNotEmpty) placeName(ref, part, locale),
    ].join(l.listSeparator);
    final weather = ref.watch(weatherProvider(city));
    final unit = ref.watch(settingsProvider.select((s) => s.temp));
    final Widget trailing = weather.when(
      data: (r) {
        final cur = r.bundle.current;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WxIconView(iconFor(cur.condition), size: 32),
            const SizedBox(width: 8),
            Text(
              roundedTemp(convertTemp(cur.tempC, unit)),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        );
      },
      error: (_, _) => const Text('—'),
      loading: () => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(_rowRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (city.isCurrentLocation) ...[
                            const GlyphView(Glyph.pin, size: 16),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (sub.isNotEmpty)
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              trailing,
              handle ?? const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}
