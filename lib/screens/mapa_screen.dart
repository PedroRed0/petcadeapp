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

  const MapaScreen({super.key, this.especieInicial = 'Todos'});

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
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreviewPet(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inicio =
        LocalizacaoService.instancia.posicao.value ?? LocalizacaoService.padrao;

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
                    initialZoom: 13,
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
                        final pets = FiltroPets(
                          especie: _especie,
                          texto: _busca.text.trim(),
                        ).aplicar(snap.data ?? []).where((p) => p.temLocal);
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

  @override
  Widget build(BuildContext context) {
    final d = LocalizacaoService.instancia.distanciaAte(pet);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () {
            final navegador = Navigator.of(context);
            navegador.pop();
            navegador.push(
              MaterialPageRoute(builder: (_) => DetalhesPetScreen(pet: pet)),
            );
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PetFoto(pet: pet, width: 72, height: 72),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SeloStatus(pet: pet),
                    const SizedBox(height: 2),
                    Text(
                      pet.nome,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        pet.especieRaca,
                        if (d != null) formatarDistancia(d),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
