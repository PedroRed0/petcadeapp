import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatos.dart';
import '../../core/widgets/avatar_usuario.dart';
import '../../core/widgets/comuns.dart';
import '../../core/widgets/selo_nivel.dart';
import '../../models/conversa.dart';
import '../../models/perfil_publico.dart';
import '../../services/chat_service.dart';
import '../../services/firebase_refs.dart';
import '../../services/perfil_service.dart';
import 'chat_screen.dart';

/// Lista de conversas (como a "Direct" do Instagram).
class ConversasScreen extends StatefulWidget {
  const ConversasScreen({super.key});

  @override
  State<ConversasScreen> createState() => _ConversasScreenState();
}

class _ConversasScreenState extends State<ConversasScreen> {
  late final Stream<List<Conversa>> _conversas = ChatService()
      .minhasConversas();

  @override
  Widget build(BuildContext context) {
    final eu = Fb.auth.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Mensagens')),
      body: StreamBuilder<List<Conversa>>(
        stream: _conversas,
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
          final lista = snap.data!;
          if (lista.isEmpty) {
            return const EstadoVazio(
              icone: Icons.chat_bubble_outline_rounded,
              titulo: 'Nenhuma conversa ainda',
              texto:
                  'Abra um anúncio e toque no balão de conversa para falar '
                  'com o tutor.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: lista.length,
            itemBuilder: (context, i) => _ItemConversa(
              key: ValueKey(lista[i].id),
              conversa: lista[i],
              eu: eu,
            ),
          );
        },
      ),
    );
  }
}

class _ItemConversa extends StatefulWidget {
  final Conversa conversa;
  final String eu;

  const _ItemConversa({super.key, required this.conversa, required this.eu});

  @override
  State<_ItemConversa> createState() => _ItemConversaState();
}

class _ItemConversaState extends State<_ItemConversa> {
  late final String _outro = widget.conversa.outro(widget.eu);
  late final Stream<PerfilPublico?> _perfil = PerfilService().perfil(_outro);

  @override
  Widget build(BuildContext context) {
    final c = widget.conversa;
    final naoLida = c.naoLidaPor(widget.eu);
    final minha = c.ultimoAutor == widget.eu;
    return StreamBuilder<PerfilPublico?>(
      stream: _perfil,
      builder: (context, snap) {
        final p = snap.data;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversaId: c.id, outroId: _outro),
            ),
          ),
          leading: AvatarPerfil(perfil: p, raio: 26),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  p?.nome.isNotEmpty == true ? p!.nome : 'Usuário',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: naoLida ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SeloNivelDe(uid: _outro, soEmoji: true),
            ],
          ),
          subtitle: Text(
            [
              '${minha ? 'Você: ' : ''}${c.ultimaMensagem}',
              if (c.ultimoEnvio != null)
                formatarTempoRelativo(c.ultimoEnvio!).toLowerCase(),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: naoLida ? FontWeight.w600 : FontWeight.w400,
              color: naoLida
                  ? Theme.of(context).colorScheme.onSurface
                  : AppColors.textoSecundario,
            ),
          ),
          trailing: naoLida
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.laranja,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        );
      },
    );
  }
}
