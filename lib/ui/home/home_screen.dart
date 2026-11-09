import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/condition_map.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../icons/glyphs.dart';
import '../sky/sky_background.dart';
import '../sky/sky_palette.dart';
import '../theme.dart';
import '../typography.dart';
import 'city_page.dart';
import 'empty_state.dart';

/// Swipeable pages over the saved cities, on top of the visible city's sky.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late final PageController _pages;

  /// 0 = top bar transparent, 1 = content has scrolled under it.
  final _barFill = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: ref.read(pageIndexProvider));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    _barFill.dispose();
    super.dispose();
  }

  City? get _visibleCity {
    final cities = ref.read(citiesProvider).value ?? const <City>[];
    if (cities.isEmpty) return null;
    return cities[_clamp(ref.read(pageIndexProvider), cities.length)];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final city = _visibleCity;
    // Non-forced: the repository's cache freshness decides whether to fetch.
    if (city != null) ref.invalidate(weatherProvider(city), asReload: true);
  }

  static int _clamp(int i, int length) => i.clamp(0, length - 1);

  @override
  Widget build(BuildContext context) {
    ref.listen(pageIndexProvider, (_, next) {
      if (_pages.hasClients && _pages.page?.round() != next) {
        _pages.jumpToPage(next);
      }
    });
    final citiesState = ref.watch(citiesProvider);
    // A failed cities load falls back to the empty state, never a blank screen.
    final cities =
        citiesState.value ?? (citiesState.hasError ? const <City>[] : null);
    final Widget body;
    var scene = SkyScene.clearDay;
    if (cities == null) {
      body = const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (cities.isEmpty) {
      body = const SafeArea(child: EmptyState());
    } else {
      final raw = ref.watch(pageIndexProvider);
      final index = _clamp(raw, cities.length);
      if (index != raw) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(pageIndexProvider.notifier).set(index);
        });
      }
      final city = cities[index];
      final condition = ref
          .watch(weatherProvider(city))
          .value
          ?.bundle
          .current
          .condition;
      if (condition != null) scene = sceneFor(condition);
      final media = MediaQuery.of(context);
      body = NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) {
          if (n.metrics.axis == Axis.vertical) {
            _barFill.value = (n.metrics.pixels / _fadeDistance).clamp(0, 1);
          }
          return false;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pages scroll under the top bar; their lists start below it.
            MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(
                  top: media.padding.top + _TopBar.height,
                ),
              ),
              child: PageView(
                controller: _pages,
                onPageChanged: (i) {
                  _barFill.value = 0;
                  ref.read(pageIndexProvider.notifier).set(i);
                },
                children: [
                  for (var i = 0; i < cities.length; i++)
                    CityPage(
                      cities[i],
                      key: ValueKey(cities[i].id),
                      dots: cities.length > 1
                          ? _PageDots(cities.length, i)
                          : null,
                    ),
                ],
              ),
            ),
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: _TopBar(city, fill: _barFill),
            ),
          ],
        ),
      );
    }
    final palette = SkyPalette.forScene(scene);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: KeyedSubtree(
              key: ValueKey(scene),
              child: SkyBackground(scene),
            ),
          ),
          SkyPaletteScope(palette: palette, child: body),
        ],
      ),
    );
  }
}

/// Content scroll distance over which the top bar's fill fades in.
const _fadeDistance = 24.0;

class _TopBar extends ConsumerWidget {
  /// Height below the status bar.
  static const height = 56.0;

  final City city;
  final ValueListenable<double> fill;
  const _TopBar(this.city, {required this.fill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = SkyPalette.of(context);
    final name = city.isCurrentLocation && city.name.isEmpty
        ? l.myLocation
        : city.name;
    final nav = Navigator.of(context);
    final top = MediaQuery.paddingOf(context).top;
    // Solid under the whole bar, then a short fade below it so content
    // scrolling up never shows directly behind the city name.
    const tail = 20.0;
    final solidTo = (top + height) / (top + height + tail);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: -tail,
          child: ValueListenableBuilder<double>(
            valueListenable: fill,
            builder: (context, v, _) => Opacity(
              key: const ValueKey('topBarFill'),
              opacity: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.barFill,
                      p.barFill,
                      p.barFill.withValues(alpha: 0),
                    ],
                    stops: [0, solidTo, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: top),
          child: SizedBox(
            key: const ValueKey('topBar'),
            height: height,
            child: IconTheme(
              data: IconThemeData(color: p.ink),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppTokens.gutter,
                  end: 4,
                ),
                child: Row(
                  children: [
                    if (city.isCurrentLocation) ...[
                      const GlyphView(
                        Glyph.pin,
                        key: ValueKey('locationPin'),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        // City names come in English; shown translated.
                        placeName(ref, name, Localizations.localeOf(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.title.copyWith(
                          color: p.ink,
                          fontWeight: FontWeight.w600,
                          shadows: SkyPalette.textShadow,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l.searchCity,
                      onPressed: () => nav.pushNamed('/search'),
                      icon: const GlyphView(Glyph.search, size: 22),
                    ),
                    IconButton(
                      tooltip: l.cities,
                      onPressed: () => nav.pushNamed('/cities'),
                      icon: const GlyphView(Glyph.menu, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count, index;
  const _PageDots(this.count, this.index);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              key: ValueKey('pageDot-$i'),
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == index ? Colors.white : Colors.white38,
              ),
            ),
        ],
      ),
    );
  }
}
