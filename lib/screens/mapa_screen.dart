import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../core/theme/app_colors.dart';
import '../core/utils/formatos.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/pet_foto.dart';
import '../core/widgets/selo_status.dart';
import '../models/filtro_pets.dart';
import '../models/pet.dart';
import '../services/localizacao_service.dart';
import '../services/pet_service.dart';
import 'detalhes_pet_screen.dart';

class MapaScreen extends StatefulWidget {
  final String especieInicial;

  /// Abre o mapa já centralizado neste pet (botão da página do pet).
  final Pet? foco;

  const MapaScreen({super.key, this.especieInicial = 'Todos', this.foco});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapa = MapController();
  final _busca = TextEditingController();
  late final Stream<List<Pet>> _pets;
  late String _especie;

  @override
  void initState() {
    super.initState();
    _pets = PetService().listarPets();
    _especie = widget.especieInicial;
    final foco = widget.foco;
    if (foco != null && foco.temLocal) {
      // Mostra o card do pet assim que o mapa aparece.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _abrirPreview(foco);
      });
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _irParaMinhaPosicao() async {
    final p = await LocalizacaoService.instancia.atualizar();
    if (!mounted) return;
    if (p == null) {
      mostrarAviso(context, 'Não foi possível obter sua localização.');
      return;
    }
    _mapa.move(p, 15);
  }

  void _abrirPreview(Pet pet) {
    abrirJanela(
      context: context,
      telaCheia: false,
      builder: (_) => _PreviewPet(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foco = widget.foco;
    final focoNoMapa = foco != null && foco.temLocal;
    final inicio = focoNoMapa
        ? LatLng(foco.latitude, foco.longitude)
        : LocalizacaoService.instancia.posicao.value ??
              LocalizacaoService.padrao;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de casos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: CampoBusca(
              dica: 'Buscar por nome, raça ou bairro',
              controller: _busca,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapa,
                  options: MapOptions(
                    initialCenter: inicio,
                    initialZoom: focoNoMapa ? 16 : 13,
                    minZoom: 4,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.petcade',
                    ),
                    // Minha posição (ponto roxo)
                    ValueListenableBuilder<LatLng?>(
                      valueListenable: LocalizacaoService.instancia.posicao,
                      builder: (context, p, _) => MarkerLayer(
                        markers: [
                          if (p != null)
                            Marker(
                              point: p,
                              width: 22,
                              height: 22,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.roxo,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.roxo.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    StreamBuilder<List<Pet>>(
                      stream: _pets,
                      builder: (context, snap) {
                        final pets =
                            FiltroPets(
                                  especie: _especie,
                                  texto: _busca.text.trim(),
                                )
                                .aplicar(snap.data ?? [])
                                .where((p) => p.temLocal)
                                .toList();
                        // O pet em foco aparece mesmo fora dos filtros.
                        if (focoNoMapa && !pets.any((p) => p.id == foco.id)) {
                          pets.add(foco);
                        }
                        return MarkerLayer(
                          markers: pets
                              .map(
                                (pet) => Marker(
                                  point: LatLng(pet.latitude, pet.longitude),
                                  width: 40,
                                  height: 48,
                                  alignment: Alignment.topCenter,
                                  child: GestureDetector(
                                    onTap: () => _abrirPreview(pet),
                                    child: _Pin(pet: pet),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                // Filtros
                Positioned(
                  left: 16,
                  bottom: 20,
                  right: 80,
                  child: FiltroEspecie(
                    valor: _especie,
                    onChanged: (e) => setState(() => _especie = e),
                  ),
                ),
                // Minha localização
                Positioned(
                  right: 16,
                  bottom: 20,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _irParaMinhaPosicao,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.my_location_rounded,
                          size: 22,
                          color: AppColors.destaque(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pin laranja com o ícone da espécie.
class _Pin extends StatelessWidget {
  final Pet pet;

  const _Pin({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.laranja, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipOval(
            child: pet.fotos.isNotEmpty
                ? PetFoto(pet: pet, width: 36, height: 36)
                : const Icon(
                    Icons.pets_rounded,
                    size: 16,
                    color: AppColors.laranja,
                  ),
          ),
        ),
        CustomPaint(size: const Size(10, 7), painter: _Triangulo()),
      ],
    );
  }
}

class _Triangulo extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.laranja);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreviewPet extends StatelessWidget {
  final Pet pet;

  const _PreviewPet({required this.pet});

  void _abrirDetalhes(BuildContext context) {
    final navegador = Navigator.of(context);
    navegador.pop();
    navegador.push(
      MaterialPageRoute(builder: (_) => DetalhesPetScreen(pet: pet)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = LocalizacaoService.instancia.distanciaAte(pet);
    final secundario = GoogleFonts.poppins(
      fontSize: 12,
      color: AppColors.textoSecundario,
    );

    Widget info(IconData icone, String texto) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icone, size: 14, color: AppColors.textoSecundario),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: secundario,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: PetFoto(pet: pet, width: 88, height: 88),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SeloStatus(pet: pet),
                    const SizedBox(height: 4),
                    Text(
                      pet.nome.isEmpty ? 'Sem nome' : pet.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (pet.especieRaca.isNotEmpty)
                      Text(
                        pet.especieRaca,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.destaque(context),
                        ),
                      ),
                    if (pet.localizacao.isNotEmpty)
                      info(Icons.location_on_outlined, pet.localizacao),
                    info(
                      Icons.schedule_rounded,
                      [
                        'Visto em ${formatarData(pet.vistoEm)}',
                        if (d != null) '${formatarDistancia(d)} de você',
                      ].join(' · '),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _abrirDetalhes(context),
            child: const Text('Ver detalhes'),
          ),
        ],
      ),
    );
  }
}
