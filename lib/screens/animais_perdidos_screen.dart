import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../core/widgets/theme_toggle_button.dart';

class AnimaisPerdidosScreen extends StatefulWidget {
  const AnimaisPerdidosScreen({super.key});

  @override
  State<AnimaisPerdidosScreen> createState() => _AnimaisPerdidosScreenState();
}

class _AnimaisPerdidosScreenState extends State<AnimaisPerdidosScreen> {
  String _filtroEspecie = 'Todos';
  final _buscaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Animais Desaparecidos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Busca + filtro
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                TextField(
                  controller: _buscaController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar pelo nome do pet',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.azulMedio,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Todos', 'Cachorro', 'Gato', 'Outro']
                        .map(
                          (especie) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                especie,
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              selected: _filtroEspecie == especie,
                              selectedColor: AppColors.laranjaClaro,
                              labelStyle: TextStyle(
                                color: _filtroEspecie == especie
                                    ? AppColors.laranja
                                    : AppColors.textoSecundario,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _filtroEspecie == especie
                                      ? AppColors.laranja
                                      : Colors.grey.shade300,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _filtroEspecie = especie),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // Lista de cards
          Expanded(
            child: StreamBuilder<List<Pet>>(
              stream: PetService().listarPets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar: ${snapshot.error}',
                      style: GoogleFonts.poppins(
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  );
                }

                final pets = snapshot.data ?? [];
                final petsFiltrados = pets.where((pet) {
                  final especieOk =
                      _filtroEspecie == 'Todos' ||
                      pet.especie == _filtroEspecie;
                  final buscaOk =
                      _buscaController.text.isEmpty ||
                      pet.nome.toLowerCase().contains(
                        _buscaController.text.toLowerCase(),
                      );
                  return especieOk && buscaOk;
                }).toList();

                if (petsFiltrados.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum pet encontrado com esse filtro.',
                      style: GoogleFonts.poppins(
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: petsFiltrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      _PetCard(pet: petsFiltrados[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;

  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              pet.fotoUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: AppColors.laranjaClaro.withValues(alpha: 0.4),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 40,
                  color: AppColors.laranja,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${pet.nome} · ${pet.especie}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (pet.recompensa != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.laranjaClaro,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Recompensa: R\$ ${pet.recompensa!.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.azulEscuro,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  pet.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textoSecundario,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pet.localizacao,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: navegar até a tela do mapa centralizada nesse pet
                      },
                      icon: const Icon(
                        Icons.map_rounded,
                        size: 16,
                        color: AppColors.azulMedio,
                      ),
                      label: Text(
                        'Ver no mapa',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.azulMedio,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
