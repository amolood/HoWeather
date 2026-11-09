// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'هو ويذر';

  @override
  String get hourly => 'توقعات كل ساعة';

  @override
  String forecastDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'توقعات $count يوم',
      many: 'توقعات $count يومًا',
      few: 'توقعات $count أيام',
      two: 'توقعات يومين',
      one: 'توقعات يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get airQuality => 'جودة الهواء';

  @override
  String get uvIndex => 'الأشعة فوق البنفسجية';

  @override
  String get wind => 'الرياح';

  @override
  String get humidity => 'الرطوبة';

  @override
  String get pressure => 'الضغط الجوي';

  @override
  String get visibility => 'مدى الرؤية';

  @override
  String get sunriseSunset => 'الشروق والغروب';

  @override
  String get sunrise => 'الشروق';

  @override
  String get sunset => 'الغروب';

  @override
  String get dailyBrief => 'موجز اليوم';

  @override
  String feelsLike(String temp) {
    return 'المحسوسة $temp';
  }

  @override
  String high(String temp) {
    return 'العظمى $temp';
  }

  @override
  String low(String temp) {
    return 'الصغرى $temp';
  }

  @override
  String get aqiGood => 'جيدة';

  @override
  String get aqiModerate => 'متوسطة';

  @override
  String get aqiUnhealthySensitive => 'غير صحية للفئات الحساسة';

  @override
  String get aqiUnhealthy => 'غير صحية';

  @override
  String get aqiVeryUnhealthy => 'غير صحية جدًا';

  @override
  String get aqiHazardous => 'خطرة';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get today => 'اليوم';

  @override
  String get now => 'الآن';

  @override
  String dewPoint(String temp) {
    return 'نقطة الندى $temp';
  }

  @override
  String gusts(String value) {
    return 'الهبات $value';
  }

  @override
  String get lifeDress => 'اللباس';

  @override
  String get lifeCarWash => 'غسيل السيارة';

  @override
  String get lifeSport => 'الرياضة';

  @override
  String get lifeUmbrella => 'المظلة';

  @override
  String get lifeSunCream => 'واقي الشمس';

  @override
  String get lifeAllergy => 'الحساسية';

  @override
  String get dressWarm => 'ملابس دافئة';

  @override
  String get dressLight => 'ملابس خفيفة';

  @override
  String get dressCool => 'ملابس صيفية';

  @override
  String get carWashGood => 'مناسب';

  @override
  String get carWashPoor => 'غير مناسب';

  @override
  String get sportIdeal => 'مثالية';

  @override
  String get sportPoor => 'غير مناسبة';

  @override
  String get umbrellaYes => 'خذ مظلة';

  @override
  String get umbrellaNo => 'غير ضرورية';

  @override
  String get uvLow => 'منخفضة';

  @override
  String get uvModerate => 'متوسطة';

  @override
  String get uvHigh => 'مرتفعة';

  @override
  String get allergyLow => 'منخفضة';

  @override
  String get allergyModerate => 'متوسطة';

  @override
  String get allergyHigh => 'مرتفعة';

  @override
  String get unitKmh => 'كم/س';

  @override
  String get unitMph => 'ميل/س';

  @override
  String get unitMs => 'م/ث';

  @override
  String get unitMb => 'مليبار';

  @override
  String get unitKm => 'كم';

  @override
  String get unitPercent => '٪';

  @override
  String get dirN => 'شمال';

  @override
  String get dirNNE => 'شمال شمال شرق';

  @override
  String get dirNE => 'شمال شرق';

  @override
  String get dirENE => 'شرق شمال شرق';

  @override
  String get dirE => 'شرق';

  @override
  String get dirESE => 'شرق جنوب شرق';

  @override
  String get dirSE => 'جنوب شرق';

  @override
  String get dirSSE => 'جنوب جنوب شرق';

  @override
  String get dirS => 'جنوب';

  @override
  String get dirSSW => 'جنوب جنوب غرب';

  @override
  String get dirSW => 'جنوب غرب';

  @override
  String get dirWSW => 'غرب جنوب غرب';

  @override
  String get dirW => 'غرب';

  @override
  String get dirWNW => 'غرب شمال غرب';

  @override
  String get dirNW => 'شمال غرب';

  @override
  String get dirNNW => 'شمال شمال غرب';

  @override
  String updatedAt(String time) {
    return 'آخر تحديث $time';
  }

  @override
  String get staleLabel => 'عرض بيانات محفوظة';

  @override
  String get dataSource => 'WeatherAPI.com';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get errorOffline => 'لا يوجد اتصال بالإنترنت';

  @override
  String get errorGeneric => 'تعذّر تحميل الطقس';

  @override
  String get errorKey => 'مفتاح API غير صالح';

  @override
  String get errorQuota => 'تم تجاوز الحصة الشهرية لـ API';

  @override
  String get errorNotFound => 'لم يتم العثور على الموقع';

  @override
  String get searchCity => 'ابحث عن مدينة';

  @override
  String get useMyLocation => 'استخدم موقعي';

  @override
  String get noCitiesTitle => 'لا توجد مدن بعد';

  @override
  String get myLocation => 'موقعي';

  @override
  String get cities => 'المدن';

  @override
  String get addCity => 'إضافة مدينة';

  @override
  String get searchHint => 'ابحث عن مدينة';

  @override
  String get noResults => 'لم يتم العثور على مدن';

  @override
  String get cityLimitReached => 'يمكنك حفظ ما يصل إلى 10 مدن';

  @override
  String get delete => 'حذف';

  @override
  String get settings => 'الإعدادات';

  @override
  String get temperatureUnit => 'وحدة الحرارة';

  @override
  String get windUnit => 'وحدة سرعة الرياح';

  @override
  String get autoUpdate => 'التحديث التلقائي';

  @override
  String get manual => 'يدوي';

  @override
  String everyHours(int n) {
    return 'كل $n س';
  }

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get about => 'حول التطبيق';

  @override
  String get dataAttribution => 'بيانات الطقس من WeatherAPI.com';

  @override
  String get unitCelsius => '°م';

  @override
  String get unitFahrenheit => '°ف';

  @override
  String get version => 'الإصدار';

  @override
  String get locationDenied => 'الوصول إلى الموقع متوقف. اسمح به من الإعدادات.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get humidityDry => 'جافة';

  @override
  String get humidityComfortable => 'معتدلة';

  @override
  String get humidityHumid => 'عالية';

  @override
  String get pressureLow => 'منخفض';

  @override
  String get pressureNormal => 'طبيعي';

  @override
  String get pressureHigh => 'مرتفع';

  @override
  String pressureInfo(String value) {
    return '$value إنش زئبق';
  }

  @override
  String get visPoor => 'ضعيفة';

  @override
  String get visFair => 'مقبولة';

  @override
  String get visGood => 'جيدة';

  @override
  String get visExcellent => 'ممتازة';

  @override
  String visInfo(String value) {
    return '$value ميل';
  }

  @override
  String uvPeak(String value) {
    return 'الذروة اليوم $value';
  }

  @override
  String daylight(String duration) {
    return 'ساعات النهار $duration';
  }

  @override
  String durationHm(int h, int m) {
    return '$hس $mد';
  }

  @override
  String get moonNew => 'محاق';

  @override
  String get moonWaxingCrescent => 'هلال متزايد';

  @override
  String get moonFirstQuarter => 'تربيع أول';

  @override
  String get moonWaxingGibbous => 'أحدب متزايد';

  @override
  String get moonFull => 'بدر';

  @override
  String get moonWaningGibbous => 'أحدب متناقص';

  @override
  String get moonLastQuarter => 'تربيع أخير';

  @override
  String get moonWaningCrescent => 'هلال متناقص';

  @override
  String get weatherAlert => 'تنبيه طقس';

  @override
  String alertsMore(int n) {
    return '+$n أخرى';
  }

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageHint => 'تظهر أوصاف الطقس والتنبيهات الرسمية بهذه اللغة.';

  @override
  String get units => 'الوحدات';

  @override
  String get translating => 'جارٍ الترجمة…';

  @override
  String get alertOriginalText => 'النص الأصلي';

  @override
  String get translationUnavailable =>
      'تعذّرت الترجمة. اضغط لقراءة النص الأصلي.';

  @override
  String get translatedAutomatically => 'مترجم آليًا';

  @override
  String hoursShort(int n) {
    return '$n س';
  }

  @override
  String get refreshManualHint => 'يتم التحديث فقط عند السحب للأسفل.';

  @override
  String get listSeparator => '، ';
}
