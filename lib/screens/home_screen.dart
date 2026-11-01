import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatos.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/pet_card.dart';
import '../models/filtro_pets.dart';
import '../models/pet.dart';
import '../models/usuario.dart';
import '../services/localizacao_service.dart';
import '../services/pet_service.dart';
import '../services/usuario_service.dart';
import 'animais_perdidos_screen.dart';
import 'detalhes_pet_screen.dart';
import 'main_shell.dart';
import 'mapa_screen.dart';

class HomeScreen extends StatefulWidget {
  final Stream<int> naoLidas;

  const HomeScreen({super.key, required this.naoLidas});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Pet>> _pets;
  late final Stream<Usuario?> _usuario;

  @override
  void initState() {
    super.initState();
    _pets = PetService().listarPets();
    _usuario = UsuarioService().usuarioAtual();
  }

  void _abrirLista([String texto = '']) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimaisPerdidosScreen(
          titulo: texto.isEmpty ? 'Animais perdidos' : 'Resultados',
          filtro: FiltroPets(texto: texto, ordenacao: Ordenacao.proximos),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverList.list(
              children: [
                // Saudação + sino
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<Usuario?>(
                        stream: _usuario,
                        builder: (context, snap) {
                          final nome = primeiroNome(snap.data?.nome ?? '');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome.isEmpty ? 'Olá!' : 'Olá, $nome!',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Juntos somos mais fortes!',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textoSecundario,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    StreamBuilder<int>(
                      stream: widget.naoLidas,
                      builder: (context, snap) => IconButton(
                        onPressed: () => MainShell.irPara(
                          context,
                          MainShell.abaNotificacoes,
                        ),
                        icon: Badge(
                          isLabelVisible: (snap.data ?? 0) > 0,
                          backgroundColor: AppColors.perdido,
                          label: Text('${snap.data ?? 0}'),
                          child: const Icon(Icons.notifications_none_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CampoBusca(onSubmitted: (t) => _abrirLista(t.trim())),
                const SizedBox(height: 16),
                _BannerAjude(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapaScreen()),
                  ),
                ),
                const SizedBox(height: 24),
                TituloSecao(
                  titulo: 'Animais perdidos próximos',
                  acao: 'Ver todos',
                  onAcao: _abrirLista,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          StreamBuilder<List<Pet>>(
            stream: _pets,
            builder: (context, snap) {
              if (snap.hasError) {
                return SliverToBoxAdapter(
                  child: EstadoVazio(
                    icone: Icons.cloud_off_rounded,
                    titulo: 'Não foi possível carregar',
                    texto: '${snap.error}',
                  ),
                );
              }
              if (!snap.hasData) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return ValueListenableBuilder(
                valueListenable: LocalizacaoService.instancia.posicao,
                builder: (context, posicao, _) {
                  final pets = const FiltroPets(
                    ordenacao: Ordenacao.proximos,
                  ).aplicar(snap.data!, posicao: posicao).take(10).toList();

                  if (pets.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: EstadoVazio(
                        icone: Icons.pets_rounded,
                        titulo: 'Nenhum animal perdido',
                        texto: 'Toque no + para cadastrar um anúncio.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: pets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => PetCard(
                        key: ValueKey(pets[i].id),
                        pet: pets[i],
                        onTap: () => abrirDetalhesPet(context, pets[i]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BannerAjude extends StatelessWidget {
  final VoidCallback onTap;

  const _BannerAjude({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.laranja,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajude a encontrar!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Veja no mapa os animais desaparecidos perto de você.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
