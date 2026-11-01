import 'package:flutter/material.dart';

/// Paleta do PetCadê: laranja (ação) + roxo (identidade).
class AppColors {
  AppColors._();

  // Roxo — cor de identidade (títulos de destaque, links, seleção)
  static const Color roxo = Color(0xFF5B3FA3);
  static const Color roxoEscuro = Color(0xFF3B2873);
  static const Color roxoClaro = Color(0xFFEFEAFB);

  // Laranja — cor de ação (botões principais, item ativo)
  static const Color laranja = Color(0xFFFF8A1F);
  static const Color laranjaClaro = Color(0xFFFFEEDD);

  // Estado "Perdido"
  static const Color perdido = Color(0xFFF2542D);
  static const Color encontrado = Color(0xFF2E9E6A);

  // Neutros
  static const Color fundo = Color(0xFFFFFFFF);
  static const Color superficie = Color(0xFFF5F4F8);
  static const Color borda = Color(0xFFE4E2EC);
  static const Color textoPrincipal = Color(0xFF1C1A27);
  static const Color textoSecundario = Color(0xFF6E6A87);

  // Roxo mais claro para textos/ícones no tema escuro
  static const Color roxoSuave = Color(0xFFB9A6EE);

  static bool escuro(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Roxo para textos e ícones (ajustado ao tema claro/escuro).
  static Color destaque(BuildContext c) => escuro(c) ? roxoSuave : roxo;

  /// Fundo roxinho para ícones e placeholders (ajustado ao tema).
  static Color fundoDestaque(BuildContext c) =>
      escuro(c) ? const Color(0xFF2C2540) : roxoClaro;

  // Tema escuro
  static const Color fundoEscuro = Color(0xFF14121C);
  static const Color superficieEscura = Color(0xFF201D2B);
  static const Color bordaEscura = Color(0xFF332F42);
}
