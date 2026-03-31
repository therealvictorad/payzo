import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme mode provider ───────────────────────────────────────────────────────

const _kThemeKey = 'theme_mode';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // overwritten by init()

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    state = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ── Color palette ─────────────────────────────────────────────────────────────

class AppColors {
  // Brand
  static const primary      = Color(0xFF7B6EF6);
  static const primaryDark  = Color(0xFF5A50D4);
  static const primaryLight = Color(0xFF9D94FF);
  static const accent       = Color(0xFF00D4AA);
  static const accentLight  = Color(0xFF00F5C4);

  // Dark surfaces
  static const darkBg      = Color(0xFF080810);
  static const darkSurface = Color(0xFF10101C);
  static const darkCard    = Color(0xFF181828);
  static const darkCardAlt = Color(0xFF1E1E32);
  static const darkBorder  = Color(0xFF252538);

  // Light surfaces
  static const lightBg      = Color(0xFFF2F2FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard    = Color(0xFFFFFFFF);
  static const lightCardAlt = Color(0xFFF8F8FF);
  static const lightBorder  = Color(0xFFE2E2F0);

  // Dark text
  static const textPrimary   = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF7878A0);
  static const textMuted     = Color(0xFF4A4A68);

  // Light text
  static const lightTextPrimary   = Color(0xFF0C0C1E);
  static const lightTextSecondary = Color(0xFF5C5C88);
  static const lightTextMuted     = Color(0xFFAAAAAC);

  // Status
  static const success = Color(0xFF00D4AA);
  static const error   = Color(0xFFFF4D6A);
  static const warning = Color(0xFFFFB347);

  // Gradients
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B6EF6), Color(0xFFAA5CF7)],
  );

  static const cardGradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFFE040FB)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4AA), Color(0xFF00A8FF)],
  );

  // Dark background mesh gradient
  static const darkBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E0E1E), Color(0xFF080810)],
  );

  // Light background mesh gradient
  static const lightBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEEEEFF), Color(0xFFF5F5FF)],
  );
}

// ── Typography helpers ────────────────────────────────────────────────────────

class AppText {
  static TextStyle display(bool isDark) => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        letterSpacing: -1.2,
        height: 1.1,
      );

  static TextStyle heading(bool isDark) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle title(bool isDark) => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle body(bool isDark) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
        height: 1.5,
      );

  static TextStyle label(bool isDark) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle caption(bool isDark) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
        letterSpacing: 0.3,
      );

  static const sectionTag = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.textSecondary,
  );
}

// ── Spacing scale ─────────────────────────────────────────────────────────────

class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;

  static const pagePadding = EdgeInsets.symmetric(horizontal: 22.0);
}

// ── Radius scale ──────────────────────────────────────────────────────────────

class AppRadius {
  static const sm  = 10.0;
  static const md  = 16.0;
  static const lg  = 22.0;
  static const xl  = 28.0;
  static const xxl = 36.0;
}

// ── Shadow helpers ────────────────────────────────────────────────────────────

class AppShadows {
  static List<BoxShadow> card(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ]
      : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.10),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];

  static List<BoxShadow> balanceCard = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.40),
      blurRadius: 40,
      spreadRadius: -8,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: const Color(0xFFAA5CF7).withOpacity(0.20),
      blurRadius: 60,
      spreadRadius: -10,
      offset: const Offset(0, 24),
    ),
  ];

  static List<BoxShadow> fab = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.50),
      blurRadius: 20,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];
}

// ── Theme data ────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg     = isDark ? AppColors.darkBg     : AppColors.lightBg;
    final card   = isDark ? AppColors.darkCard   : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final txtPri = isDark ? AppColors.textPrimary      : AppColors.lightTextPrimary;
    final txtSec = isDark ? AppColors.textSecondary    : AppColors.lightTextSecondary;
    final txtMut = isDark ? AppColors.textMuted        : AppColors.lightTextMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary:   AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface:   isDark ? AppColors.darkSurface : AppColors.lightSurface,
        onSurface: txtPri,
        error:     AppColors.error,
        onError:   Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge:  GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: txtPri, letterSpacing: -1.2, height: 1.1),
        displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: txtPri, letterSpacing: -0.8),
        headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: txtPri, letterSpacing: -0.5),
        headlineMedium:GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: txtPri, letterSpacing: -0.3),
        titleLarge:    GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: txtPri, letterSpacing: -0.3),
        titleMedium:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: txtPri),
        titleSmall:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: txtPri),
        bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: txtPri, height: 1.6),
        bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: txtSec, height: 1.5),
        bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: txtMut, height: 1.4),
        labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: txtPri, letterSpacing: 0.3),
        labelMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: txtSec, letterSpacing: 0.2),
        labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: txtMut, letterSpacing: 1.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle:  GoogleFonts.inter(color: txtMut,  fontSize: 14),
        labelStyle: GoogleFonts.inter(color: txtSec, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          elevation: 0,
          shadowColor: AppColors.primary.withOpacity(0.4),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          side: BorderSide(color: border),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 2,
        shadowColor: AppColors.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: txtPri,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: txtPri),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : (isDark ? AppColors.textMuted : AppColors.lightTextMuted),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withOpacity(0.35)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
    );
  }
}
