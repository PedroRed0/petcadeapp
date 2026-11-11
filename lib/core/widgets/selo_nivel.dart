import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/nivel.dart';
import '../../services/prestigio_service.dart';
import '../theme/app_colors.dart';

/// Selo pequeno do nível: "🥇 Ouro". Iniciantes não mostram selo.
class SeloNivel extends StatelessWidget {
  final Nivel nivel;
  final bool soEmoji;

  const SeloNivel({super.key, required this.nivel, this.soEmoji = false});

  @override
  Widget build(BuildContext context) {
    if (nivel == Nivel.iniciante) return const SizedBox.shrink();
    if (soEmoji) {
      return Tooltip(
        message: 'Nível ${nivel.nome}',
        child: Text(nivel.emoji, style: const TextStyle(fontSize: 14)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: nivel.cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${nivel.emoji} ${nivel.nome}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: nivel.cor,
        ),
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

/// Cartão do Perfil: nível atual, quantos animais encontrou e o progresso.
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

  void _explicar(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Prestígio',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você ganha +1 quando um tutor confirma que você ajudou a '
              'encontrar o pet dele (avisando "Eu vi este pet" ou '
              'conversando pelo anúncio).',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final n in Nivel.values.skip(1))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${n.emoji}  ${n.nome}: ${n.minimo} animais',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

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
            onTap: () => _explicar(context),
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
                      Text(nivel.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prestígio ${nivel.nome}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              n == 1
                                  ? '1 animal encontrado'
                                  : '$n animais encontrados',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
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
                        ? 'Nível máximo! Obrigado por tanta ajuda 💜'
                        : 'Faltam ${nivel.faltamPara(n)} para '
                              '${proximo.emoji} ${proximo.nome}',
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
