import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/pet_foto.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';

class AnimaisPerdidosScreen extends StatefulWidget {
  const AnimaisPerdidosScreen({super.key});

  @override
  State<AnimaisPerdidosScreen> createState() => _AnimaisPerdidosScreenState();
}

class _AnimaisPerdidosScreenState extends State<AnimaisPerdidosScreen> {
  String _filtroEspecie = 'Todos';
  final _buscaController = TextEditingController();

  // O stream é criado UMA vez só. Antes ele era recriado a cada setState
  // (ao digitar na busca ou trocar o filtro), o que fazia a lista ficar
  // presa no "carregando" e piscar.
  late final Stream<List<Pet>> _petsStream;

  @override
  void initState() {
    super.initState();
    _petsStream = PetService().listarPets();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

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
                    fillColor: cores.surface,
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
                              showCheckmark: false,
                              selectedColor: AppColors.laranjaClaro,
                              labelStyle: TextStyle(
                                color: _filtroEspecie == especie
                                    ? AppColors.laranja
                                    : AppColors.textoSecundario,
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: cores.surface,
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
              stream: _petsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _Mensagem(
                    icone: Icons.cloud_off_rounded,
                    texto:
                        'Não foi possível carregar os animais.\n${snapshot.error}',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pets = snapshot.data!;
                if (pets.isEmpty) {
                  return const _Mensagem(
                    icone: Icons.pets_rounded,
                    texto: 'Nenhum animal cadastrado ainda.',
                  );
                }

                final busca = _buscaController.text.trim().toLowerCase();
                final petsFiltrados = pets.where((pet) {
                  final especieOk =
                      _filtroEspecie == 'Todos' ||
                      pet.especie == _filtroEspecie;
                  final buscaOk =
                      busca.isEmpty || pet.nome.toLowerCase().contains(busca);
                  return especieOk && buscaOk;
                }).toList();

                if (petsFiltrados.isEmpty) {
                  return const _Mensagem(
                    icone: Icons.search_off_rounded,
                    texto: 'Nenhum pet encontrado com esse filtro.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: petsFiltrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final pet = petsFiltrados[index];
                    return PetCard(
                      key: ValueKey(pet.id),
                      pet: pet,
                      onTap: () => _abrirDetalhes(context, pet),
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

  void _abrirDetalhes(BuildContext context, Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DetalhesPet(pet: pet),
    );
  }
}

class _Mensagem extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _Mensagem({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: AppColors.textoSecundario),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatarData(DateTime d) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(d.day)}/${doisDigitos(d.month)}/${d.year}';
}

/// Card com a foto e as informações principais do pet.
class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;

  const PetCard({super.key, required this.pet, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: cores.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto com selos por cima
            Stack(
              children: [
                PetFoto(pet: pet, height: 190, width: double.infinity),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _Selo(
                    texto: pet.especie.isEmpty ? 'Pet' : pet.especie,
                    fundo: AppColors.azulMedio,
                    corTexto: Colors.white,
                  ),
                ),
                if (pet.recompensa != null && pet.recompensa! > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _Selo(
                      texto:
                          'Recompensa R\$ ${pet.recompensa!.toStringAsFixed(0)}',
                      fundo: AppColors.laranja,
                      corTexto: Colors.white,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.nome.isEmpty ? 'Sem nome' : pet.nome,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: cores.onSurface,
                    ),
                  ),
                  if (pet.racaCor.isNotEmpty)
                    Text(
                      pet.racaCor,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.azulMedio,
                      ),
                    ),
                  if (pet.descricao.isNotEmpty) ...[
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
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _InfoLinha(
                    icone: Icons.location_on_rounded,
                    texto: pet.localizacao.isEmpty
                        ? 'Local não informado'
                        : pet.localizacao,
                  ),
                  const SizedBox(height: 4),
                  _InfoLinha(
                    icone: Icons.calendar_today_rounded,
                    texto: 'Cadastrado em ${_formatarData(pet.criadoEm)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  final String texto;
  final Color fundo;
  final Color corTexto;

  const _Selo({
    required this.texto,
    required this.fundo,
    required this.corTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: corTexto,
        ),
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _InfoLinha({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Folha com todas as informações do pet (abre ao tocar no card).
class _DetalhesPet extends StatelessWidget {
  final Pet pet;

  const _DetalhesPet({required this.pet});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PetFoto(pet: pet, height: 260, width: double.infinity),
          ),
          const SizedBox(height: 16),
          Text(
            pet.nome.isEmpty ? 'Sem nome' : pet.nome,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cores.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _Campo(titulo: 'Espécie', valor: pet.especie),
          _Campo(titulo: 'Raça / cor', valor: pet.racaCor),
          _Campo(titulo: 'Descrição', valor: pet.descricao),
          _Campo(titulo: 'Última localização', valor: pet.localizacao),
          if (pet.recompensa != null && pet.recompensa! > 0)
            _Campo(
              titulo: 'Recompensa',
              valor: 'R\$ ${pet.recompensa!.toStringAsFixed(2)}',
            ),
          _Campo(titulo: 'Cadastrado em', valor: _formatarData(pet.criadoEm)),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Campo({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    if (valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textoSecundario,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
