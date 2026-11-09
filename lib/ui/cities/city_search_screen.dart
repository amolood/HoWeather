import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prefs_store.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../home/city_page.dart' show weatherErrorText;
import '../icons/glyphs.dart';

const _debounce = Duration(milliseconds: 350);
const _minChars = 2;

/// Search-as-you-type city lookup; tapping a result saves it and jumps to it.
class CitySearchScreen extends ConsumerStatefulWidget {
  const CitySearchScreen({super.key});

  @override
  ConsumerState<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends ConsumerState<CitySearchScreen> {
  Timer? _timer;
  int _token = 0; // identifies the latest query; older responses are dropped
  List<City>? _results;
  Object? _error;
  bool _loading = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _timer?.cancel();
    final token = ++_token;
    final q = text.trim();
    if (q.length < _minChars) {
      setState(() {
        _results = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _timer = Timer(_debounce, () => _search(q, token));
  }

  Future<void> _search(String q, int token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final found = await ref.read(weatherRepositoryProvider).search(q);
      if (!mounted || token != _token) return;
      setState(() {
        _results = found;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || token != _token) return;
      setState(() {
        _results = null;
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _pick(City c) async {
    final notifier = ref.read(citiesProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final limitText = AppLocalizations.of(context).cityLimitReached;
    try {
      await notifier.add(c);
    } on CityLimitException {
      messenger.showSnackBar(SnackBar(content: Text(limitText)));
      return;
    }
    if (!mounted) return;
    final list = ref.read(citiesProvider).value ?? const <City>[];
    final i = list.indexWhere((x) => x.id == c.id);
    if (i >= 0) ref.read(pageIndexProvider.notifier).set(i);
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final saved = {
      for (final c in ref.watch(citiesProvider).value ?? const <City>[]) c.id,
    };
    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(weatherErrorText(l, _error!)));
    } else if (_results == null) {
      body = const SizedBox.shrink();
    } else if (_results!.isEmpty) {
      body = Center(child: Text(l.noResults));
    } else {
      body = ListView(
        children: [
          for (final c in _results!)
            ListTile(
              title: Text(
                [
                  for (final part in [c.name, c.region, c.country])
                    if (part.isNotEmpty)
                      placeName(ref, part, Localizations.localeOf(context)),
                ].join(l.listSeparator),
              ),
              trailing: saved.contains(c.id)
                  ? const GlyphView(Glyph.check, size: 22)
                  : null,
              onTap: saved.contains(c.id)
                  ? () => Navigator.of(context).pop()
                  : () => _pick(c),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: TextField(
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
          ),
        ),
      ),
      body: body,
    );
  }
}
