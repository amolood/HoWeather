import 'models.dart';

/// The part of a [WeatherBundle] still worth showing at a given moment.
class WeatherView {
  final List<HourlyPoint> hours;
  final List<DailyPoint> days;

  /// Whether `hours.first` is the city's current hour (label it "Now").
  final bool firstHourIsNow;

  /// Whether `days.first` is the city's today (label it "Today").
  final bool firstDayIsToday;

  const WeatherView({
    required this.hours,
    required this.days,
    required this.firstHourIsNow,
    required this.firstDayIsToday,
  });
}

/// Drops hours that ended and days that passed before [nowUtc] in the city's
/// time zone, so a stale bundle never labels old data as "Now"/"Today".
WeatherView visibleWindow(WeatherBundle b, DateTime nowUtc) {
  const hour = Duration(hours: 1);
  final cityNow = b.toCityTime(nowUtc);
  final cityToday = DateTime.utc(cityNow.year, cityNow.month, cityNow.day);
  final hours = [
    for (final h in b.hourly)
      if (b.toCityTime(h.time).add(hour).isAfter(cityNow)) h,
  ];
  final days = [
    for (final d in b.daily)
      if (!d.date.isBefore(cityToday)) d,
  ];
  final firstHour = hours.isEmpty ? null : b.toCityTime(hours.first.time);
  return WeatherView(
    hours: hours,
    days: days,
    firstHourIsNow: firstHour != null && !firstHour.isAfter(cityNow),
    firstDayIsToday: days.isNotEmpty && days.first.date == cityToday,
  );
}
