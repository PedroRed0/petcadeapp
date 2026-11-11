import 'package:flutter/material.dart';

/// Níveis de prestígio: quantos animais a pessoa ajudou a encontrar.
enum Nivel {
  iniciante(0, 'Iniciante', '🐾', Color(0xFF8E8AA5)),
  bronze(5, 'Bronze', '🥉', Color(0xFFB0703A)),
  prata(10, 'Prata', '🥈', Color(0xFF8C96A3)),
  ouro(20, 'Ouro', '🥇', Color(0xFFD9A400)),
  diamante(50, 'Diamante', '💎', Color(0xFF3AA6D9));

  /// Animais encontrados necessários para chegar a este nível.
  final int minimo;
  final String nome;
  final String emoji;
  final Color cor;

  const Nivel(this.minimo, this.nome, this.emoji, this.cor);

  static Nivel deQuantidade(int encontrados) {
    var n = Nivel.iniciante;
    for (final nivel in Nivel.values) {
      if (encontrados >= nivel.minimo) n = nivel;
    }
    return n;
  }

  /// Próximo nível (null se já é Diamante).
  Nivel? get proximo =>
      index + 1 < Nivel.values.length ? Nivel.values[index + 1] : null;

  /// Quantos faltam para o próximo nível.
  int faltamPara(int encontrados) {
    final p = proximo;
    return p == null ? 0 : (p.minimo - encontrados).clamp(0, p.minimo);
  }

  /// Progresso (0 a 1) entre este nível e o próximo.
  double progresso(int encontrados) {
    final p = proximo;
    if (p == null) return 1;
    return ((encontrados - minimo) / (p.minimo - minimo)).clamp(0, 1);
  }
}
