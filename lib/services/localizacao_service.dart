import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/pet.dart';

/// Guarda a posição do usuário para calcular "1,2 km de você".
class LocalizacaoService {
  LocalizacaoService._();
  static final instancia = LocalizacaoService._();

  /// Centro padrão (São Paulo) quando não temos a posição.
  static const LatLng padrao = LatLng(-23.5505, -46.6333);

  final ValueNotifier<LatLng?> posicao = ValueNotifier(null);

  bool _buscando = false;

  /// Pede permissão (se precisar) e atualiza a posição.
  /// Retorna null se o usuário negar ou o GPS estiver desligado.
  Future<LatLng?> atualizar() async {
    if (_buscando) return posicao.value;
    _buscando = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return posicao.value;
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return posicao.value;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      posicao.value = LatLng(p.latitude, p.longitude);
    } catch (_) {
      // Sem localização: o app continua funcionando, só sem distância.
    } finally {
      _buscando = false;
    }
    return posicao.value;
  }

  /// Distância em metros até o pet (null se não der para calcular).
  double? distanciaAte(Pet pet) {
    final p = posicao.value;
    if (p == null || !pet.temLocal) return null;
    return const Distance().as(
      LengthUnit.Meter,
      p,
      LatLng(pet.latitude, pet.longitude),
    );
  }
}
