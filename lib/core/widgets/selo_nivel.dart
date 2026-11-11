import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/nivel.dart';
import '../../screens/perfil/meus_niveis_screen.dart';
import '../../services/prestigio_service.dart';
import '../theme/app_colors.dart';

/// Cor do texto em cima do degradê metálico (a prata é clara).
Color corSobreMetal(Nivel n) =>
    n == Nivel.prata ? const Color(0xFF3E4650) : Colors.white;

/// Etiqueta metálica: "★ NÍVEL 2 • PRATA". Iniciantes não mostram nada.
class SeloNivel extends StatelessWidget {
  final Nivel nivel;

  /// true: só a medalha redonda (para listas apertadas).
  final bool soEmoji;

  /// true: usa o título ("NÍVEL 2 • PROTETOR").
  final bool comTitulo;

  final double tamanhoFonte;

  const SeloNivel({
    super.key,
    required this.nivel,
    this.soEmoji = false,
    this.comTitulo = false,
    this.tamanhoFonte = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (nivel == Nivel.iniciante) return const SizedBox.shrink();
    if (soEmoji) {
      return Tooltip(
        message: '${nivel.rotulo} • ${nivel.titulo}',
        child: MedalhaNivel(nivel: nivel, tamanho: 18),
      );
    }
    final cor = corSobreMetal(nivel);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        gradient: nivel.degrade,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: nivel.cor.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(nivel.icone, size: tamanhoFonte + 3, color: cor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              comTitulo ? nivel.rotuloTitulo : nivel.rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: tamanhoFonte,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Medalha redonda com o ícone do nível.
class MedalhaNivel extends StatelessWidget {
  final Nivel nivel;
  final double tamanho;

  const MedalhaNivel({super.key, required this.nivel, this.tamanho = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: nivel.degrade,
        border: Border.all(color: Colors.white, width: tamanho * 0.08),
        boxShadow: [
          BoxShadow(color: nivel.cor.withValues(alpha: 0.4), blurRadius: 3),
        ],
      ),
      child: Icon(
        nivel.icone,
        size: tamanho * 0.58,
        color: corSobreMetal(nivel),
      ),
    );
  }
}

/// Anel metálico em volta da foto (vazio para Iniciante).
class MolduraNivel extends StatelessWidget {
  final Nivel nivel;
  final Widget child;
  final double espessura;

  const MolduraNivel({
    super.key,
    required this.nivel,
    required this.child,
    this.espessura = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (nivel == Nivel.iniciante) return child;
    return Container(
      padding: EdgeInsets.all(espessura),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: nivel.degrade,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: child,
      ),
    );
  }
}

/// Selo do nível de qualquer pessoa, buscado em tempo real.
class SeloNivelDe extends StatefulWidget {
  final String uid;
  final bool soEmoji;

  const SeloNivelDe({super.key, required this.uid, this.soEmoji = false});

  @override
  State<SeloNivelDe> createState() => _SeloNivelDeState();
}

class _SeloNivelDeState extends State<SeloNivelDe> {
  late final Stream<Nivel> _nivel = PrestigioService().nivel(widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Nivel>(
      stream: _nivel,
      builder: (context, snap) => SeloNivel(
        nivel: snap.data ?? Nivel.iniciante,
        soEmoji: widget.soEmoji,
      ),
    );
  }
}

/// Etiqueta do Perfil: "NÍVEL 1 • EXPLORADOR • 5 pets encontrados".
class EtiquetaPrestigio extends StatelessWidget {
  final int encontrados;
  final VoidCallback? onTap;

  const EtiquetaPrestigio({super.key, required this.encontrados, this.onTap});

  @override
  Widget build(BuildContext context) {
    final nivel = Nivel.deQuantidade(encontrados);
    final pets = encontrados == 1
        ? '1 pet encontrado'
        : '$encontrados pets encontrados';
    final iniciante = nivel == Nivel.iniciante;
    final texto = iniciante
        ? 'Ajude a encontrar ${Nivel.bronze.minimo} pets e vire '
              '${Nivel.bronze.titulo}!'
        : '${nivel.rotuloTitulo} • $pets';
    final cor = iniciante ? Colors.white : corSobreMetal(nivel);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: iniciante
              ? const LinearGradient(
                  colors: [AppColors.laranja, Color(0xFFFFA24D)],
                )
              : nivel.degrade,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(nivel.icone, size: 14, color: cor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão do Perfil: nível atual e progresso. Abre "Meus níveis".
class CartaoPrestigio extends StatefulWidget {
  final String uid;

  const CartaoPrestigio({super.key, required this.uid});

  @override
  State<CartaoPrestigio> createState() => _CartaoPrestigioState();
}

class _CartaoPrestigioState extends State<CartaoPrestigio> {
  late final Stream<int> _encontrados = PrestigioService().encontrados(
    widget.uid,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _encontrados,
      builder: (context, snap) {
        final n = snap.data ?? 0;
        final nivel = Nivel.deQuantidade(n);
        final proximo = nivel.proximo;
        final tema = Theme.of(context);
        return Material(
          color: tema.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeusNiveisScreen()),
            ),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tema.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MedalhaNivel(nivel: nivel, tamanho: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meus níveis',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              nivel == Nivel.iniciante
                                  ? 'Iniciante • ${n == 1 ? '1 pet encontrado' : '$n pets encontrados'}'
                                  : '${nivel.titulo} • ${n == 1 ? '1 pet encontrado' : '$n pets encontrados'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textoSecundario,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: nivel.progresso(n),
                      minHeight: 6,
                      backgroundColor: tema.colorScheme.surfaceContainerHighest,
                      color: (proximo ?? nivel).cor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    proximo == null
                        ? 'Você é uma Lenda! Obrigado por tanta ajuda 💜'
                        : 'Faltam ${nivel.faltamPara(n)} para '
                              '${proximo.titulo} (${proximo.nome})',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
