import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatos.dart';
import '../core/widgets/comuns.dart';
import '../models/notificacao.dart';
import '../services/notificacao_service.dart';
import '../services/pet_service.dart';
import '../core/widgets/avatar_usuario.dart';
import '../core/widgets/selo_nivel.dart';
import '../models/nivel.dart';
import '../models/perfil_publico.dart';
import '../services/perfil_service.dart';
import '../services/prestigio_service.dart';
import 'chat/chat_screen.dart';
import 'perfil/meus_niveis_screen.dart';
import 'detalhes_pet_screen.dart';

class NotificacoesScreen extends StatefulWidget {
  /// Quando a aba fica visível, marcamos as notificações como lidas.
  final bool visivel;

  const NotificacoesScreen({super.key, required this.visivel});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  final _servico = NotificacaoService();
  late final Stream<List<Notificacao>> _lista;
  List<Notificacao> _ultimas = [];

  @override
  void initState() {
    super.initState();
    _lista = _servico.minhas();
  }

  @override
  void didUpdateWidget(covariant NotificacoesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Saiu da aba: marca como lidas o que foi visto.
    if (oldWidget.visivel && !widget.visivel) {
      _servico.marcarTodasComoLidas(_ultimas);
    }
  }

  Future<void> _abrir(Notificacao n) async {
    if (n.petId.isEmpty) return;
    final pet = await PetService().pet(n.petId).first;
    if (!mounted) return;
    if (pet == null) {
      mostrarAviso(context, 'Esse anúncio não existe mais.');
      return;
    }
    abrirDetalhesPet(context, pet);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Notificações')),
        body: StreamBuilder<List<Notificacao>>(
          stream: _lista,
          builder: (context, snap) {
            if (snap.hasError) {
              return EstadoVazio(
                icone: Icons.cloud_off_rounded,
                titulo: 'Não foi possível carregar',
                texto: '${snap.error}',
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            _ultimas = snap.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (_ultimas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40, bottom: 24),
                    child: EstadoVazio(
                      icone: Icons.notifications_none_rounded,
                      titulo: 'Nenhuma notificação por enquanto',
                      texto: 'Quando alguém avistar um pet seu, você será avisado aqui.',
                    ),
                  ),
                for (final n in _ultimas) ...[
                  Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _servico.excluir(n),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.perdido.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.perdido,
                      ),
                    ),
                    child: _CartaoNotificacao(
                      notificacao: n,
                      onTap: () => _abrir(n),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const _CartaoDica(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartaoNotificacao extends StatelessWidget {
  final Notificacao notificacao;
  final VoidCallback onTap;

  const _CartaoNotificacao({required this.notificacao, required this.onTap});

  /// Card laranja "Patente desbloqueada".
  Widget _cartaoPatente(BuildContext context, Nivel nivel) {
    final n = notificacao;
    return Material(
      color: AppColors.laranja,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MeusNiveisScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFD96A00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 26,
                  color: Color(0xFF1C1A27),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1A27),
                      ),
                    ),
                    Text(
                      n.mensagem,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF1C1A27),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SeloNivel(nivel: nivel, comTitulo: true),
                  ],
                ),
              ),
              if (!n.lida)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = notificacao;
    final patente = Nivel.values
        .where((v) => v.name == n.patente && v != Nivel.iniciante)
        .firstOrNull;
    if (patente != null) return _cartaoPatente(context, patente);
    final encontrado = n.tipo == Notificacao.tipoEncontrado;
    final ajuda = n.tipo == Notificacao.tipoAjuda;
    final cor = ajuda
        ? const Color(0xFFD9A400)
        : encontrado
        ? AppColors.encontrado
        : AppColors.destaque(context);
    final tema = Theme.of(context);

    return Material(
      color: n.lida
          ? tema.colorScheme.surface
          : tema.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tema.colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (n.tipo == Notificacao.tipoAvistamento && n.autorId.isNotEmpty)
                _AvatarComNivel(uid: n.autorId)
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ajuda
                        ? Icons.emoji_events_outlined
                        : encontrado
                        ? Icons.favorite_rounded
                        : Icons.visibility_outlined,
                    size: 20,
                    color: cor,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.titulo,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!n.lida)
                          Container(
                            margin: const EdgeInsets.only(left: 6, top: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.laranja,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.mensagem,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatarTempoRelativo(n.criadoEm),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    if (n.telefone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.destaque(context),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: SelectableText(
                              n.telefone,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.destaque(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (n.tipo == Notificacao.tipoAvistamento &&
                        n.autorId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => abrirConversaCom(context, n.autorId),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                          ),
                          label: const Text('Conversar'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card fixo com dicas de busca.
class _CartaoDica extends StatelessWidget {
  const _CartaoDica();

  static const _dicas = [
    'Procure nas redondezas logo nas primeiras horas, chamando pelo nome.',
    'Avise vizinhos, porteiros, pet shops e clínicas veterinárias da região.',
    'Compartilhe o anúncio em grupos do bairro.',
    'Use fotos nítidas e descreva marcas, coleira e comportamento.',
    'Deixe um objeto com o cheiro do pet (ou o seu) na porta de casa.',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.laranjaClaro,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.laranja.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 20,
                color: AppColors.laranja,
              ),
            ),
            title: Text(
              'Dicas de busca',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textoPrincipal,
              ),
            ),
            subtitle: Text(
              'Aumente as chances de encontrar seu pet',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textoSecundario,
              ),
            ),
            iconColor: AppColors.laranja,
            collapsedIconColor: AppColors.laranja,
            children: [
              for (final d in _dicas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.circle,
                          size: 5,
                          color: AppColors.laranja,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto de quem enviou, com a etiqueta "NÍVEL 2 • PRATA" embaixo.
class _AvatarComNivel extends StatefulWidget {
  final String uid;

  const _AvatarComNivel({required this.uid});

  @override
  State<_AvatarComNivel> createState() => _AvatarComNivelState();
}

class _AvatarComNivelState extends State<_AvatarComNivel> {
  late final Stream<PerfilPublico?> _perfil = PerfilService().perfil(
    widget.uid,
  );
  late final Stream<Nivel> _nivel = PrestigioService().nivel(widget.uid);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: StreamBuilder<Nivel>(
        stream: _nivel,
        builder: (context, snapN) {
          final nivel = snapN.data ?? Nivel.iniciante;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<PerfilPublico?>(
                stream: _perfil,
                builder: (context, snapP) => MolduraNivel(
                  nivel: nivel,
                  espessura: 2,
                  child: AvatarPerfil(perfil: snapP.data, raio: 22),
                ),
              ),
              if (nivel != Nivel.iniciante)
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: FittedBox(
                    child: SeloNivel(nivel: nivel, tamanhoFonte: 8),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
