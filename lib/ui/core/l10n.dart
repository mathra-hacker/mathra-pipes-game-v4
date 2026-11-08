import 'package:pipes/domain/models/app_settings.dart';

/// Tiny bilingual helper (English / සිංහල / both).
///
///   L10n.t('Play', 'ක්‍රීඩා කරන්න')   -> short labels (buttons, titles)
///   L10n.d('long text', 'දිග වාක්‍යය') -> long text (two lines in "both")
class L10n {
  L10n._();

  static AppLanguage current = AppLanguage.both;

  static String t(String en, String si) {
    switch (current) {
      case AppLanguage.en:
        return en;
      case AppLanguage.si:
        return si;
      case AppLanguage.both:
        return '$en  •  $si';
    }
  }

  static String d(String en, String si) {
    switch (current) {
      case AppLanguage.en:
        return en;
      case AppLanguage.si:
        return si;
      case AppLanguage.both:
        return '$en\n$si';
    }
  }
}
