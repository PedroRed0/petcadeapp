import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/pet.dart';
import '../theme/app_colors.dart';

/// Pequeno selo "Perdido" / "Encontrado".
class SeloStatus extends StatelessWidget {
  final Pet pet;

  const SeloStatus({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final perdido = pet.perdido;
    final cor = perdido ? AppColors.perdido : AppColors.encontrado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            perdido ? Icons.search_rounded : Icons.check_rounded,
            size: 12,
            color: cor,
          ),
          const SizedBox(width: 4),
          Text(
            perdido ? 'Perdido' : 'Encontrado',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
