import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/avatar_usuario.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/selo_nivel.dart';
import '../models/perfil_publico.dart';
import '../models/pet.dart';
import '../services/perfil_service.dart';
import '../services/pet_service.dart';
import '../services/prestigio_service.dart';

/// "Marcar como encontrado": pergunta quem ajudou (para dar prestígio),
/// finaliza o anúncio e avisa quem acompanhava.
Future<void> marcarComoEncontrado(BuildContext context, Pet pet) async {
  // null = cancelou; '' = ninguém do app; uid = quem ajudou
  final escolha = await abrirJanela<String>(
    context: context,
    builder: (_) => _QuemAjudou(pet: pet),
  );
  if (escolha == null || !context.mounted) return;
  try {
    await PetService().marcarEncontrado(pet);
    if (escolha.isNotEmpty) {
      await PrestigioService().registrarAjuda(pet, escolha);
    }
    if (context.mounted) {
      mostrarAviso(
        context,
        escolha.isEmpty
            ? 'Que ótima notícia! 🎉'
            : 'Que ótima notícia! 🎉 Quem ajudou ganhou +1 de prestígio.',
      );
    }
  } catch (e) {
    if (context.mounted) mostrarAviso(context, 'Erro: $e');
  }
}

class _QuemAjudou extends StatefulWidget {
  final Pet pet;

  const _QuemAjudou({required this.pet});

  @override
  State<_QuemAjudou> createState() => _QuemAjudouState();
}

class _QuemAjudouState extends State<_QuemAjudou> {
  late final Future<List<PerfilPublico>> _candidatos = _carregar();
  String? _selecionado; // '' = ninguém

  Future<List<PerfilPublico>> _carregar() async {
    final ids = await PrestigioService().candidatos(widget.pet);
    final perfis = await Future.wait(
      ids.map(
        (id) async =>
            await PerfilService().buscar(id) ??
            PerfilPublico(uid: id, nome: 'Usuário'),
      ),
    );
    return perfis;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.pet.nome} foi encontrado! 🎉',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Alguém do PetCadê ajudou? A pessoa ganha +1 de prestígio.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: FutureBuilder<List<PerfilPublico>>(
              future: _candidatos,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final lista = snap.data ?? [];
                return ListView(
                  shrinkWrap: true,
                  children: [
                    if (lista.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Ninguém avisou ou conversou sobre este anúncio ainda.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ),
                    for (final p in lista)
                      _Opcao(
                        selecionada: _selecionado == p.uid,
                        onTap: () => setState(() => _selecionado = p.uid),
                        leading: AvatarPerfil(perfil: p, raio: 20),
                        titulo: Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.nome.isEmpty ? 'Usuário' : p.nome,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            SeloNivelDe(uid: p.uid, soEmoji: true),
                          ],
                        ),
                      ),
                    _Opcao(
                      selecionada: _selecionado == '',
                      onTap: () => setState(() => _selecionado = ''),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.fundoDestaque(context),
                        child: Icon(
                          Icons.home_outlined,
                          size: 20,
                          color: AppColors.destaque(context),
                        ),
                      ),
                      titulo: const Text('Encontrei sem ajuda do app'),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _selecionado == null
                ? null
                : () => Navigator.pop(context, _selecionado),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  final bool selecionada;
  final VoidCallback onTap;
  final Widget leading;
  final Widget titulo;

  const _Opcao({
    required this.selecionada,
    required this.onTap,
    required this.leading,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: leading,
      title: DefaultTextStyle.merge(
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        child: titulo,
      ),
      trailing: Icon(
        selecionada
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        size: 20,
        color: selecionada ? AppColors.laranja : AppColors.textoSecundario,
      ),
    );
  }
}
