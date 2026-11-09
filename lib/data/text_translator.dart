import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Translates free text (official alerts, place names) into the app's
/// language.
abstract class TextTranslator {
  /// [text] in [targetLang] ('en' or 'ar'). Returns [text] unchanged when it
  /// is already in that language. Throws [TranslationUnavailable] when the
  /// source language is unknown or the model can't be used (e.g. offline
  /// before its first download). Pass [from] when the source language is
  /// known (place names are too short to identify reliably).
  Future<String> translate(String text, String targetLang, {String? from});
}

class TranslationUnavailable implements Exception {
  final String reason;
  const TranslationUnavailable(this.reason);
  @override
  String toString() => 'TranslationUnavailable: $reason';
}

/// Leaves text as it is; the default where no real translator is wired
/// (tests, unsupported platforms).
class PassThroughTranslator implements TextTranslator {
  const PassThroughTranslator();
  @override
  Future<String> translate(
    String text,
    String targetLang, {
    String? from,
  }) async => text;
}

/// On-device Google ML Kit: identifies the source language (unless given),
/// then translates. Each language model (~30 MB) downloads once on first
/// use, then works offline.
class MlKitTextTranslator implements TextTranslator {
  final _identifier = LanguageIdentifier(confidenceThreshold: 0.4);
  final _translators = <String, OnDeviceTranslator>{};

  @override
  Future<String> translate(
    String text,
    String targetLang, {
    String? from,
  }) async {
    if (text.trim().isEmpty) return text;
    final target = BCP47Code.fromRawValue(targetLang);
    if (target == null) throw TranslationUnavailable('target $targetLang');
    final code = from ?? await _identifier.identifyLanguage(text);
    if (code == targetLang) return text;
    final source = BCP47Code.fromRawValue(code);
    if (source == null) throw TranslationUnavailable('source $code');
    final translator = _translators.putIfAbsent(
      '$code>$targetLang',
      () => OnDeviceTranslator(sourceLanguage: source, targetLanguage: target),
    );
    try {
      return await translator.translateText(text);
    } catch (e) {
      throw TranslationUnavailable('$e');
    }
  }
}
