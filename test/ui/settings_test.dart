import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/prefs_store.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/l10n/gen/app_localizations.dart';
import 'package:howeather/state/providers.dart';
import 'package:howeather/ui/settings/settings_screen.dart';
import 'package:howeather/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('switching to F updates settingsProvider and persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = PrefsStore(await SharedPreferences.getInstance());
    final container = ProviderContainer(
      overrides: [
        prefsStoreProvider.overrideWithValue(store),
        localeProvider.overrideWith(() => LocaleNotifier(const Locale('en'))),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en'), Locale('ar')],
          locale: const Locale('en'),
          theme: buildTheme(Brightness.light),
          home: const SettingsScreen(),
        ),
      ),
    );
    expect(container.read(settingsProvider).temp, TempUnit.c);

    await tester.tap(find.text('°F'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).temp, TempUnit.f);
    expect(store.loadSettings(const Locale('en')).temp, TempUnit.f);

    await tester.ensureVisible(find.text('3 h'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 h'));
    await tester.pumpAndSettle();
    expect(
      store.loadSettings(const Locale('en')).refresh,
      const Duration(hours: 3),
    );

    await tester.scrollUntilVisible(
      find.text('Weather data by WeatherAPI.com'),
      200,
    );
    expect(find.text('Weather data by WeatherAPI.com'), findsOneWidget);
  });

  testWidgets('choosing Arabic switches the app locale and persists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = PrefsStore(await SharedPreferences.getInstance());
    final container = ProviderContainer(
      overrides: [
        prefsStoreProvider.overrideWithValue(store),
        localeProvider.overrideWith(() => LocaleNotifier(const Locale('en'))),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en'), Locale('ar')],
          locale: const Locale('en'),
          theme: buildTheme(Brightness.light),
          home: const SettingsScreen(),
        ),
      ),
    );
    expect(find.text('Language'), findsOneWidget);
    expect(container.read(appLocaleProvider), const Locale('en'));

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).language, AppLanguage.ar);
    expect(container.read(appLocaleProvider), const Locale('ar'));
    expect(store.loadSettings(const Locale('en')).language, AppLanguage.ar);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(container.read(appLocaleProvider), const Locale('en'));
  });
}
