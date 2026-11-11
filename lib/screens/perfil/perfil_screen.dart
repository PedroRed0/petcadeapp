import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar_usuario.dart';
import '../../core/widgets/comuns.dart';
import '../../core/widgets/selo_nivel.dart';
import '../chat/conversas_screen.dart';
import '../../models/pet.dart';
import '../../models/usuario.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../services/usuario_service.dart';
import '../detalhes_pet_screen.dart';
import 'ajuda_screen.dart';
import 'animais_salvos_screen.dart';
import 'configuracoes_screen.dart';
import 'editar_perfil_screen.dart';
import 'meus_anuncios_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final Stream<Usuario?> _usuario;
  late final Stream<List<Pet>> _meus;

  @override
  void initState() {
    super.initState();
    final servico = UsuarioService();
    _usuario = servico.usuarioAtual();
    _meus = PetService().meusPets(servico.uid ?? '');
  }

  void _abrir(Widget tela) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => tela));

  Future<void> _sair() async {
    final ok = await confirmar(
      context,
      titulo: 'Sair da conta?',
      texto: 'Você poderá entrar de novo quando quiser.',
      acao: 'Sair',
      perigo: true,
    );
    if (ok) await AuthService().sair();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<Usuario?>(
        stream: _usuario,
        builder: (context, snap) {
          final u = snap.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Row(
                children: [
                  AvatarEditavel(usuario: u),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u?.nome.isNotEmpty == true ? u!.nome : 'Usuário',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          u?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: u == null
                                ? null
                                : () => _abrir(EditarPerfilScreen(usuario: u)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              foregroundColor: AppColors.destaque(context),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: const Text('Editar perfil'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CartaoPrestigio(uid: UsuarioService().uid ?? ''),
              const SizedBox(height: 10),
              LinhaOpcao(
                icone: Icons.chat_bubble_outline_rounded,
                titulo: 'Mensagens',
                onTap: () => _abrir(const ConversasScreen()),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Pet>>(
                stream: _meus,
                builder: (context, s) {
                  final ativos = (s.data ?? []).where((p) => p.perdido).length;
                  return LinhaOpcao(
                    icone: Icons.pets_rounded,
                    titulo: 'Meus anúncios',
                    subtitulo: ativos == 1
                        ? '1 anúncio ativo'
                        : '$ativos anúncios ativos',
                    onTap: () => _abrir(const MeusAnunciosScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              LinhaOpcao(
                icone: Icons.favorite_border_rounded,
                titulo: 'Animais salvos',
                subtitulo: () {
                  final n = u?.favoritos.length ?? 0;
                  return n == 1 ? '1 animal' : '$n animais';
                }(),
                onTap: () => _abrir(const AnimaisSalvosScreen()),
              ),
              const SizedBox(height: 10),
              LinhaOpcao(
                icone: Icons.settings_outlined,
                titulo: 'Configurações',
                onTap: () => _abrir(const ConfiguracoesScreen()),
              ),
              const SizedBox(height: 10),
              LinhaOpcao(
                icone: Icons.help_outline_rounded,
                titulo: 'Ajuda e suporte',
                onTap: () => _abrir(const AjudaScreen()),
              ),
              const SizedBox(height: 10),
              LinhaOpcao(
                icone: Icons.logout_rounded,
                titulo: 'Sair',
                cor: AppColors.perdido,
                trailing: const SizedBox.shrink(),
                onTap: _sair,
              ),
            ],
          );
        },
      ),
    );
  }
}
