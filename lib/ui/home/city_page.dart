import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/prefs_store.dart';
import '../../data/weather_mapper.dart';
import '../../data/weather_repository.dart';
import '../../domain/life_index.dart';
import '../../domain/models.dart';
import '../../domain/weather_view.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/providers.dart';
import '../cards/alert_card.dart';
import '../cards/brief_card.dart';
import '../cards/current_hero.dart';
import '../cards/daily_card.dart';
import '../cards/glass_card.dart';
import '../cards/hourly_card.dart';
import '../cards/metric_card.dart';
import '../cards/sun_card.dart';
import '../sky/sky_palette.dart';
import '../theme.dart';
import '../typography.dart';

const _gap = AppTokens.cardGap;

/// List padding: the top inset (status bar + top bar, provided by the home
/// screen as MediaQuery padding) keeps the hero below the bar on frame one.
EdgeInsets _pad(BuildContext context) {
  final inset = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(
    AppTokens.gutter,
    inset.top + 4,
    AppTokens.gutter,
    inset.bottom + 32,
  );
}

/// Entrance motion: each card fades and slides up over this duration...
const entranceDuration = Duration(milliseconds: 250);

/// ...starting this much after the previous card.
const entranceStagger = Duration(milliseconds: 50);

/// User-facing text for a weather load failure (Ruling R9).
String weatherErrorText(AppLocalizations l, Object error) {
  if (error is! WeatherApiException) return l.errorGeneric;
  return switch (error.code) {
    1002 || 2006 || 2008 => l.errorKey,
    2007 || 2011 => l.errorQuota,
    1006 => l.errorNotFound,
    null when error.message == 'offline' => l.errorOffline,
    _ => l.errorGeneric,
  };
}

/// One city's scrollable list of weather cards, with pull-to-refresh.
/// [dots] (page indicator) is shown centered under the hero.
class CityPage extends ConsumerWidget {
  final City city;
  final Widget? dots;
  const CityPage(this.city, {super.key, this.dots});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weatherProvider(city));
    if (weather.hasValue) {
      return RefreshIndicator(
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: () => ref.read(weatherProvider(city).notifier).refresh(),
        child: _Cards(
          weather.requireValue,
          ref.watch(settingsProvider),
          ref.read(clockProvider)().toUtc(),
          dots: dots,
        ),
      );
    }
    if (weather.hasError) {
      return _ErrorView(
        message: weatherErrorText(AppLocalizations.of(context), weather.error!),
        onRetry: () => ref.invalidate(weatherProvider(city)),
        dots: dots,
      );
    }
    return _Skeleton(dots: dots);
  }
}

class _Cards extends StatefulWidget {
  final WeatherResult result;
  final Settings settings;
  final DateTime nowUtc;
  final Widget? dots;
  const _Cards(this.result, this.settings, this.nowUtc, {this.dots});

  @override
  State<_Cards> createState() => _CardsState();
}

class _CardsState extends State<_Cards> with SingleTickerProviderStateMixin {
  /// One controller for the whole staggered entrance; it runs once when the
  /// page first shows data, so cards scrolled back into view don't replay.
  late final AnimationController _entrance;

  /// Per-card curves, built once (index = card position).
  late final List<CurvedAnimation> _curves;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    final count = _items().length;
    final total = entranceDuration + entranceStagger * (count - 1);
    _entrance = AnimationController(vsync: this, duration: total);
    _curves = [
      for (var i = 0; i < count; i++)
        CurvedAnimation(
          parent: _entrance,
          curve: Interval(
            (entranceStagger * i).inMicroseconds / total.inMicroseconds,
            (entranceStagger * i + entranceDuration).inMicroseconds /
                total.inMicroseconds,
            curve: Curves.easeOutCubic,
          ),
        ),
    ];
    final slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero);
    _slides = [for (final c in _curves) slide.animate(c)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entrance.isAnimating || _entrance.isCompleted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    for (final c in _curves) {
      c.dispose();
    }
    _entrance.dispose();
    super.dispose();
  }

  /// Cards added by a later refresh (beyond the first count) just appear.
  Widget _enter(int i, Widget child) => FadeTransition(
    key: ValueKey('entrance-$i'),
    opacity: i < _curves.length ? _curves[i] : kAlwaysCompleteAnimation,
    child: SlideTransition(
      position: i < _slides.length
          ? _slides[i]
          : const AlwaysStoppedAnimation(Offset.zero),
      child: child,
    ),
  );

  List<Widget> _items() {
    final result = widget.result, settings = widget.settings;
    final b = result.bundle;
    final c = b.current;
    final view = visibleWindow(b, widget.nowUtc);
    final today = view.days.isEmpty ? null : view.days.first;
    final tomorrow = view.days.length > 1 ? view.days[1] : null;
    return [
      CurrentHero(b, settings),
      if (b.alerts.isNotEmpty) AlertCard(b.alerts),
      HourlyCard(
        view.hours,
        settings,
        toCityTime: b.toCityTime,
        firstIsNow: view.firstHourIsNow,
      ),
      DailyCard(view.days, settings, firstIsToday: view.firstDayIsToday),
      _pair(MetricCard.aqi(c.air), MetricCard.uv(c.uv, peak: today?.uv)),
      if (today != null) SunCard(today, b.toCityTime(widget.nowUtc)),
      _pair(
        MetricCard.wind(c, settings.wind),
        MetricCard.humidity(c, settings.temp),
      ),
      _pair(MetricCard.pressure(c.pressureMb), MetricCard.visibility(c.visKm)),
      if (today != null) BriefCard(deriveLifeIndices(c, today, tomorrow)),
      _Footer(result),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();
    return ListView(
      padding: _pad(context),
      physics: const AlwaysScrollableScrollPhysics(),
      children: _spaced([
        for (var i = 0; i < items.length; i++)
          _enter(
            i,
            i == 0 && widget.dots != null
                ? Column(children: [items[0], widget.dots!])
                : items[i],
          ),
      ]),
    );
  }
}

List<Widget> _spaced(List<Widget> items) => [
  for (var i = 0; i < items.length; i++) ...[
    if (i > 0) const SizedBox(height: _gap),
    items[i],
  ],
];

Widget _pair(Widget a, Widget b) => IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: a),
      const SizedBox(width: _gap),
      Expanded(child: b),
    ],
  ),
);

class _Footer extends StatelessWidget {
  final WeatherResult result;
  const _Footer(this.result);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final b = result.bundle;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat(
      'HH:mm',
      locale,
    ).format(b.toCityTime(b.current.updatedAt));
    final style = AppType.caption.copyWith(
      color: SkyPalette.of(context).inkFaint,
    );
    final error = result.error;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          if (result.isStale)
            Text(
              [
                l.staleLabel,
                if (error != null) weatherErrorText(l, error),
              ].join(' · '),
              textAlign: TextAlign.center,
              style: style.copyWith(fontWeight: FontWeight.w600),
            ),
          Text(
            '${l.updatedAt(time)} · ${l.dataSource}',
            textAlign: TextAlign.center,
            style: style,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Widget? dots;
  const _ErrorView({required this.message, required this.onRetry, this.dots});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Column(
        children: [
          ?dots,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppType.body,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: onRetry, child: Text(l.retry)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static placeholder shown while a city's first load is in flight.
class _Skeleton extends StatelessWidget {
  final Widget? dots;
  const _Skeleton({this.dots});

  @override
  Widget build(BuildContext context) {
    Widget block(double h) => GlassCard(child: SizedBox(height: h));
    return ListView(
      padding: _pad(context),
      physics: const NeverScrollableScrollPhysics(),
      children: _spaced([
        Column(children: [const SizedBox(height: 200), ?dots]),
        block(120),
        block(260),
        _pair(block(90), block(90)),
      ]),
    );
  }
}
