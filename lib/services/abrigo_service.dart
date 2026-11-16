import 'dart:async';
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

/// Nenhum serviço de busca respondeu (ocupados ou sem internet).
class BuscaAbrigosIndisponivel implements Exception {
  final String detalhe;
  const BuscaAbrigosIndisponivel(this.detalhe);

  @override
  String toString() => 'BuscaAbrigosIndisponivel($detalhe)';
}

/// Busca abrigos de animais no OpenStreetMap, de graça.
///
/// 1. Overpass (marcação `amenity=animal_shelter`), tentando vários
///    servidores: o principal vive sobrecarregado e recusa pedidos.
/// 2. Se nenhum responder, Nominatim (o mesmo da busca de endereço).
class AbrigoService {
  final http.Client _cliente;

  AbrigoService({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  /// Servidores públicos do Overpass, com os mesmos dados.
  static final servidoresOverpass = [
    Uri.https('overpass-api.de', '/api/interpreter'),
    Uri.https('overpass.private.coffee', '/api/interpreter'),
    Uri.https('overpass.kumi.systems', '/api/interpreter'),
  ];

  static const _cabecalhos = {
    'User-Agent': 'PetCade/1.0 (app de animais perdidos)',
    'Accept-Language': 'pt-BR',
  };

  /// Os [quantidade] abrigos mais próximos.
  Future<List<Abrigo>> proximos(LatLng perto, {int quantidade = 3}) async {
    final falhas = <String>[];

    // 1) Overpass: 40 km; se vier pouco, 100 km.
    List<Abrigo>? lista;
    try {
      lista = await _overpass(perto, 40000, falhas);
    } on BuscaAbrigosIndisponivel {
      lista = null; // tenta o plano B
    }
    if (lista != null && lista.length < quantidade) {
      try {
        final maior = await _overpass(perto, 100000, falhas);
        if (maior.length > lista.length) lista = maior;
      } on BuscaAbrigosIndisponivel {
        // fica com o que já achou em 40 km
      }
    }
    if (lista != null && lista.isNotEmpty) {
      return lista.take(quantidade).toList();
    }

    // 2) Plano B: Nominatim.
    try {
      final nomi = await _nominatim(perto);
      if (nomi.isNotEmpty || lista != null) {
        return nomi.take(quantidade).toList();
      }
    } catch (e) {
      falhas.add('nominatim: $e');
    }
    if (lista != null) return const []; // Overpass respondeu: não há abrigos
    throw BuscaAbrigosIndisponivel(falhas.join('; '));
  }

  /// Tenta cada servidor do Overpass até um responder.
  Future<List<Abrigo>> _overpass(
    LatLng p,
    int raioMetros,
    List<String> falhas,
  ) async {
    final consulta =
        '[out:json][timeout:12];'
        '('
        'node["amenity"="animal_shelter"](around:$raioMetros,${p.latitude},${p.longitude});'
        'way["amenity"="animal_shelter"](around:$raioMetros,${p.latitude},${p.longitude});'
        ');'
        'out center tags 40;';
    for (final servidor in servidoresOverpass) {
      try {
        final r = await _cliente
            .post(servidor, headers: _cabecalhos, body: {'data': consulta})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) {
          falhas.add('${servidor.host}: ${r.statusCode}');
          continue; // 429 (muitos pedidos), 504 (ocupado)…: próximo
        }
        final d = jsonDecode(utf8.decode(r.bodyBytes, allowMalformed: true));
        if (d is! Map || d['elements'] is! List) {
          falhas.add('${servidor.host}: resposta inesperada');
          continue;
        }
        return _lerOverpass(p, d['elements'] as List);
      } on TimeoutException {
        falhas.add('${servidor.host}: demorou demais');
      } catch (e) {
        falhas.add('${servidor.host}: $e');
      }
    }
    throw BuscaAbrigosIndisponivel(falhas.join('; '));
  }

  List<Abrigo> _lerOverpass(LatLng p, List elementos) {
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

  /// Plano B: procura "animal shelter" / "abrigo de animais" perto da pessoa.
  Future<List<Abrigo>> _nominatim(LatLng p) async {
    const d = 0.6; // ~65 km para cada lado
    final caixa =
        '${p.longitude - d},${p.latitude + d},'
        '${p.longitude + d},${p.latitude - d}';
    final vistos = <String>{};
    final abrigos = <Abrigo>[];
    for (final termo in ['animal shelter', 'abrigo de animais']) {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': termo,
        'format': 'jsonv2',
        'limit': '10',
        'countrycodes': 'br',
        'viewbox': caixa,
        'bounded': '1',
        'addressdetails': '1',
      });
      final r = await _cliente
          .get(uri, headers: _cabecalhos)
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) {
        throw Exception('Nominatim respondeu ${r.statusCode}');
      }
      final lista = jsonDecode(utf8.decode(r.bodyBytes, allowMalformed: true));
      if (lista is! List) continue;
      for (final item in lista) {
        if (item is! Map) continue;
        // Só o que o mapa marca como abrigo de animais.
        if ('${item['type']}' != 'animal_shelter') continue;
        final lat = double.tryParse('${item['lat']}');
        final lon = double.tryParse('${item['lon']}');
        if (lat == null || lon == null) continue;
        final chave = '${item['osm_type']}${item['osm_id']}';
        if (!vistos.add(chave)) continue;
        final ponto = LatLng(lat, lon);
        final end = item['address'] is Map ? item['address'] as Map : const {};
        String a(String k) => (end[k] ?? '').toString().trim();
        final nome = (item['name'] ?? '').toString().trim();
        final endereco = [
          [a('road'), a('house_number')].where((x) => x.isNotEmpty).join(', '),
          a('suburb'),
          a('city').isNotEmpty ? a('city') : a('town'),
        ].where((x) => x.isNotEmpty).join(' - ');
        abrigos.add(
          Abrigo(
            nome: nome.isNotEmpty ? nome : 'Abrigo de animais',
            ponto: ponto,
            distanciaMetros: const Distance().as(LengthUnit.Meter, p, ponto),
            endereco: endereco,
          ),
        );
      }
    }
    abrigos.sort((a, b) => a.distanciaMetros.compareTo(b.distanciaMetros));
    return abrigos;
  }
}
