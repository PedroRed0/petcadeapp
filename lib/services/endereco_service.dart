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

  /// Lugares que combinam com o texto, do mais provável ao menos.
  /// Com [perto], dá preferência a lugares próximos (ex.: o bairro
  /// "José Bonifácio" em São Paulo, e não a cidade de mesmo nome).
  Future<List<Lugar>> buscarLugares(
    String texto, {
    LatLng? perto,
    int limite = 5,
  }) async {
    final q = texto.replaceAll(' - ', ', ').trim();
    if (q.isEmpty) return [];
    final params = {
      'q': q,
      'format': 'jsonv2',
      'limit': '$limite',
      'countrycodes': 'br',
      'addressdetails': '0',
    };
    if (perto != null) {
      // Caixa de ~150 km em volta: só PRIORIZA, não exclui o resto.
      const d = 0.7;
      params['viewbox'] =
          '${perto.longitude - d},${perto.latitude + d},'
          '${perto.longitude + d},${perto.latitude - d}';
      params['bounded'] = '0';
    }
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    final r = await _cliente
        .get(uri, headers: _cabecalhos)
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception('Busca de endereço respondeu ${r.statusCode}');
    }
    final lista = jsonDecode(utf8.decode(r.bodyBytes, allowMalformed: true));
    if (lista is! List) return [];
    final lugares = <Lugar>[];
    for (final item in lista) {
      if (item is! Map) continue;
      final lat = double.tryParse('${item['lat']}');
      final lon = double.tryParse('${item['lon']}');
      if (lat == null || lon == null) continue;
      final nome = (item['display_name'] ?? texto).toString();
      // Ignora repetidos (mesmo nome a menos de 300 m).
      final ponto = LatLng(lat, lon);
      final repetido = lugares.any(
        (l) =>
            l.nomeCurto == Lugar.encurtar(nome) &&
            const Distance().as(LengthUnit.Meter, l.ponto, ponto) < 300,
      );
      if (!repetido) lugares.add(Lugar(nome: nome, ponto: ponto));
    }
    return lugares;
  }

  /// Converte um texto ("Vila Sônia, São Paulo - SP") em coordenadas
  /// (o resultado mais provável). Retorna null se não encontrar.
  Future<LatLng?> buscarCoordenadas(String texto, {LatLng? perto}) async {
    final lugares = await buscarLugares(texto, perto: perto, limite: 1);
    return lugares.isEmpty ? null : lugares.first.ponto;
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

/// Um resultado da busca de endereço.
class Lugar {
  /// Nome completo, como o OpenStreetMap devolve.
  final String nome;
  final LatLng ponto;

  const Lugar({required this.nome, required this.ponto});

  /// Sem o país e o CEP no fim: "José Bonifácio, São Paulo, SP".
  String get nomeCurto => encurtar(nome);

  static String encurtar(String nome) {
    final partes = nome
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .where((p) => p != 'Brasil' && !RegExp(r'^\d{5}-?\d{3}$').hasMatch(p))
        .where((p) => !p.startsWith('Região Geográfica'))
        .toList();
    return partes.join(', ');
  }
}
