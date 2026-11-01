import 'package:flutter/material.dart';

/// Logo do PetCadê (assets/logo.png).
class LogoPetcade extends StatelessWidget {
  final double tamanho;

  const LogoPetcade({super.key, this.tamanho = 88});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: tamanho,
      height: tamanho,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Logo PetCadê',
    );
  }
}
