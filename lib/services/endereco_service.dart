import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Endereço vindo do CEP.
class Endereco {
  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String uf;

  const Endereco({
    required this.cep,
    this.logradouro = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
  });

  /// "Vila Sônia, São Paulo - SP" (o que aparece no anúncio)
  String get resumo {
    final local = [cidade, uf].where((s) => s.isNotEmpty).join(' - ');
    return [bairro, local].where((s) => s.isNotEmpty).join(', ');
  }
}

/// Busca de endereço e coordenadas — serviços públicos e gratuitos:
/// - ViaCEP (viacep.com.br): CEP → rua, bairro, cidade;
/// - Nominatim (OpenStreetMap): texto do endereço → latitude/longitude.
class EnderecoService {
  final http.Client _cliente;

  EnderecoService({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  // O Nominatim pede que cada app se identifique.
  static const _cabecalhos = {
    'User-Agent': 'PetCade/1.0 (app de animais perdidos)',
    'Accept-Language': 'pt-BR',
  };

  static String somenteNumeros(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// "05622000" → "05622-000"
  static String formatarCep(String s) {
    final n = somenteNumeros(s);
    return n.length == 8 ? '${n.substring(0, 5)}-${n.substring(5)}' : s;
  }

  /// Busca o endereço de um CEP. Retorna null se o CEP não existir.
  Future<Endereco?> buscarCep(String cep) async {
    final n = somenteNumeros(cep);
    if (n.length != 8) {
      throw const FormatException('O CEP precisa ter 8 números.');
    }
    final r = await _cliente
        .get(Uri.parse('https://viacep.com.br/ws/$n/json/'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode == 400) return null;
    if (r.statusCode != 200) {
      throw Exception('ViaCEP respondeu ${r.statusCode}');
    }
    final d = jsonDecode(utf8.decode(r.bodyBytes, allowMalformed: true));
    if (d is! Map || d['erro'] == true || d['erro'] == 'true') return null;
    String c(String k) => (d[k] ?? '').toString().trim();
    return Endereco(
      cep: formatarCep(n),
      logradouro: c('logradouro'),
      bairro: c('bairro'),
      cidade: c('localidade'),
      uf: c('uf'),
    );
  }

  /// Converte um texto ("Vila Sônia, São Paulo - SP") em coordenadas.
  /// Retorna null se não encontrar.
  Future<LatLng?> buscarCoordenadas(String texto) async {
    final q = texto.replaceAll(' - ', ', ').trim();
    if (q.isEmpty) return null;
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'br',
    });
    final r = await _cliente
        .get(uri, headers: _cabecalhos)
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception('Busca de endereço respondeu ${r.statusCode}');
    }
    final lista = jsonDecode(utf8.decode(r.bodyBytes, allowMalformed: true));
    if (lista is! List || lista.isEmpty) return null;
    final lat = double.tryParse('${lista.first['lat']}');
    final lon = double.tryParse('${lista.first['lon']}');
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  /// Coordenadas de um endereço de CEP: tenta do mais preciso (rua) ao
  /// menos preciso (só a cidade).
  Future<LatLng?> coordenadasDoEndereco(Endereco e) async {
    final cidadeUf = [e.cidade, e.uf].where((s) => s.isNotEmpty).join(', ');
    final tentativas = <String>{
      if (e.logradouro.isNotEmpty) '${e.logradouro}, ${e.bairro}, $cidadeUf',
      if (e.bairro.isNotEmpty) '${e.bairro}, $cidadeUf',
      cidadeUf,
    };
    for (final t in tentativas) {
      final p = await buscarCoordenadas(t);
      if (p != null) return p;
    }
    return null;
  }
}
