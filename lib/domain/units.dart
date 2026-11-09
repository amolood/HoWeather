import 'models.dart';

double convertTemp(double c, TempUnit u) => switch (u) {
  TempUnit.c => c,
  TempUnit.f => c * 9 / 5 + 32,
};

double convertWind(double kph, WindUnit u) => switch (u) {
  WindUnit.kmh => kph,
  WindUnit.mph => kph / 1.609344,
  WindUnit.ms => kph / 3.6,
};
