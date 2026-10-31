import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../theme/app_colors.dart';

/// Mostra a foto do pet. Funciona tanto com a foto salva em base64
/// (cadastros novos) quanto com URL (cadastros antigos).
class PetFoto extends StatefulWidget {
  final Pet pet;
  final double? width;
  final double? height;

  const PetFoto({super.key, required this.pet, this.width, this.height});

  @override
  State<PetFoto> createState() => _PetFotoState();
}

class _PetFotoState extends State<PetFoto> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decodificar();
  }

  @override
  void didUpdateWidget(covariant PetFoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet.fotoBase64 != widget.pet.fotoBase64) _decodificar();
  }

  // Decodifica uma vez só (e não a cada rebuild), para a lista ficar leve.
  void _decodificar() {
    _bytes = null;
    if (widget.pet.fotoBase64.isEmpty) return;
    try {
      _bytes = base64Decode(widget.pet.fotoBase64);
    } catch (_) {
      _bytes = null;
    }
  }

  Widget _semFoto() => Container(
    width: widget.width,
    height: widget.height,
    color: AppColors.laranjaClaro.withValues(alpha: 0.4),
    child: const Icon(Icons.pets_rounded, size: 40, color: AppColors.laranja),
  );

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _semFoto(),
      );
    }
    if (widget.pet.fotoUrl.isNotEmpty) {
      return Image.network(
        widget.pet.fotoUrl,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _semFoto(),
      );
    }
    return _semFoto();
  }
}
