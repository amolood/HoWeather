import 'package:flutter/widgets.dart';

import 'line_icon.dart';

enum WxIcon {
  sun,
  moon,
  partlyDay,
  partlyNight,
  cloud,
  overcast,
  fog,
  drizzle,
  rain,
  heavyRain,
  thunder,
  sleet,
  snow,
  heavySnow,
}

String _cloud(double b) =>
    'M17.5 ${b}H7a4 4 0 0 1-.4-8 5 5 0 0 1 9.7 1.3A3.3 3.3 0 0 1 17.5 ${b}z';

const _partlyCloud =
    'M17.5 19H8a3.5 3.5 0 0 1-.3-7 4.5 4.5 0 0 1 8.7 1.2A3 3 0 0 1 17.5 19z';

const _sunRays = 'M8 3.5v1M3.5 8.5h1M4.9 5.4l.7.7M11.1 5.4l-.7.7';

final Map<WxIcon, LineShape> _shapes = {
  WxIcon.sun: const LineShape(
    [
      'M12 2v2M12 20v2M4.2 4.2l1.4 1.4M18.4 18.4l1.4 1.4M2 12h2M20 12h2M4.2 19.8l1.4-1.4M18.4 5.6l1.4-1.4',
    ],
    [(12, 12, 4.2)],
  ),
  WxIcon.moon: const LineShape([
    'M20 14.5A8 8 0 1 1 9.5 4a6.3 6.3 0 0 0 10.5 10.5z',
  ]),
  WxIcon.partlyDay: LineShape([_sunRays, _partlyCloud], const [(8, 8.5, 3.2)]),
  WxIcon.partlyNight: LineShape([
    'M11.2 9.4A3.7 3.7 0 1 1 6.6 4.5a3 3 0 0 0 4.6 4.9z',
    _partlyCloud,
  ]),
  WxIcon.cloud: LineShape([_cloud(18)]),
  WxIcon.overcast: LineShape([
    'M9.5 8.6A4 4 0 0 1 16.6 6.6 3.6 3.6 0 0 1 20.5 10.6',
    _cloud(20),
  ]),
  WxIcon.fog: LineShape([_cloud(13), 'M4.5 16.5h15M8 20h8']),
  WxIcon.drizzle: LineShape([
    _cloud(15),
    'M8 18.2l-.6 1.4M12 18.2l-.6 1.4M16 18.2l-.6 1.4',
  ]),
  WxIcon.rain: LineShape([_cloud(15), 'M8 18l-1 2M12 18l-1 2M16 18l-1 2']),
  WxIcon.heavyRain: LineShape([
    _cloud(14),
    'M8 17l-1.5 4M12 17l-1.5 4M16 17l-1.5 4',
  ]),
  WxIcon.thunder: LineShape([_cloud(15), 'M12.8 15.5l-2.6 3h3.6l-2.2 3.5']),
  WxIcon.sleet: LineShape([
    _cloud(15),
    'M8 17.5l-1 2.5M16 17.5l-1 2.5M12 18.5v.01M12 21.5v.01',
  ]),
  WxIcon.snow: LineShape([
    _cloud(15),
    'M8 18.5v.01M12 18.5v.01M16 18.5v.01M10 21.5v.01M14 21.5v.01',
  ]),
  WxIcon.heavySnow: LineShape([
    _cloud(14),
    'M8 17.2v2.8M6.6 18.6h2.8M16 17.2v2.8M14.6 18.6h2.8M12 20.2v2.4M10.8 21.4h2.4',
  ]),
};

LineShape wxShape(WxIcon icon) => _shapes[icon]!;

/// Condition images from the app's drawable set (assets/icons/). They are
/// full-color, so [WxIconView]'s color is ignored for them. Icons without an
/// entry here fall back to the vector shape in [_shapes].
const Map<WxIcon, String> _assets = {
  WxIcon.sun: 'assets/icons/wx_sun.png',
  WxIcon.moon: 'assets/icons/wx_moon.png',
  WxIcon.partlyDay: 'assets/icons/wx_partly_day.png',
  WxIcon.partlyNight: 'assets/icons/wx_partly_night.png',
  WxIcon.cloud: 'assets/icons/wx_cloud.webp',
  WxIcon.overcast: 'assets/icons/wx_cloud.webp',
  WxIcon.fog: 'assets/icons/wx_fog.webp',
  WxIcon.drizzle: 'assets/icons/wx_drizzle.webp',
  WxIcon.rain: 'assets/icons/wx_drizzle.webp',
  WxIcon.heavyRain: 'assets/icons/wx_heavy_rain.webp',
  WxIcon.thunder: 'assets/icons/wx_thunder.webp',
  WxIcon.sleet: 'assets/icons/wx_snow.webp',
  WxIcon.snow: 'assets/icons/wx_snow.webp',
  WxIcon.heavySnow: 'assets/icons/wx_heavy_snow.webp',
};

class WxIconView extends StatelessWidget {
  final WxIcon icon;
  final double size;
  final Color? color;
  const WxIconView(this.icon, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final asset = _assets[icon];
    if (asset == null) {
      return LineIconBox(shape: wxShape(icon), size: size, color: color);
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
