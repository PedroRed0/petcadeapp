import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../theme/app_colors.dart';

/// Mostra uma foto do pet (base64 salvo no Firestore, ou URL antiga).
class PetFoto extends StatefulWidget {
  final Pet pet;
  final int indice;
  final double? width;
  final double? height;

  const PetFoto({
    super.key,
    required this.pet,
    this.indice = 0,
    this.width,
    this.height,
  });

  @override
  State<PetFoto> createState() => _PetFotoState();
}

class _PetFotoState extends State<PetFoto> {
  // Cache simples para não decodificar a mesma foto várias vezes.
  static final Map<int, Uint8List> _cache = {};

  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decodificar();
  }

  @override
  void didUpdateWidget(covariant PetFoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet != widget.pet || oldWidget.indice != widget.indice) {
      _decodificar();
    }
  }

  void _decodificar() {
    _bytes = null;
    final fotos = widget.pet.fotos;
    if (widget.indice >= fotos.length) return;
    final texto = fotos[widget.indice];
    final chave = texto.hashCode ^ texto.length;
    try {
      _bytes = _cache[chave] ??= base64Decode(texto);
      if (_cache.length > 80) _cache.remove(_cache.keys.first);
    } catch (_) {
      _bytes = null;
    }
  }

  Widget _semFoto(BuildContext context) => Container(
    width: widget.width,
    height: widget.height,
    color: AppColors.fundoDestaque(context),
    alignment: Alignment.center,
    child: Icon(
      Icons.pets_rounded,
      size: 28,
      color: AppColors.destaque(context).withValues(alpha: 0.35),
    ),
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
        errorBuilder: (_, _, _) => _semFoto(context),
      );
    }
    if (widget.indice == 0 && widget.pet.fotoUrl.isNotEmpty) {
      return Image.network(
        widget.pet.fotoUrl,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _semFoto(context),
      );
    }
    return _semFoto(context);
  }
}
