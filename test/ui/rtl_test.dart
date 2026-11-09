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
import 'package:howeather/ui/home/home_screen.dart';
import 'package:howeather/ui/theme.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRepo extends Mock implements WeatherRepository {}

class DeniedLocation implements LocationService {
  @override
  Future<LocationOutcome> current() async => const LocationDenied();

  @override
  Future<void> openSettings() async {}
}

void main() {
  setUpAll(() {
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
    registerFallbackValue(
      const City(id: 'x', name: 'x', region: '', country: '', lat: 1, lon: 2),
    );
    registerFallbackValue(Duration.zero);
  });

  tearDown(() {
    final b = TestWidgetsFlutterBinding.instance;
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets('Arabic home is RTL and scrolls without overflow at 360x780', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;

    const london = City(
      id: '51.5,-0.12',
      name: 'London',
      region: '',
      country: 'UK',
      lat: 51.5,
      lon: -0.12,
    );
    final bundle = mapForecast(
      jsonDecode(File('test/fixtures/forecast_london.json').readAsStringSync())
          as Map<String, dynamic>,
      fetchedAt: DateTime.utc(2026, 11, 9, 17, 40),
    );
    final repo = MockRepo();
    when(
      () => repo.load(
        any(),
        lang: any(named: 'lang'),
        maxAge: any(named: 'maxAge'),
        force: any(named: 'force'),
      ),
    ).thenAnswer((_) async => WeatherResult(bundle));
    SharedPreferences.setMockInitialValues({
      'cities': jsonEncode([london.toJson()]),
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          prefsStoreProvider.overrideWithValue(PrefsStore(prefs)),
          weatherRepositoryProvider.overrideWithValue(repo),
          locationServiceProvider.overrideWithValue(DeniedLocation()),
          localeProvider.overrideWith(() => LocaleNotifier(const Locale('ar'))),
          clockProvider.overrideWithValue(
            () => DateTime.utc(2026, 11, 9, 17, 40),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en'), Locale('ar')],
          locale: const Locale('ar'),
          theme: buildTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(HomeScreen))),
      TextDirection.rtl,
    );
    expect(find.text('توقعات كل ساعة'), findsOneWidget);

    final list = find.byType(ListView).first;
    for (var i = 0; i < 8; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
