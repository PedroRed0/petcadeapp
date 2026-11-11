import 'package:flutter/material.dart';

/// Níveis (patentes) de prestígio: quantos pets a pessoa ajudou a encontrar.
enum Nivel {
  iniciante(
    0,
    0,
    'Iniciante',
    'Iniciante',
    Icons.pets_rounded,
    Color(0xFF8E8AA5),
    [Color(0xFFB9B5CC), Color(0xFF8E8AA5)],
  ),
  bronze(1, 5, 'Bronze', 'Explorador', Icons.pets_rounded, Color(0xFF8A4B22), [
    Color(0xFF6E3412),
    Color(0xFFC77A43),
    Color(0xFFE8A86B),
    Color(0xFF8A4B22),
  ]),
  prata(2, 10, 'Prata', 'Protetor', Icons.star_rounded, Color(0xFF6B7682), [
    Color(0xFF8E9AA6),
    Color(0xFFE6EBF0),
    Color(0xFFB5BEC7),
    Color(0xFF7D8894),
  ]),
  ouro(
    3,
    20,
    'Ouro',
    'Guardião',
    Icons.workspace_premium_rounded,
    Color(0xFFC08A00),
    [
      Color(0xFFB8860B),
      Color(0xFFFFD54F),
      Color(0xFFF5C542),
      Color(0xFFC99A06),
    ],
  ),
  diamante(
    4,
    50,
    'Diamante',
    'Lenda',
    Icons.diamond_rounded,
    Color(0xFF1C7CC7),
    [
      Color(0xFF0B5FA5),
      Color(0xFF3AA6D9),
      Color(0xFF8FDCFF),
      Color(0xFF1C7CC7),
    ],
  );

  /// Número do nível (1 a 4; Iniciante = 0).
  final int numero;

  /// Pets encontrados necessários para chegar a este nível.
  final int minimo;

  /// Metal: Bronze, Prata, Ouro, Diamante.
  final String nome;

  /// Patente: Explorador, Protetor, Guardião, Lenda.
  final String titulo;

  final IconData icone;

  /// Cor para textos.
  final Color cor;

  /// Degradê "metálico" das molduras e etiquetas.
  final List<Color> metal;

  const Nivel(
    this.numero,
    this.minimo,
    this.nome,
    this.titulo,
    this.icone,
    this.cor,
    this.metal,
  );

  /// Níveis de verdade (sem o Iniciante).
  static List<Nivel> get patentes => values.skip(1).toList();

  static Nivel deQuantidade(int encontrados) {
    var n = Nivel.iniciante;
    for (final nivel in Nivel.values) {
      if (encontrados >= nivel.minimo) n = nivel;
    }
    return n;
  }

  /// "NÍVEL 2 • PRATA"
  String get rotulo => 'NÍVEL $numero • ${nome.toUpperCase()}';

  /// "NÍVEL 2 • PROTETOR"
  String get rotuloTitulo => 'NÍVEL $numero • ${titulo.toUpperCase()}';

  LinearGradient get degrade => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: metal,
  );

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

  /// Se ao passar de [antes] para [depois] pets a pessoa subiu de nível,
  /// retorna o nível novo.
  static Nivel? subiu(int antes, int depois) {
    final a = deQuantidade(antes);
    final d = deQuantidade(depois);
    return d.index > a.index ? d : null;
  }
}
