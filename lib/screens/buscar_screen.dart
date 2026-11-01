import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/comuns.dart';
import '../models/filtro_pets.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import 'animais_perdidos_screen.dart';
import 'mapa_screen.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _texto = TextEditingController();
  FiltroPets _filtro = const FiltroPets();
  late final Stream<List<Pet>> _pets;

  @override
  void initState() {
    super.initState();
    _pets = PetService().listarPets();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _aplicar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimaisPerdidosScreen(
          titulo: 'Resultados',
          filtro: _filtro.copyWith(texto: _texto.text.trim()),
        ),
      ),
    );
  }

  void _limpar() {
    _texto.clear();
    setState(() => _filtro = const FiltroPets());
  }

  Future<void> _escolher({
    required String titulo,
    required List<String> opcoes,
    required String atual,
    required ValueChanged<String> onEscolher,
  }) async {
    final escolha = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ListaOpcoes(titulo: titulo, opcoes: opcoes, atual: atual),
    );
    if (escolha != null) onEscolher(escolha == 'Todos' ? '' : escolha);
  }

  Future<void> _escolherRegiao() async {
    final controller = TextEditingController(text: _filtro.regiao);
    final regiao = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Região',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Bairro ou cidade (ex.: Itaquera)',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Confirmar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Qualquer região'),
            ),
          ],
        ),
      ),
    );
    if (regiao != null) setState(() => _filtro = _filtro.copyWith(regiao: regiao));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar'),
          actions: [
            IconButton(
              tooltip: 'Ver no mapa',
              icon: const Icon(Icons.map_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapaScreen(especieInicial: _filtro.especie),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            CampoBusca(controller: _texto, onSubmitted: (_) => _aplicar()),
            const SizedBox(height: 14),
            FiltroEspecie(
              valor: _filtro.especie,
              onChanged: (e) =>
                  setState(() => _filtro = _filtro.copyWith(especie: e)),
            ),
            const SizedBox(height: 18),
            LinhaOpcao(
              icone: Icons.location_on_outlined,
              titulo: 'Região',
              subtitulo: _filtro.regiao.isEmpty ? 'Todas' : _filtro.regiao,
              onTap: _escolherRegiao,
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Pet>>(
              stream: _pets,
              builder: (context, snap) {
                // Raças que já foram cadastradas
                final racas = {
                  for (final p in snap.data ?? <Pet>[])
                    if (p.raca.trim().isNotEmpty &&
                        (_filtro.especie == 'Todos' ||
                            p.especie == _filtro.especie))
                      p.raca.trim(),
                }.toList()..sort();
                return LinhaOpcao(
                  icone: Icons.pets_rounded,
                  titulo: 'Raça',
                  subtitulo: _filtro.raca.isEmpty ? 'Todas' : _filtro.raca,
                  onTap: () => _escolher(
                    titulo: 'Raça',
                    opcoes: ['Todos', ...racas],
                    atual: _filtro.raca,
                    onEscolher: (v) =>
                        setState(() => _filtro = _filtro.copyWith(raca: v)),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            LinhaOpcao(
              icone: Icons.straighten_rounded,
              titulo: 'Porte',
              subtitulo: _filtro.porte.isEmpty ? 'Todos' : _filtro.porte,
              onTap: () => _escolher(
                titulo: 'Porte',
                opcoes: const ['Todos', 'Pequeno', 'Médio', 'Grande'],
                atual: _filtro.porte,
                onEscolher: (v) =>
                    setState(() => _filtro = _filtro.copyWith(porte: v)),
              ),
            ),
            const SizedBox(height: 10),
            LinhaOpcao(
              icone: Icons.transgender_rounded,
              titulo: 'Sexo',
              subtitulo: _filtro.sexo.isEmpty ? 'Todos' : _filtro.sexo,
              onTap: () => _escolher(
                titulo: 'Sexo',
                opcoes: const ['Todos', 'Macho', 'Fêmea'],
                atual: _filtro.sexo,
                onEscolher: (v) =>
                    setState(() => _filtro = _filtro.copyWith(sexo: v)),
              ),
            ),
            const SizedBox(height: 10),
            LinhaOpcao(
              icone: Icons.sort_rounded,
              titulo: 'Ordenar por',
              subtitulo: _filtro.ordenacao == Ordenacao.recentes
                  ? 'Mais recentes'
                  : 'Mais próximos',
              onTap: () => _escolher(
                titulo: 'Ordenar por',
                opcoes: const ['Mais recentes', 'Mais próximos'],
                atual: _filtro.ordenacao == Ordenacao.recentes
                    ? 'Mais recentes'
                    : 'Mais próximos',
                onEscolher: (v) => setState(
                  () => _filtro = _filtro.copyWith(
                    ordenacao: v == 'Mais próximos'
                        ? Ordenacao.proximos
                        : Ordenacao.recentes,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _aplicar,
              child: const Text('Aplicar filtros'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _limpar,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textoSecundario,
              ),
              child: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaOpcoes extends StatelessWidget {
  final String titulo;
  final List<String> opcoes;
  final String atual;

  const _ListaOpcoes({
    required this.titulo,
    required this.opcoes,
    required this.atual,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                for (final o in opcoes)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(o, style: GoogleFonts.poppins(fontSize: 14)),
                    trailing:
                        (o == atual || (atual.isEmpty && o == 'Todos'))
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.laranja,
                            size: 20,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, o),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
