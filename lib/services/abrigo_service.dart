import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Uma casa de adoção / abrigo de animais.
class Abrigo {
  final String nome;
  final LatLng ponto;
  final double distanciaMetros;
  final String endereco;
  final String telefone;
  final String site;

  const Abrigo({
    required this.nome,
    required this.ponto,
    required this.distanciaMetros,
    this.endereco = '',
    this.telefone = '',
    this.site = '',
  });

  /// Link de rota no Google Maps (gratuito, abre o app de mapas).
  Uri get rota => Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${ponto.latitude},${ponto.longitude}',
  });
}

/// Busca abrigos de animais no OpenStreetMap (serviço Overpass, gratuito).
/// No OpenStreetMap eles são marcados como `amenity=animal_shelter`.
class AbrigoService {
  final http.Client _cliente;

  AbrigoService({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  static final _servidor = Uri.https('overpass-api.de', '/api/interpreter');

  /// Os [quantidade] abrigos mais próximos. Procura em 25 km e, se não
  /// achar o suficiente, amplia para 80 km.
  Future<List<Abrigo>> proximos(LatLng perto, {int quantidade = 3}) async {
    var lista = await _buscar(perto, 25000);
    if (lista.length < quantidade) lista = await _buscar(perto, 80000);
    return lista.take(quantidade).toList();
  }

  Future<List<Abrigo>> _buscar(LatLng p, int raioMetros) async {
    final consulta =
        '[out:json][timeout:25];'
        '('
        'node["amenity"="animal_shelter"](around:$raioMetros,${p.latitude},${p.longitude});'
        'way["amenity"="animal_shelter"](around:$raioMetros,${p.latitude},${p.longitude});'
        ');'
        'out center tags 40;';
    final r = await _cliente
        .post(
          _servidor,
          headers: {'User-Agent': 'PetCade/1.0 (app de animais perdidos)'},
          body: {'data': consulta},
        )
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('A busca de abrigos respondeu ${r.statusCode}');
    }
    final d = jsonDecode(utf8.decode(r.bodyBytes, allowMalformed: true));
    final elementos = (d is Map && d['elements'] is List)
        ? d['elements'] as List
        : const [];
    final abrigos = <Abrigo>[];
    for (final e in elementos) {
      if (e is! Map) continue;
      final centro = e['center'] is Map ? e['center'] as Map : e;
      final lat = double.tryParse('${centro['lat']}');
      final lon = double.tryParse('${centro['lon']}');
      if (lat == null || lon == null) continue;
      final tags = e['tags'] is Map ? e['tags'] as Map : const {};
      String t(String k) => (tags[k] ?? '').toString().trim();
      final ponto = LatLng(lat, lon);
      final rua = [
        t('addr:street'),
        t('addr:housenumber'),
      ].where((x) => x.isNotEmpty).join(', ');
      final endereco = [
        rua,
        t('addr:suburb'),
        t('addr:city'),
      ].where((x) => x.isNotEmpty).join(' - ');
      abrigos.add(
        Abrigo(
          nome: t('name').isNotEmpty ? t('name') : 'Abrigo de animais',
          ponto: ponto,
          distanciaMetros: const Distance().as(LengthUnit.Meter, p, ponto),
          endereco: endereco,
          telefone: t('phone').isNotEmpty ? t('phone') : t('contact:phone'),
          site: t('website').isNotEmpty ? t('website') : t('contact:website'),
        ),
      );
    }
    abrigos.sort((a, b) => a.distanciaMetros.compareTo(b.distanciaMetros));
    return abrigos;
  }
}
