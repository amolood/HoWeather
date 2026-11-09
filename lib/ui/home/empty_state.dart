import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../icons/glyphs.dart';

/// Shown when there are no saved cities (e.g. location denied on first run).
class EmptyState extends ConsumerWidget {
  const EmptyState({super.key});

  Future<void> _useMyLocation(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final location = ref.read(locationServiceProvider);
    final outcome = await ref.read(citiesProvider.notifier).refreshLocation();
    if (outcome is LocationFound) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.locationDenied),
        action: SnackBarAction(
          label: l.openSettings,
          onPressed: location.openSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.noCitiesTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/search'),
              icon: const GlyphView(Glyph.search, size: 18),
              label: Text(l.searchCity),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              onPressed: () => _useMyLocation(context, ref),
              icon: const GlyphView(Glyph.pin, size: 18),
              label: Text(l.useMyLocation),
            ),
          ],
        ),
      ),
    );
  }
}
