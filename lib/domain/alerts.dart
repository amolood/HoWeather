import 'models.dart';

/// Severe/Extreme alerts rank first and get the red sign.
bool isSevereAlert(WeatherAlert a) {
  final s = a.severity.toLowerCase();
  return s.contains('severe') || s.contains('extreme');
}

final _latin = RegExp('[A-Za-z]');
final _arabicScript = RegExp('[؀-ۿݐ-ݿࢠ-ࣿ]');
final _rtlScript = RegExp('[֐-ࣿ]');

/// Letters used in Persian/Urdu but not in Arabic (پ چ ژ گ ک ی).
final _persianOnly = RegExp('[پچژگکی]');

/// Whether [text] is already written in [languageCode] ('en' or 'ar').
/// Cheap script check used to skip translation; it does not identify
/// other languages.
bool textMatchesLanguage(String text, String languageCode) {
  final latin = _latin.allMatches(text).length;
  final arabic = _arabicScript.allMatches(text).length;
  if (latin == 0 && arabic == 0) return true; // nothing to judge
  if (languageCode == 'ar') {
    return arabic > latin && !_persianOnly.hasMatch(text);
  }
  return latin >= arabic;
}

bool alertMatchesLanguage(WeatherAlert a, String languageCode) =>
    textMatchesLanguage('${a.event} ${a.headline} ${a.desc}', languageCode);

/// True when [text] contains right-to-left script.
bool isRtlText(String text) => _rtlScript.hasMatch(text);
