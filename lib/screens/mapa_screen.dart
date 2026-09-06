import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/theme/app_colors.dart';
import '../models/pet.dart';
import '../core/widgets/theme_toggle_button.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();

  // Centro aproximado de São Paulo
  static const LatLng _centroSP = LatLng(-23.5610, -46.5250);

  get petsMock => null;

  void _abrirDetalhesPet(Pet pet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PetPreviewSheet(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mapa de Animais Desaparecidos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _centroSP,
              initialZoom: 11.5,
              minZoom: 4,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.petcade',
              ),
              MarkerLayer(
                markers: petsMock
                    .map(
                      (pet) => Marker(
                        point: LatLng(pet.latitude, pet.longitude),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _abrirDetalhesPet(pet),
                          child: _PetPin(especie: pet.especie),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),

          // Legenda flutuante no topo
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Visualize os pets perdidos próximos a você',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ),

          // Botões de zoom
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                _BotaoMapa(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _BotaoMapa(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
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

class _PetPin extends StatelessWidget {
  final String especie;

  const _PetPin({required this.especie});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.laranja,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6),
            ],
          ),
          child: Icon(
            especie == 'Gato' ? Icons.pets_rounded : Icons.pets_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        CustomPaint(size: const Size(10, 6), painter: _TrianguloPainter()),
      ],
    );
  }
}

class _TrianguloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.laranja;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BotaoMapa extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BotaoMapa({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.azulEscuro),
        ),
      ),
    );
  }
}

class _PetPreviewSheet extends StatelessWidget {
  final Pet pet;

  const _PetPreviewSheet({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              pet.fotoUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppColors.laranjaClaro.withOpacity(0.4),
                child: const Icon(Icons.pets_rounded, color: AppColors.laranja),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pet.nome} · ${pet.especie}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pet.localizacao,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textoSecundario,
                  ),
                ),
                if (pet.recompensa != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Recompensa: R\$ ${pet.recompensa!.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.laranja,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
