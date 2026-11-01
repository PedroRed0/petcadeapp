import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/pet_card.dart';
import '../models/filtro_pets.dart';
import '../models/pet.dart';
import '../services/localizacao_service.dart';
import '../services/pet_service.dart';
import 'detalhes_pet_screen.dart';

/// Lista de animais perdidos com um filtro aplicado
/// ("Ver todos", resultado da busca, etc).
class AnimaisPerdidosScreen extends StatefulWidget {
  final String titulo;
  final FiltroPets filtro;

  const AnimaisPerdidosScreen({
    super.key,
    this.titulo = 'Animais perdidos',
    this.filtro = const FiltroPets(),
  });

  @override
  State<AnimaisPerdidosScreen> createState() => _AnimaisPerdidosScreenState();
}

class _AnimaisPerdidosScreenState extends State<AnimaisPerdidosScreen> {
  late final Stream<List<Pet>> _pets;
  late FiltroPets _filtro;

  @override
  void initState() {
    super.initState();
    _pets = PetService().listarPets();
    _filtro = widget.filtro;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: FiltroEspecie(
              valor: _filtro.especie,
              onChanged: (e) =>
                  setState(() => _filtro = _filtro.copyWith(especie: e)),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Pet>>(
              stream: _pets,
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
                return ValueListenableBuilder(
                  valueListenable: LocalizacaoService.instancia.posicao,
                  builder: (context, posicao, _) {
                    final pets = _filtro.aplicar(snap.data!, posicao: posicao);
                    if (pets.isEmpty) {
                      return const EstadoVazio(
                        icone: Icons.search_off_rounded,
                        titulo: 'Nenhum animal encontrado',
                        texto: 'Tente mudar os filtros da busca.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: pets.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Text(
                            pets.length == 1
                                ? '1 animal encontrado'
                                : '${pets.length} animais encontrados',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textoSecundario,
                            ),
                          );
                        }
                        final pet = pets[i - 1];
                        return PetCard(
                          key: ValueKey(pet.id),
                          pet: pet,
                          onTap: () => abrirDetalhesPet(context, pet),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
