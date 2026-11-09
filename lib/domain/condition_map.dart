import '../ui/icons/wx_icons.dart';
import 'models.dart';

enum SkyScene {
  clearDay,
  clearNight,
  cloudyDay,
  cloudyNight,
  rainDay,
  rainNight,
  snowDay,
  snowNight,
  fogDay,
  fogNight,
  stormDay,
  stormNight,
}

/// Icon for every WeatherAPI condition code (1000-1282, 60 codes).
/// Day/night variants of sun/partly-cloudy are resolved in [iconFor].
/// Code 1006 (Cloudy) is intentionally the plain `cloud` icon, which is also
/// the fallback for unknown codes.
const Map<int, WxIcon> _iconByCode = {
  1000: WxIcon.sun,
  1003: WxIcon.partlyDay,
  1006: WxIcon.cloud,
  1009: WxIcon.overcast,
  // Haze, dust, sand, smoke, smog, mist, fog
  1012: WxIcon.fog,
  1015: WxIcon.fog,
  1018: WxIcon.fog,
  1021: WxIcon.fog,
  1024: WxIcon.fog,
  1027: WxIcon.fog,
  1030: WxIcon.fog,
  1033: WxIcon.fog,
  1036: WxIcon.fog,
  1039: WxIcon.fog,
  1042: WxIcon.fog,
  1045: WxIcon.fog,
  1048: WxIcon.fog,
  1135: WxIcon.fog,
  1147: WxIcon.fog,
  // Possible precipitation
  1063: WxIcon.rain,
  1066: WxIcon.snow,
  1069: WxIcon.sleet,
  1072: WxIcon.sleet,
  1087: WxIcon.thunder,
  // Blowing snow, blizzard
  1114: WxIcon.snow,
  1117: WxIcon.heavySnow,
  // Drizzle
  1150: WxIcon.drizzle,
  1153: WxIcon.drizzle,
  1168: WxIcon.sleet,
  1171: WxIcon.sleet,
  // Rain
  1180: WxIcon.rain,
  1183: WxIcon.rain,
  1186: WxIcon.rain,
  1189: WxIcon.rain,
  1192: WxIcon.heavyRain,
  1195: WxIcon.heavyRain,
  1198: WxIcon.sleet,
  1201: WxIcon.sleet,
  // Sleet
  1204: WxIcon.sleet,
  1207: WxIcon.sleet,
  // Snow
  1210: WxIcon.snow,
  1213: WxIcon.snow,
  1216: WxIcon.snow,
  1219: WxIcon.snow,
  1222: WxIcon.heavySnow,
  1225: WxIcon.heavySnow,
  // Ice pellets
  1237: WxIcon.sleet,
  // Showers
  1240: WxIcon.rain,
  1243: WxIcon.heavyRain,
  1246: WxIcon.heavyRain,
  1249: WxIcon.sleet,
  1252: WxIcon.sleet,
  1255: WxIcon.snow,
  1258: WxIcon.heavySnow,
  1261: WxIcon.sleet,
  1264: WxIcon.sleet,
  // Thunder
  1273: WxIcon.thunder,
  1276: WxIcon.thunder,
  1279: WxIcon.thunder,
  1282: WxIcon.thunder,
};

WxIcon iconFor(Condition c) {
  final icon = _iconByCode[c.code] ?? WxIcon.cloud;
  if (c.isDay) return icon;
  return switch (icon) {
    WxIcon.sun => WxIcon.moon,
    WxIcon.partlyDay => WxIcon.partlyNight,
    _ => icon,
  };
}

SkyScene sceneFor(Condition c) {
  final d = c.isDay;
  return switch (iconFor(c)) {
    WxIcon.sun || WxIcon.moon => d ? SkyScene.clearDay : SkyScene.clearNight,
    WxIcon.partlyDay ||
    WxIcon.partlyNight ||
    WxIcon.cloud ||
    WxIcon.overcast => d ? SkyScene.cloudyDay : SkyScene.cloudyNight,
    WxIcon.fog => d ? SkyScene.fogDay : SkyScene.fogNight,
    WxIcon.drizzle ||
    WxIcon.rain ||
    WxIcon.heavyRain => d ? SkyScene.rainDay : SkyScene.rainNight,
    WxIcon.sleet ||
    WxIcon.snow ||
    WxIcon.heavySnow => d ? SkyScene.snowDay : SkyScene.snowNight,
    WxIcon.thunder => d ? SkyScene.stormDay : SkyScene.stormNight,
  };
}
