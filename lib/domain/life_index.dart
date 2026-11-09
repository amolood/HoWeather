import 'models.dart';

enum LifeLevel { good, fair, poor }

enum LifeKind { dress, carWash, sport, umbrella, sunCream, allergy }

/// One daily-brief entry. [key] is an l10n (ARB) key, always a member of
/// [lifeIndexKeys].
class LifeIndex {
  final LifeKind kind;
  final LifeLevel level;
  final String key;
  const LifeIndex({required this.kind, required this.level, required this.key});
}

/// Every l10n key [deriveLifeIndices] can produce. Task 11 must provide a
/// translation for each of these in both ARB files.
const List<String> lifeIndexKeys = [
  'dressWarm',
  'dressLight',
  'dressCool',
  'carWashGood',
  'carWashPoor',
  'sportIdeal',
  'sportPoor',
  'umbrellaYes',
  'umbrellaNo',
  'uvLow',
  'uvModerate',
  'uvHigh',
  'allergyLow',
  'allergyModerate',
  'allergyHigh',
];

// --- Thresholds -----------------------------------------------------------

/// Dress: feels-like below this (deg C) -> dressWarm.
const double dressWarmBelowC = 10;

/// Dress: feels-like above this (deg C) -> dressCool; between -> dressLight.
const double dressCoolAboveC = 22;

/// Car wash: poor if today's or tomorrow's rain chance (%) is at least this.
const int carWashRainPct = 40;

/// Sport: poor if rain chance (%) is at least this.
const int sportRainPct = 50;

/// Sport: poor if feels-like (deg C) is above this ...
const double sportMaxFeelsLikeC = 35;

/// ... or below this.
const double sportMinFeelsLikeC = 0;

/// Sport: poor if EPA air-quality index is at least this.
const int sportEpaIndex = 4;

/// Umbrella: yes if today's rain chance (%) is at least this.
const int umbrellaRainPct = 40;

/// Sun cream: UV below this -> low.
const double uvModerateFrom = 3;

/// Sun cream: UV above this -> high; from [uvModerateFrom] to this -> moderate.
const double uvHighAbove = 6;

/// Allergy: EPA index at least this -> moderate (fair).
const int allergyModerateEpa = 3;

/// Allergy: EPA index at least this -> high (poor).
const int allergyHighEpa = 4;

/// Allergy: wind (kph) at least this -> moderate (fair); stirs up pollen/dust.
const double allergyWindKph = 25;

/// Derives the six daily-brief indices, always in [LifeKind] order.
/// A null [tomorrow] means car wash looks at today only; a null `now.air`
/// (or null epaIndex) means air quality is ignored.
List<LifeIndex> deriveLifeIndices(
  CurrentWeather now,
  DailyPoint today,
  DailyPoint? tomorrow,
) {
  final feels = now.feelsLikeC;
  final epa = now.air?.epaIndex;

  final LifeIndex dress;
  if (feels < dressWarmBelowC) {
    dress = const LifeIndex(
      kind: LifeKind.dress,
      level: LifeLevel.fair,
      key: 'dressWarm',
    );
  } else if (feels <= dressCoolAboveC) {
    dress = const LifeIndex(
      kind: LifeKind.dress,
      level: LifeLevel.good,
      key: 'dressLight',
    );
  } else {
    dress = const LifeIndex(
      kind: LifeKind.dress,
      level: LifeLevel.fair,
      key: 'dressCool',
    );
  }

  final carRain =
      today.chanceOfRain >= carWashRainPct ||
      (tomorrow != null && tomorrow.chanceOfRain >= carWashRainPct);
  final carWash = LifeIndex(
    kind: LifeKind.carWash,
    level: carRain ? LifeLevel.poor : LifeLevel.good,
    key: carRain ? 'carWashPoor' : 'carWashGood',
  );

  final sportPoor =
      today.chanceOfRain >= sportRainPct ||
      feels > sportMaxFeelsLikeC ||
      feels < sportMinFeelsLikeC ||
      (epa != null && epa >= sportEpaIndex);
  final sport = LifeIndex(
    kind: LifeKind.sport,
    level: sportPoor ? LifeLevel.poor : LifeLevel.good,
    key: sportPoor ? 'sportPoor' : 'sportIdeal',
  );

  final rain = today.chanceOfRain >= umbrellaRainPct;
  final umbrella = LifeIndex(
    kind: LifeKind.umbrella,
    level: rain ? LifeLevel.poor : LifeLevel.good,
    key: rain ? 'umbrellaYes' : 'umbrellaNo',
  );

  final uv = today.uv; // forecast UV: current UV is 0 at night
  final LifeIndex sunCream;
  if (uv < uvModerateFrom) {
    sunCream = const LifeIndex(
      kind: LifeKind.sunCream,
      level: LifeLevel.good,
      key: 'uvLow',
    );
  } else if (uv <= uvHighAbove) {
    sunCream = const LifeIndex(
      kind: LifeKind.sunCream,
      level: LifeLevel.fair,
      key: 'uvModerate',
    );
  } else {
    sunCream = const LifeIndex(
      kind: LifeKind.sunCream,
      level: LifeLevel.poor,
      key: 'uvHigh',
    );
  }

  final LifeIndex allergy;
  if (epa != null && epa >= allergyHighEpa) {
    allergy = const LifeIndex(
      kind: LifeKind.allergy,
      level: LifeLevel.poor,
      key: 'allergyHigh',
    );
  } else if ((epa != null && epa >= allergyModerateEpa) ||
      now.windKph >= allergyWindKph) {
    allergy = const LifeIndex(
      kind: LifeKind.allergy,
      level: LifeLevel.fair,
      key: 'allergyModerate',
    );
  } else {
    allergy = const LifeIndex(
      kind: LifeKind.allergy,
      level: LifeLevel.good,
      key: 'allergyLow',
    );
  }

  return [dress, carWash, sport, umbrella, sunCream, allergy];
}
