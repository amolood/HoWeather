import 'package:flutter/widgets.dart';

/// The app's type scale. Every style uses tabular figures so numbers line up
/// and don't jitter when they change. Colours come from the caller (the sky
/// palette over the sky, the theme elsewhere).
abstract final class AppType {
  static const _tab = [FontFeature.tabularFigures()];

  /// Hero temperature.
  static const display = TextStyle(
    fontSize: 104,
    height: 1,
    fontWeight: FontWeight.w200,
    letterSpacing: -2,
    fontFeatures: _tab,
  );

  /// Degree sign next to [display]: smaller, top-aligned by the caller.
  static const displayUnit = TextStyle(
    fontSize: 44,
    height: 1,
    fontWeight: FontWeight.w200,
    fontFeatures: _tab,
  );

  /// The one dominant value of a metric card.
  static const metric = TextStyle(
    fontSize: 48,
    height: 1,
    fontWeight: FontWeight.w300,
    letterSpacing: -1,
    fontFeatures: _tab,
  );

  /// Unit next to [metric]: small, top-aligned by the caller.
  static const metricUnit = TextStyle(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFeatures: _tab,
  );

  static const title = TextStyle(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w500,
    fontFeatures: _tab,
  );

  static const body = TextStyle(
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w400,
    fontFeatures: _tab,
  );

  /// Card headers. Use [labelOf] / [labelText], which keep Arabic joined.
  static const label = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    fontFeatures: _tab,
  );

  static const caption = TextStyle(
    fontSize: 12.5,
    height: 1.3,
    fontWeight: FontWeight.w400,
    fontFeatures: _tab,
  );

  /// Scripts whose letters join: tracking or case changes break them.
  static bool _joined(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

  /// [label] for the current locale: no letter spacing in Arabic.
  static TextStyle labelOf(BuildContext context) =>
      _joined(context) ? label.copyWith(letterSpacing: 0) : label;

  /// Label text for the current locale: upper-cased except in Arabic.
  static String labelText(BuildContext context, String text) =>
      _joined(context) ? text : text.toUpperCase();
}
