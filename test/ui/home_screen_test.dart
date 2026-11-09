import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/location_service.dart';
import 'package:howeather/data/prefs_store.dart';
import 'package:howeather/data/weather_mapper.dart';
import 'package:howeather/data/weather_repository.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/l10n/gen/app_localizations.dart';
import 'package:howeather/state/providers.dart';
import 'package:howeather/ui/cards/current_hero.dart';
import 'package:howeather/ui/home/city_page.dart'
    show entranceDuration, entranceStagger;
import 'package:howeather/ui/home/empty_state.dart';
import 'package:howeather/ui/home/home_screen.dart';
import 'package:howeather/ui/theme.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRepo extends Mock implements WeatherRepository {}

class FakeLocation implements LocationService {
  int calls = 0;
  @override
  Future<LocationOutcome> current() async {
    calls++;
    return const LocationDenied();
  }

  int settingsOpened = 0;
  @override
  Future<void> openSettings() async => settingsOpened++;
}

City city(String id, String name) =>
    City(id: id, name: name, region: '', country: '', lat: 1, lon: 2);

final paris = city('48.85,2.35', 'Paris');
final cairo = city('30.04,31.24', 'Cairo');

/// The vertical card list's scrollable (not the hourly strip or PageView).
final cards = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

final fixtureNow = DateTime.utc(2026, 11, 9, 17, 40);

final bundle = mapForecast(
  jsonDecode(File('test/fixtures/forecast_london.json').readAsStringSync())
      as Map<String, dynamic>,
  fetchedAt: DateTime.utc(2026, 11, 9, 17, 40),
);

When<Future<WeatherResult>> whenLoad(MockRepo r) => when(
  () => r.load(
    any(),
    lang: any(named: 'lang'),
    maxAge: any(named: 'maxAge'),
    force: any(named: 'force'),
  ),
);

/// Cities that never finish loading.
class PendingCities extends CitiesNotifier {
  @override
  Future<List<City>> build() => Completer<List<City>>().future;
}

Future<void> pumpHome(
  WidgetTester tester, {
  required List<City> saved,
  required MockRepo repo,
  FakeLocation? location,
  bool citiesPending = false,
  bool settle = true,
  bool animate = false,
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues({
    if (saved.isNotEmpty)
      'cities': jsonEncode([for (final c in saved) c.toJson()]),
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        prefsStoreProvider.overrideWithValue(PrefsStore(prefs)),
        weatherRepositoryProvider.overrideWithValue(repo),
        locationServiceProvider.overrideWithValue(location ?? FakeLocation()),
        localeProvider.overrideWith(() => LocaleNotifier(const Locale('en'))),
        if (citiesPending) citiesProvider.overrideWith(PendingCities.new),
        clockProvider.overrideWithValue(() => now ?? fixtureNow),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 900),
          padding: const EdgeInsets.only(top: 24),
          disableAnimations: !animate,
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en'), Locale('ar')],
          locale: const Locale('en'),
          theme: buildTheme(Brightness.light),
          routes: {
            '/search': (_) => const Scaffold(body: Text('search-route')),
            '/cities': (_) => const Scaffold(body: Text('cities-route')),
          },
          home: const HomeScreen(),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
    registerFallbackValue(paris);
    registerFallbackValue(Duration.zero);
  });

  testWidgets('no cities -> empty state with both buttons', (tester) async {
    final loc = FakeLocation();
    await pumpHome(tester, saved: const [], repo: MockRepo(), location: loc);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No cities yet'), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Search a city'), findsOneWidget);

    final before = loc.calls;
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(loc.calls, before + 1);
    expect(
      find.text('Location access is off. Allow it in Settings.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(loc.settingsOpened, 1);

    await tester.tap(find.text('Search a city'));
    await tester.pumpAndSettle();
    expect(find.text('search-route'), findsOneWidget);
  });

  testWidgets('stale bundle: past hours/days dropped, labels follow clock', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    // One day later: yesterday's row is gone and the 10th is "Today".
    await pumpHome(
      tester,
      saved: [paris],
      repo: repo,
      now: fixtureNow.add(const Duration(days: 1)),
    );
    await tester.scrollUntilVisible(find.text('Today'), 200, scrollable: cards);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Now'), findsNothing);
    expect(
      find.text('${bundle.daily.length - 1}-DAY FORECAST'),
      findsOneWidget,
    );
  });

  testWidgets('clock behind the data: no Now/Today labels', (tester) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await pumpHome(
      tester,
      saved: [paris],
      repo: repo,
      now: DateTime.utc(2026, 11, 8, 12),
    );
    expect(find.text('${bundle.daily.length}-DAY FORECAST'), findsOneWidget);
    expect(find.text('Now'), findsNothing);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('fresh bundle shows Now and Today', (tester) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await pumpHome(tester, saved: [paris], repo: repo);
    expect(find.text('Now'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Today'), 200, scrollable: cards);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('cities loading -> centered progress indicator', (tester) async {
    await pumpHome(
      tester,
      saved: const [],
      repo: MockRepo(),
      citiesPending: true,
      settle: false,
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
  });

  testWidgets('two cities -> two page dots, swipe shows second city', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await pumpHome(tester, saved: [paris, cairo], repo: repo);

    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('pageDot'),
      ),
      findsNWidgets(2),
    );
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('Cairo'), findsNothing);
    // The dots sit centered under the hero.
    final dot = tester.getRect(find.byKey(const ValueKey('pageDot-0')));
    final hero = tester.getRect(find.byType(CurrentHero));
    expect(dot.top, greaterThanOrEqualTo(hero.bottom));

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('Paris'), findsNothing);
  });

  testWidgets('stale result shows the stale label', (tester) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer(
      (_) async => WeatherResult(
        bundle,
        isStale: true,
        error: const WeatherApiException(null, 'offline'),
      ),
    );
    await pumpHome(tester, saved: [paris], repo: repo);
    await tester.scrollUntilVisible(
      find.textContaining('Showing saved data'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text("Showing saved data · You're offline"), findsOneWidget);
    expect(find.textContaining('· WeatherAPI.com'), findsOneWidget);
  });

  testWidgets('error with no cache -> retry button reloads', (tester) async {
    final repo = MockRepo();
    whenLoad(repo).thenThrow(const WeatherApiException(null, 'offline'));
    await pumpHome(tester, saved: [paris], repo: repo);

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    verify(
      () => repo.load(
        any(),
        lang: any(named: 'lang'),
        maxAge: any(named: 'maxAge'),
        force: any(named: 'force'),
      ),
    ).called(1);

    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    verify(
      () => repo.load(
        any(),
        lang: any(named: 'lang'),
        maxAge: any(named: 'maxAge'),
        force: any(named: 'force'),
      ),
    ).called(1);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('quota error (2007) with no cache -> quota message', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo)
        .thenThrow(const WeatherApiException(2007, 'API key has exceeded'));
    await pumpHome(tester, saved: [paris], repo: repo);
    expect(find.text('Monthly API quota exceeded'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('location city shows "My location" when its name is empty', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    const here = City(
      id: 'loc',
      name: '',
      region: '',
      country: '',
      lat: 1,
      lon: 2,
      isCurrentLocation: true,
    );
    await pumpHome(tester, saved: const [here], repo: repo);
    expect(find.text('My location'), findsOneWidget);
    expect(find.byKey(const ValueKey('locationPin')), findsOneWidget);
  });

  testWidgets('app resume reloads the visible city (non-forced)', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await pumpHome(tester, saved: [paris], repo: repo);
    clearInteractions(repo);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    verify(
      () => repo.load(
        paris,
        lang: any(named: 'lang'),
        maxAge: any(named: 'maxAge'),
        force: false,
      ),
    ).called(1);
  });

  Finder heroTemp() => find.descendant(
    of: find.byType(CurrentHero),
    matching: find.text('${bundle.current.tempC.round()}'),
  );

  testWidgets('hero is visible below the top bar on the first frame', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await pumpHome(tester, saved: [paris], repo: repo);
    final bar = tester.getRect(find.byKey(const ValueKey('topBar')));
    final temp = tester.getRect(heroTemp());
    expect(bar.top, greaterThanOrEqualTo(24)); // below the status bar
    expect(temp.top, greaterThanOrEqualTo(bar.bottom));
    expect(temp.bottom, lessThan(900 / 2));
    expect(
      tester.getRect(find.text(bundle.current.condition.text)).top,
      greaterThanOrEqualTo(bar.bottom),
    );
  });

  testWidgets('top bar fill fades in when content scrolls under it', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await pumpHome(tester, saved: [paris], repo: repo);
    double fill() => tester
        .widget<Opacity>(find.byKey(const ValueKey('topBarFill')))
        .opacity;
    expect(fill(), 0);
    await tester.drag(cards, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(fill(), 1);
    await tester.drag(cards, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(fill(), 0);
  });

  testWidgets('cards fade/slide in once, staggered, on first load', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await pumpHome(
      tester,
      saved: [paris],
      repo: repo,
      settle: false,
      animate: true,
    );
    for (var i = 0; i < 20 && heroTemp().evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    double opacity(int i) => tester
        .widget<FadeTransition>(find.byKey(ValueKey('entrance-$i')))
        .opacity
        .value;
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(0), greaterThan(0));
    expect(opacity(0), lessThan(1));
    expect(opacity(1), lessThan(opacity(0))); // staggered
    // Each card takes entranceDuration; the next starts one stagger later.
    // (closeTo: interval bounds are fractions of the derived total.)
    await tester.pump(entranceDuration - const Duration(milliseconds: 100));
    expect(opacity(0), closeTo(1, 1e-3));
    expect(opacity(1), lessThan(1));
    await tester.pump(entranceStagger);
    expect(opacity(1), closeTo(1, 1e-3));
    await tester.pump(const Duration(seconds: 1));
    expect(opacity(0), 1);
  });

  testWidgets('no entrance motion when animations are disabled', (
    tester,
  ) async {
    final repo = MockRepo();
    whenLoad(repo).thenAnswer((_) async => WeatherResult(bundle));
    await pumpHome(tester, saved: [paris], repo: repo, settle: false);
    for (var i = 0; i < 20 && heroTemp().evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(
      tester
          .widget<FadeTransition>(find.byKey(const ValueKey('entrance-0')))
          .opacity
          .value,
      1,
    );
  });
}
