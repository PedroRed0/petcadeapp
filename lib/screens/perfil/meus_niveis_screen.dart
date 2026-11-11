import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_usuario.dart';
import '../../core/widgets/selo_nivel.dart';
import '../../models/nivel.dart';
import '../../models/usuario.dart';
import '../../services/prestigio_service.dart';
import '../../services/usuario_service.dart';

/// "Meus níveis": as quatro patentes com moldura metálica.
class MeusNiveisScreen extends StatefulWidget {
  const MeusNiveisScreen({super.key});

  @override
  State<MeusNiveisScreen> createState() => _MeusNiveisScreenState();
}

class _MeusNiveisScreenState extends State<MeusNiveisScreen> {
  late final Stream<Usuario?> _usuario = UsuarioService().usuarioAtual();
  late final Stream<int> _encontrados = PrestigioService().encontrados(
    UsuarioService().uid ?? '',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: StreamBuilder<Usuario?>(
        stream: _usuario,
        builder: (context, snapU) => StreamBuilder<int>(
          stream: _encontrados,
          builder: (context, snapN) {
            final n = snapN.data ?? 0;
            final atual = Nivel.deQuantidade(n);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'MEUS NÍVEIS',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.laranja,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.pets_rounded,
                      color: AppColors.laranja,
                      size: 26,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ganhe +1 quando um tutor confirmar que você ajudou a '
                  'encontrar o pet dele.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textoSecundario,
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: EtiquetaPrestigio(encontrados: n)),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.74,
                  children: [
                    for (final nivel in Nivel.patentes)
                      CartaoNivel(
                        nivel: nivel,
                        usuario: snapU.data,
                        encontrados: n,
                        atual: nivel == atual,
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Um card de patente com moldura metálica e etiqueta no topo.
class CartaoNivel extends StatelessWidget {
  final Nivel nivel;
  final Usuario? usuario;
  final int encontrados;
  final bool atual;

  const CartaoNivel({
    super.key,
    required this.nivel,
    required this.usuario,
    required this.encontrados,
    this.atual = false,
  });

  bool get desbloqueado => encontrados >= nivel.minimo;

  @override
  Widget build(BuildContext context) {
    final superficie = Theme.of(context).colorScheme.surface;
    final brilho = nivel == Nivel.ouro || nivel == Nivel.diamante;

    Widget card = Stack(
      clipBehavior: Clip.none,
      children: [
        // Moldura metálica
        Positioned.fill(
          top: 12,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: nivel.degrade,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: nivel.cor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: superficie,
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      child: AvatarUsuario(usuario: usuario, raio: 36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      nivel.titulo.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: nivel.cor,
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${nivel.minimo} pets encontrados',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                  if (atual) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.laranja,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'SEU NÍVEL',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Brilhos (ouro e diamante)
        if (brilho) ...[
          _brilho(top: 8, left: -3, tamanho: 14),
          _brilho(bottom: -4, right: 6, tamanho: 16),
          _brilho(top: 40, right: -5, tamanho: 10),
          _brilho(bottom: 30, left: -4, tamanho: 9),
        ],
        // Etiqueta "NÍVEL 1 • BRONZE"
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: nivel.degrade,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  nivel.rotulo,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: corSobreMetal(nivel),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (desbloqueado) return card;

    // Ainda bloqueado: cinza, com cadeado e quanto falta.
    final faltam = nivel.minimo - encontrados;
    return Stack(
      children: [
        Opacity(
          opacity: 0.55,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.33, 0.33, 0.33, 0, 0, //
              0.33, 0.33, 0.33, 0, 0, //
              0.33, 0.33, 0.33, 0, 0, //
              0, 0, 0, 1, 0, //
            ]),
            child: card,
          ),
        ),
        Positioned.fill(
          top: 12,
          left: 8,
          right: 8,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      faltam == 1 ? 'Falta 1 pet' : 'Faltam $faltam pets',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _brilho({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double tamanho,
  }) => Positioned(
    top: top,
    left: left,
    right: right,
    bottom: bottom,
    child: Icon(
      Icons.auto_awesome,
      size: tamanho,
      color: nivel == Nivel.diamante
          ? const Color(0xFF8FDCFF)
          : const Color(0xFFFFE07A),
    ),
  );
}
