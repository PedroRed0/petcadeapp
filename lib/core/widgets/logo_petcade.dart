import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo simples: um pin de localização com uma patinha.
/// (Se quiser usar a sua imagem de logo, troque este widget por
/// Image.asset('assets/logo.png', height: tamanho).)
class LogoPetcade extends StatelessWidget {
  final double tamanho;

  const LogoPetcade({super.key, this.tamanho = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: tamanho,
            color: AppColors.laranja,
          ),
          Positioned(
            top: tamanho * 0.2,
            child: Container(
              width: tamanho * 0.4,
              height: tamanho * 0.4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_rounded,
                size: tamanho * 0.24,
                color: AppColors.roxo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
