import 'package:flutter/material.dart';

enum AppThemePreset {
  pastelMint(
    id: 'pastelMint',
    displayName: 'Mint & Sage',
    bg: Color(0xFFEAF5ED),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFA5D6A7),
    headingDark: Color(0xFF1B4D3E),
    headingWhite: Color(0xFF0F382C),
    subtext: Color(0xFF4A7C59),
    gridLines: Color(0xFFC8E6C9),
    accent: Color(0xFF388E3C),
    border: Color(0xFFA5D6A7),
  ),
  pastelPeach(
    id: 'pastelPeach',
    displayName: 'Warm Peach',
    bg: Color(0xFFFFF3E0),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFCC80),
    headingDark: Color(0xFF4E2A00),
    headingWhite: Color(0xFF381D00),
    subtext: Color(0xFF8C5C26),
    gridLines: Color(0xFFFFE0B2),
    accent: Color(0xFFE65100),
    border: Color(0xFFFFB74D),
  ),
  pastelLavender(
    id: 'pastelLavender',
    displayName: 'Soft Lavender',
    bg: Color(0xFFF3E5F5),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFCE93D8),
    headingDark: Color(0xFF3A1C47),
    headingWhite: Color(0xFF281133),
    subtext: Color(0xFF6B437C),
    gridLines: Color(0xFFE1BEE7),
    accent: Color(0xFF7B1FA2),
    border: Color(0xFFBA68C8),
  ),
  pastelSky(
    id: 'pastelSky',
    displayName: 'Cloud Sky',
    bg: Color(0xFFE1F5FE),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF81D4FA),
    headingDark: Color(0xFF013A63),
    headingWhite: Color(0xFF012A4A),
    subtext: Color(0xFF2A6F97),
    gridLines: Color(0xFFB3E5FC),
    accent: Color(0xFF0288D1),
    border: Color(0xFF4FC3F7),
  ),
  pastelRose(
    id: 'pastelRose',
    displayName: 'Pastel Rose',
    bg: Color(0xFFFCE4EC),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFF48FB1),
    headingDark: Color(0xFF4A1525),
    headingWhite: Color(0xFF360C19),
    subtext: Color(0xFF883955),
    gridLines: Color(0xFFF8BBD0),
    accent: Color(0xFFC2185B),
    border: Color(0xFFF06292),
  ),
  pastelButter(
    id: 'pastelButter',
    displayName: 'Honey Butter',
    bg: Color(0xFFFFFDE7),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFE082),
    headingDark: Color(0xFF423800),
    headingWhite: Color(0xFF2D2600),
    subtext: Color(0xFF7A6A10),
    gridLines: Color(0xFFFFF59D),
    accent: Color(0xFFF57F17),
    border: Color(0xFFFFD54F),
  ),
  pastelCoral(
    id: 'pastelCoral',
    displayName: 'Sweet Coral',
    bg: Color(0xFFFFEBE6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFFFAB91),
    headingDark: Color(0xFF4D1C10),
    headingWhite: Color(0xFF38120A),
    subtext: Color(0xFF8D4434),
    gridLines: Color(0xFFFFCCBC),
    accent: Color(0xFFD84315),
    border: Color(0xFFFF8A65),
  ),
  pastelOcean(
    id: 'pastelOcean',
    displayName: 'Aqua Breeze',
    bg: Color(0xFFE0F2F1),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF80CBC4),
    headingDark: Color(0xFF00363A),
    headingWhite: Color(0xFF002528),
    subtext: Color(0xFF00695C),
    gridLines: Color(0xFFB2DFDB),
    accent: Color(0xFF00695C),
    border: Color(0xFF4DB6AC),
  ),
  obsidian(
    id: 'obsidian',
    displayName: 'Obsidian Dark',
    bg: Color(0xFF121212),
    surface: Color(0xFF1C1C1C),
    primary: Color(0xFF2D2D2D),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF121212),
    subtext: Color(0xFF888888),
    gridLines: Color(0xFF2D2D2D),
    accent: Color(0xFF81C784),
    border: Color(0x3DFFFFFF),
  ),
  lemonLime(
    id: 'lemonLime',
    displayName: 'Lemon Lime',
    bg: Color(0xFFF4FBE3),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFC5E1A5),
    headingDark: Color(0xFF2E4A0B),
    headingWhite: Color(0xFF1F3306),
    subtext: Color(0xFF5B7F2A),
    gridLines: Color(0xFFDCEDC8),
    accent: Color(0xFF689F38),
    border: Color(0xFFAED581),
  ),
  sandDune(
    id: 'sandDune',
    displayName: 'Sand Dune',
    bg: Color(0xFFF5EFE6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFD7C4A3),
    headingDark: Color(0xFF3E2F1C),
    headingWhite: Color(0xFF2A1F12),
    subtext: Color(0xFF7A6548),
    gridLines: Color(0xFFE6D9C3),
    accent: Color(0xFF8D6E3F),
    border: Color(0xFFC9B48F),
  ),
  midnight(
    id: 'midnight',
    displayName: 'Midnight Blue',
    bg: Color(0xFF0B1220),
    surface: Color(0xFF121B2E),
    primary: Color(0xFF1C2A44),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0B1220),
    subtext: Color(0xFF8FA3C4),
    gridLines: Color(0xFF1C2A44),
    accent: Color(0xFF4FC3F7),
    border: Color(0x3DFFFFFF),
  ),
  neonNight(
    id: 'neonNight',
    displayName: 'Neon Night',
    bg: Color(0xFF0D0221),
    surface: Color(0xFF1A0B38),
    primary: Color(0xFF2A1458),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0D0221),
    subtext: Color(0xFFA89BC9),
    gridLines: Color(0xFF2A1458),
    accent: Color(0xFFFF2E97),
    border: Color(0x3DFFFFFF),
  ),
  deepForest(
    id: 'deepForest',
    displayName: 'Deep Forest',
    bg: Color(0xFF0E1A14),
    surface: Color(0xFF16261D),
    primary: Color(0xFF1F3A2B),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF0E1A14),
    subtext: Color(0xFF8DB09B),
    gridLines: Color(0xFF1F3A2B),
    accent: Color(0xFF66BB6A),
    border: Color(0x3DFFFFFF),
  ),
  crimsonDark(
    id: 'crimsonDark',
    displayName: 'Crimson Dark',
    bg: Color(0xFF1A0A0D),
    surface: Color(0xFF261015),
    primary: Color(0xFF3A1720),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF1A0A0D),
    subtext: Color(0xFFC99AA3),
    gridLines: Color(0xFF3A1720),
    accent: Color(0xFFFF5252),
    border: Color(0x3DFFFFFF),
  ),
  amoledGold(
    id: 'amoledGold',
    displayName: 'AMOLED Gold',
    bg: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    primary: Color(0xFF1A1A1A),
    headingDark: Color(0xFFFFFFFF),
    headingWhite: Color(0xFF000000),
    subtext: Color(0xFF8A8A8A),
    gridLines: Color(0xFF1A1A1A),
    accent: Color(0xFFFFD54F),
    border: Color(0x3DFFFFFF),
  );

  const AppThemePreset({
    required this.id,
    required this.displayName,
    required this.bg,
    required this.surface,
    required this.primary,
    required this.headingDark,
    required this.headingWhite,
    required this.subtext,
    required this.gridLines,
    required this.accent,
    required this.border,
  });

  final String id;
  final String displayName;
  final Color bg;
  final Color surface;
  final Color primary;
  final Color headingDark;
  final Color headingWhite;
  final Color subtext;
  final Color gridLines;
  final Color accent;
  final Color border;

  static AppThemePreset fromId(String? id) {
    return AppThemePreset.values.firstWhere(
      (e) => e.id == id,
      orElse: () => AppThemePreset.pastelSky,
    );
  }

  bool get isDark => bg.computeLuminance() < 0.5;
}

enum AppLanguage {
  en('English', 'English'),
  si('සිංහල', 'සිංහල'),
  both('English + සිංහල', 'English + සිංහල');

  const AppLanguage(this.label, this.sinhala);
  final String label;
  final String sinhala;

  static AppLanguage fromName(String? name) {
    return AppLanguage.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppLanguage.both,
    );
  }
}

enum EmojiSpeed {
  slow('Slow', 'හෙමින්'),
  fast('Fast', 'හයියෙන්');

  const EmojiSpeed(this.label, this.sinhala);
  final String label;
  final String sinhala;

  static EmojiSpeed fromName(String? name) {
    return EmojiSpeed.values.firstWhere(
      (e) => e.name == name,
      orElse: () => EmojiSpeed.slow,
    );
  }
}

/// What plays when a level is completed.
enum GameEffect {
  emoji('Emoji rain', 'Emoji වැස්ස', '🎉'),
  confetti('Confetti', 'කොන්ෆෙටි', '🎊'),
  both('Both', 'දෙකම', '✨'),
  off('Off', 'නැහැ', '🚫');

  const GameEffect(this.label, this.sinhala, this.icon);
  final String label;
  final String sinhala;
  final String icon;

  bool get hasEmoji => this == GameEffect.emoji || this == GameEffect.both;
  bool get hasConfetti => this == GameEffect.confetti || this == GameEffect.both;

  static GameEffect fromName(String? name) {
    return GameEffect.values.firstWhere(
      (e) => e.name == name,
      orElse: () => GameEffect.both,
    );
  }
}

/// Quality used when a YouTube link is downloaded as audio.
/// Smaller files download much faster.
enum AudioQuality {
  fast('Fast', 'වේගවත්', '~48 kbps'),
  normal('Normal', 'සාමාන්‍ය', '~128 kbps'),
  high('High', 'උසස්', 'best');

  const AudioQuality(this.label, this.sinhala, this.hint);
  final String label;
  final String sinhala;
  final String hint;

  static AudioQuality fromName(String? name) {
    return AudioQuality.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AudioQuality.normal,
    );
  }
}

class EmojiPack {
  const EmojiPack(this.id, this.name, this.emojis);
  final String id;
  final String name;
  final List<String> emojis;

  static const List<EmojiPack> all = [
    EmojiPack('water', 'Water 💧', ['💧', '🌊', '💦', '🫧', '💙']),
    EmojiPack('love', 'Love ❤️', ['❤️', '💖', '💕', '💗', '😍']),
    EmojiPack('party', 'Party 🎉', ['🎉', '🎊', '✨', '🥳', '🎈']),
    EmojiPack('stars', 'Stars ⭐', ['⭐', '🌟', '✨', '💫', '🌠']),
    EmojiPack('fun', 'Fun 😂', ['😂', '🤩', '😎', '🥰', '😜']),
    EmojiPack('fruit', 'Fruit 🍓', ['🍓', '🍉', '🍒', '🍍', '🍊']),
  ];

  static EmojiPack fromId(String? id) {
    return all.firstWhere((e) => e.id == id, orElse: () => all.first);
  }
}

@immutable
class AppSettings {
  const AppSettings({
    this.isHintEnabled = false,
    this.theme = AppThemePreset.pastelSky,
    this.emojiSpeed = EmojiSpeed.slow,
    this.emojiPackId = 'water',
    this.autoPlayMusic = false,
    this.language = AppLanguage.both,
    this.effect = GameEffect.both,
    this.haptics = true,
    this.audioQuality = AudioQuality.normal,
  });

  final bool isHintEnabled;
  final AppThemePreset theme;
  final EmojiSpeed emojiSpeed;
  final String emojiPackId;
  final bool autoPlayMusic;
  final AppLanguage language;
  final GameEffect effect;
  final bool haptics;
  final AudioQuality audioQuality;

  EmojiPack get emojiPack => EmojiPack.fromId(emojiPackId);

  AppSettings copyWith({
    bool? isHintEnabled,
    AppThemePreset? theme,
    EmojiSpeed? emojiSpeed,
    String? emojiPackId,
    bool? autoPlayMusic,
    AppLanguage? language,
    GameEffect? effect,
    bool? haptics,
    AudioQuality? audioQuality,
  }) {
    return AppSettings(
      isHintEnabled: isHintEnabled ?? this.isHintEnabled,
      theme: theme ?? this.theme,
      emojiSpeed: emojiSpeed ?? this.emojiSpeed,
      emojiPackId: emojiPackId ?? this.emojiPackId,
      autoPlayMusic: autoPlayMusic ?? this.autoPlayMusic,
      language: language ?? this.language,
      effect: effect ?? this.effect,
      haptics: haptics ?? this.haptics,
      audioQuality: audioQuality ?? this.audioQuality,
    );
  }
}
