import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = _criar(Brightness.light);
  static ThemeData dark = _criar(Brightness.dark);

  static ThemeData _criar(Brightness brilho) {
    final escuro = brilho == Brightness.dark;
    final fundo = escuro ? AppColors.fundoEscuro : AppColors.fundo;
    final superficie = escuro
        ? AppColors.superficieEscura
        : AppColors.superficie;
    final borda = escuro ? AppColors.bordaEscura : AppColors.borda;
    final texto = escuro ? Colors.white : AppColors.textoPrincipal;

    final esquema =
        ColorScheme.fromSeed(
          seedColor: AppColors.roxo,
          brightness: brilho,
        ).copyWith(
          primary: AppColors.laranja,
          onPrimary: Colors.white,
          secondary: AppColors.roxo,
          onSecondary: Colors.white,
          surface: fundo,
          onSurface: texto,
          surfaceContainerHighest: superficie,
          outline: borda,
          outlineVariant: borda,
        );

    final raio = BorderRadius.circular(14);
    OutlineInputBorder bordaCampo(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: raio,
          borderSide: BorderSide(color: cor, width: largura),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquema,
      scaffoldBackgroundColor: fundo,
      splashFactory: InkSparkle.splashFactory,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: brilho).textTheme,
      ).apply(bodyColor: texto, displayColor: texto),
      iconTheme: IconThemeData(color: texto, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: fundo,
        foregroundColor: texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: texto,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.laranja,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.laranja.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.laranja,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.laranja, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: escuro ? const Color(0xFFB9A6EE) : AppColors.roxo,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: escuro ? AppColors.superficieEscura : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textoSecundario.withValues(alpha: 0.8),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textoSecundario,
        ),
        prefixIconColor: AppColors.textoSecundario,
        suffixIconColor: AppColors.textoSecundario,
        border: bordaCampo(borda),
        enabledBorder: bordaCampo(borda),
        focusedBorder: bordaCampo(AppColors.roxo, 1.5),
        errorBorder: bordaCampo(AppColors.perdido),
        focusedErrorBorder: bordaCampo(AppColors.perdido, 1.5),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: fundo,
        selectedColor: AppColors.laranja,
        side: BorderSide(color: borda),
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: texto),
        secondaryLabelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: borda, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.roxoEscuro,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: fundo,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.laranja : null,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.laranja,
      ),
    );
  }
}
