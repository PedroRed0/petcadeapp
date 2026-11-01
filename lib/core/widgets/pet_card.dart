import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/pet.dart';
import '../../services/localizacao_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatos.dart';
import 'pet_foto.dart';
import 'selo_status.dart';

/// Card horizontal: foto à esquerda, informações à direita.
class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final bool mostrarSeta;

  const PetCard({
    super.key,
    required this.pet,
    this.onTap,
    this.mostrarSeta = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final secundario = AppColors.textoSecundario;
    final estiloInfo = GoogleFonts.poppins(fontSize: 12, color: secundario);

    return Material(
      color: tema.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tema.colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PetFoto(pet: pet, width: 96, height: 112),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SeloStatus(pet: pet),
                        const Spacer(),
                        if (mostrarSeta)
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: secundario,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.nome.isEmpty ? 'Sem nome' : pet.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tema.colorScheme.onSurface,
                      ),
                    ),
                    if (pet.especieRaca.isNotEmpty)
                      Text(
                        pet.especieRaca,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.destaque(context),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'Visto em ${formatarData(pet.vistoEm)}',
                      style: estiloInfo,
                    ),
                    if (pet.localizacao.isNotEmpty)
                      Text(
                        pet.localizacao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estiloInfo,
                      ),
                    ValueListenableBuilder<LatLng?>(
                      valueListenable: LocalizacaoService.instancia.posicao,
                      builder: (context, _, _) {
                        final d = LocalizacaoService.instancia.distanciaAte(
                          pet,
                        );
                        if (d == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.laranja,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                formatarDistancia(d),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tema.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
