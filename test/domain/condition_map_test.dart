import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/domain/condition_map.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/ui/icons/wx_icons.dart';

/// All codes from https://www.weatherapi.com/docs/weather_conditions.json.
const allCodes = <int>[
  1000,
  1003,
  1006,
  1009,
  1012,
  1015,
  1018,
  1021,
  1024,
  1027,
  1030,
  1033,
  1036,
  1039,
  1042,
  1045,
  1048,
  1063,
  1066,
  1069,
  1072,
  1087,
  1114,
  1117,
  1135,
  1147,
  1150,
  1153,
  1168,
  1171,
  1180,
  1183,
  1186,
  1189,
  1192,
  1195,
  1198,
  1201,
  1204,
  1207,
  1210,
  1213,
  1216,
  1219,
  1222,
  1225,
  1237,
  1240,
  1243,
  1246,
  1249,
  1252,
  1255,
  1258,
  1261,
  1264,
  1273,
  1276,
  1279,
  1282,
];

Condition c(int code, {bool day = true}) =>
    Condition(code: code, text: '', isDay: day);

void main() {
  test('list has the 60 documented codes', () {
    expect(allCodes.length, 60);
    expect(allCodes.toSet().length, 60);
  });

  test('every documented code maps to a specific icon; only 1006 is cloud', () {
    for (final code in allCodes) {
      for (final day in [true, false]) {
        final icon = iconFor(c(code, day: day));
        if (code == 1006) {
          expect(icon, WxIcon.cloud, reason: 'Cloudy is intentionally cloud');
        } else {
          expect(icon, isNot(WxIcon.cloud), reason: 'code $code unmapped');
        }
      }
    }
  });

  test('spec examples', () {
    expect(iconFor(c(1000)), WxIcon.sun);
    expect(iconFor(c(1000, day: false)), WxIcon.moon);
    expect(iconFor(c(1003)), WxIcon.partlyDay);
    expect(iconFor(c(1003, day: false)), WxIcon.partlyNight);
    expect(iconFor(c(1195)), WxIcon.heavyRain);
    expect(iconFor(c(1087)), WxIcon.thunder);
    expect(iconFor(c(1135)), WxIcon.fog);
    expect(iconFor(c(1225)), WxIcon.heavySnow);
    expect(iconFor(c(9999)), WxIcon.cloud);
    for (final code in [1072, 1168, 1171, 1198, 1201]) {
      expect(iconFor(c(code)), WxIcon.sleet, reason: 'freezing code \$code');
      expect(sceneFor(c(code)), SkyScene.snowDay);
    }
  });

  test('scenes', () {
    expect(sceneFor(c(1000, day: false)), SkyScene.clearNight);
    expect(sceneFor(c(1276)), SkyScene.stormDay);
    expect(sceneFor(c(1276, day: false)), SkyScene.stormNight);
    expect(sceneFor(c(1189)), SkyScene.rainDay);
    expect(sceneFor(c(1213, day: false)), SkyScene.snowNight);
    expect(sceneFor(c(1135)), SkyScene.fogDay);
    expect(sceneFor(c(1009)), SkyScene.cloudyDay);
    expect(sceneFor(c(9999, day: false)), SkyScene.cloudyNight);
  });
}
