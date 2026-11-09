import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'HoWeather'**
  String get appTitle;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly forecast'**
  String get hourly;

  /// No description provided for @forecastDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day forecast} other{{count}-day forecast}}'**
  String forecastDays(int count);

  /// No description provided for @airQuality.
  ///
  /// In en, this message translates to:
  /// **'Air quality'**
  String get airQuality;

  /// No description provided for @uvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV index'**
  String get uvIndex;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @sunriseSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunrise & sunset'**
  String get sunriseSunset;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @dailyBrief.
  ///
  /// In en, this message translates to:
  /// **'Daily brief'**
  String get dailyBrief;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}'**
  String feelsLike(String temp);

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'H {temp}'**
  String high(String temp);

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'L {temp}'**
  String low(String temp);

  /// No description provided for @aqiGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get aqiGood;

  /// No description provided for @aqiModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get aqiModerate;

  /// No description provided for @aqiUnhealthySensitive.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy for sensitive groups'**
  String get aqiUnhealthySensitive;

  /// No description provided for @aqiUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get aqiUnhealthy;

  /// No description provided for @aqiVeryUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Very unhealthy'**
  String get aqiVeryUnhealthy;

  /// No description provided for @aqiHazardous.
  ///
  /// In en, this message translates to:
  /// **'Hazardous'**
  String get aqiHazardous;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @dewPoint.
  ///
  /// In en, this message translates to:
  /// **'Dew point {temp}'**
  String dewPoint(String temp);

  /// No description provided for @gusts.
  ///
  /// In en, this message translates to:
  /// **'Gusts {value}'**
  String gusts(String value);

  /// No description provided for @lifeDress.
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get lifeDress;

  /// No description provided for @lifeCarWash.
  ///
  /// In en, this message translates to:
  /// **'Car wash'**
  String get lifeCarWash;

  /// No description provided for @lifeSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get lifeSport;

  /// No description provided for @lifeUmbrella.
  ///
  /// In en, this message translates to:
  /// **'Umbrella'**
  String get lifeUmbrella;

  /// No description provided for @lifeSunCream.
  ///
  /// In en, this message translates to:
  /// **'Sun cream'**
  String get lifeSunCream;

  /// No description provided for @lifeAllergy.
  ///
  /// In en, this message translates to:
  /// **'Allergy'**
  String get lifeAllergy;

  /// No description provided for @dressWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm clothes'**
  String get dressWarm;

  /// No description provided for @dressLight.
  ///
  /// In en, this message translates to:
  /// **'Light layers'**
  String get dressLight;

  /// No description provided for @dressCool.
  ///
  /// In en, this message translates to:
  /// **'Cool clothes'**
  String get dressCool;

  /// No description provided for @carWashGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get carWashGood;

  /// No description provided for @carWashPoor.
  ///
  /// In en, this message translates to:
  /// **'Not ideal'**
  String get carWashPoor;

  /// No description provided for @sportIdeal.
  ///
  /// In en, this message translates to:
  /// **'Ideal'**
  String get sportIdeal;

  /// No description provided for @sportPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sportPoor;

  /// No description provided for @umbrellaYes.
  ///
  /// In en, this message translates to:
  /// **'Take one'**
  String get umbrellaYes;

  /// No description provided for @umbrellaNo.
  ///
  /// In en, this message translates to:
  /// **'Not needed'**
  String get umbrellaNo;

  /// No description provided for @uvLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get uvLow;

  /// No description provided for @uvModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get uvModerate;

  /// No description provided for @uvHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get uvHigh;

  /// No description provided for @allergyLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get allergyLow;

  /// No description provided for @allergyModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get allergyModerate;

  /// No description provided for @allergyHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get allergyHigh;

  /// No description provided for @unitKmh.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get unitKmh;

  /// No description provided for @unitMph.
  ///
  /// In en, this message translates to:
  /// **'mph'**
  String get unitMph;

  /// No description provided for @unitMs.
  ///
  /// In en, this message translates to:
  /// **'m/s'**
  String get unitMs;

  /// No description provided for @unitMb.
  ///
  /// In en, this message translates to:
  /// **'mb'**
  String get unitMb;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @unitPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get unitPercent;

  /// No description provided for @dirN.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get dirN;

  /// No description provided for @dirNNE.
  ///
  /// In en, this message translates to:
  /// **'NNE'**
  String get dirNNE;

  /// No description provided for @dirNE.
  ///
  /// In en, this message translates to:
  /// **'NE'**
  String get dirNE;

  /// No description provided for @dirENE.
  ///
  /// In en, this message translates to:
  /// **'ENE'**
  String get dirENE;

  /// No description provided for @dirE.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get dirE;

  /// No description provided for @dirESE.
  ///
  /// In en, this message translates to:
  /// **'ESE'**
  String get dirESE;

  /// No description provided for @dirSE.
  ///
  /// In en, this message translates to:
  /// **'SE'**
  String get dirSE;

  /// No description provided for @dirSSE.
  ///
  /// In en, this message translates to:
  /// **'SSE'**
  String get dirSSE;

  /// No description provided for @dirS.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dirS;

  /// No description provided for @dirSSW.
  ///
  /// In en, this message translates to:
  /// **'SSW'**
  String get dirSSW;

  /// No description provided for @dirSW.
  ///
  /// In en, this message translates to:
  /// **'SW'**
  String get dirSW;

  /// No description provided for @dirWSW.
  ///
  /// In en, this message translates to:
  /// **'WSW'**
  String get dirWSW;

  /// No description provided for @dirW.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dirW;

  /// No description provided for @dirWNW.
  ///
  /// In en, this message translates to:
  /// **'WNW'**
  String get dirWNW;

  /// No description provided for @dirNW.
  ///
  /// In en, this message translates to:
  /// **'NW'**
  String get dirNW;

  /// No description provided for @dirNNW.
  ///
  /// In en, this message translates to:
  /// **'NNW'**
  String get dirNNW;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedAt(String time);

  /// No description provided for @staleLabel.
  ///
  /// In en, this message translates to:
  /// **'Showing saved data'**
  String get staleLabel;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'WeatherAPI.com'**
  String get dataSource;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get errorOffline;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the weather'**
  String get errorGeneric;

  /// No description provided for @errorKey.
  ///
  /// In en, this message translates to:
  /// **'API key is invalid'**
  String get errorKey;

  /// No description provided for @errorQuota.
  ///
  /// In en, this message translates to:
  /// **'Monthly API quota exceeded'**
  String get errorQuota;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get errorNotFound;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search a city'**
  String get searchCity;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @noCitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No cities yet'**
  String get noCitiesTitle;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @cities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get cities;

  /// No description provided for @addCity.
  ///
  /// In en, this message translates to:
  /// **'Add city'**
  String get addCity;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a city'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get noResults;

  /// No description provided for @cityLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can save up to 10 cities'**
  String get cityLimitReached;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @temperatureUnit.
  ///
  /// In en, this message translates to:
  /// **'Temperature unit'**
  String get temperatureUnit;

  /// No description provided for @windUnit.
  ///
  /// In en, this message translates to:
  /// **'Wind speed unit'**
  String get windUnit;

  /// No description provided for @autoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto update'**
  String get autoUpdate;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @everyHours.
  ///
  /// In en, this message translates to:
  /// **'Every {n} h'**
  String everyHours(int n);

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @dataAttribution.
  ///
  /// In en, this message translates to:
  /// **'Weather data by WeatherAPI.com'**
  String get dataAttribution;

  /// No description provided for @unitCelsius.
  ///
  /// In en, this message translates to:
  /// **'°C'**
  String get unitCelsius;

  /// No description provided for @unitFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'°F'**
  String get unitFahrenheit;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access is off. Allow it in Settings.'**
  String get locationDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @humidityDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get humidityDry;

  /// No description provided for @humidityComfortable.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get humidityComfortable;

  /// No description provided for @humidityHumid.
  ///
  /// In en, this message translates to:
  /// **'Humid'**
  String get humidityHumid;

  /// No description provided for @pressureLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get pressureLow;

  /// No description provided for @pressureNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get pressureNormal;

  /// No description provided for @pressureHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get pressureHigh;

  /// No description provided for @pressureInfo.
  ///
  /// In en, this message translates to:
  /// **'{value} inHg'**
  String pressureInfo(String value);

  /// No description provided for @visPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get visPoor;

  /// No description provided for @visFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get visFair;

  /// No description provided for @visGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get visGood;

  /// No description provided for @visExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get visExcellent;

  /// No description provided for @visInfo.
  ///
  /// In en, this message translates to:
  /// **'{value} mi'**
  String visInfo(String value);

  /// No description provided for @uvPeak.
  ///
  /// In en, this message translates to:
  /// **'Today\'s peak {value}'**
  String uvPeak(String value);

  /// No description provided for @daylight.
  ///
  /// In en, this message translates to:
  /// **'Daylight {duration}'**
  String daylight(String duration);

  /// No description provided for @durationHm.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String durationHm(int h, int m);

  /// No description provided for @moonNew.
  ///
  /// In en, this message translates to:
  /// **'New moon'**
  String get moonNew;

  /// No description provided for @moonWaxingCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waxing crescent'**
  String get moonWaxingCrescent;

  /// No description provided for @moonFirstQuarter.
  ///
  /// In en, this message translates to:
  /// **'First quarter'**
  String get moonFirstQuarter;

  /// No description provided for @moonWaxingGibbous.
  ///
  /// In en, this message translates to:
  /// **'Waxing gibbous'**
  String get moonWaxingGibbous;

  /// No description provided for @moonFull.
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get moonFull;

  /// No description provided for @moonWaningGibbous.
  ///
  /// In en, this message translates to:
  /// **'Waning gibbous'**
  String get moonWaningGibbous;

  /// No description provided for @moonLastQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last quarter'**
  String get moonLastQuarter;

  /// No description provided for @moonWaningCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waning crescent'**
  String get moonWaningCrescent;

  /// No description provided for @weatherAlert.
  ///
  /// In en, this message translates to:
  /// **'Weather alert'**
  String get weatherAlert;

  /// No description provided for @alertsMore.
  ///
  /// In en, this message translates to:
  /// **'+{n} more'**
  String alertsMore(int n);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Weather descriptions and official alerts are shown in this language.'**
  String get languageHint;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get translating;

  /// No description provided for @alertOriginalText.
  ///
  /// In en, this message translates to:
  /// **'Original text'**
  String get alertOriginalText;

  /// No description provided for @translationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t translate it. Tap to read the original.'**
  String get translationUnavailable;

  /// No description provided for @translatedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Translated automatically'**
  String get translatedAutomatically;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String hoursShort(int n);

  /// No description provided for @refreshManualHint.
  ///
  /// In en, this message translates to:
  /// **'Updates only when you pull to refresh.'**
  String get refreshManualHint;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
