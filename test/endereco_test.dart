import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:petcade/core/theme/app_theme.dart';
import 'package:petcade/models/pet.dart';
import 'package:petcade/screens/cadastro_pet_screen.dart';
import 'package:petcade/screens/perfil/alterar_local_screen.dart';
import 'package:petcade/services/endereco_service.dart';
import 'package:petcade/services/firebase_refs.dart';
import 'package:petcade/services/localizacao_service.dart';

// Coordenadas aproximadas da Vila Sônia (zona Oeste de SP)
const _vilaSonia = LatLng(-23.5970, -46.7340);
// José Bonifácio: o município no interior e o bairro da Zona Leste de SP
const _joseBonifacioCidade = LatLng(-21.0550, -49.6880);
const _joseBonifacioBairro = LatLng(-23.5480, -46.4370);
// "Minha posição" (Itaquera, zona Leste) — o pet NÃO pode ficar aqui
const _minhaPosicao = LatLng(-23.5400, -46.4560);

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAIAAAAmkwkpAAAAEElEQVR4nGP43yUPRwzEcQC/UhqBZFbBrwAAAABJRU5ErkJggg==';

/// Simula o ViaCEP e o Nominatim (OpenStreetMap), com as respostas no
/// mesmo formato dos serviços de verdade.
final List<Uri> _pedidos = [];
final List<Map<String, String>> _cabecalhos = [];

http.Client _clienteFalso() => MockClient((req) async {
  _pedidos.add(req.url);
  _cabecalhos.add(req.headers);
  if (req.url.host == 'viacep.com.br') {
    if (req.url.path.contains('05622000')) {
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'cep': '05622-000',
            'logradouro': '',
            'bairro': 'Vila Sônia',
            'localidade': 'São Paulo',
            'uf': 'SP',
          }),
        ),
        200,
      );
    }
    return http.Response('{"erro": "true"}', 200);
  }
  if (req.url.host == 'nominatim.openstreetmap.org') {
    final q = (req.url.queryParameters['q'] ?? '').toLowerCase();
    if (q.contains('josé bonifácio') || q.contains('jose bonifacio')) {
      return http.Response.bytes(
        utf8.encode(
          jsonEncode([
            {
              'lat': '${_joseBonifacioCidade.latitude}',
              'lon': '${_joseBonifacioCidade.longitude}',
              'display_name': 'José Bonifácio, Região Imediata de São José do Rio Preto, São Paulo, Região Sudeste, Brasil',
            },
            {
              'lat': '${_joseBonifacioBairro.latitude}',
              'lon': '${_joseBonifacioBairro.longitude}',
              'display_name': 'José Bonifácio, São Paulo, Região Metropolitana de São Paulo, São Paulo, Região Sudeste, 08250-000, Brasil',
            },
          ]),
        ),
        200,
      );
    }
    if (q.contains('vila sônia') || q.contains('vila sonia')) {
      return http.Response.bytes(
        utf8.encode(
          jsonEncode([
            {
              'lat': '${_vilaSonia.latitude}',
              'lon': '${_vilaSonia.longitude}',
              'display_name': 'Vila Sônia, São Paulo, SP, Brasil',
            },
          ]),
        ),
        200,
      );
    }
    return http.Response('[]', 200);
  }
  return http.Response('não encontrado', 404);
});

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    _pedidos.clear();
    _cabecalhos.clear();
  });

  group('EnderecoService', () {
    final s = EnderecoService(cliente: _clienteFalso());

    test('busca o CEP (aceita com ou sem traço)', () async {
      final e = await s.buscarCep('05622-000');
      expect(e!.bairro, 'Vila Sônia');
      expect(e.cidade, 'São Paulo');
      expect(e.resumo, 'Vila Sônia, São Paulo - SP');
      expect(
        _pedidos.last.toString(),
        'https://viacep.com.br/ws/05622000/json/',
      );
    });

    test('CEP inexistente retorna null; CEP curto dá erro claro', () async {
      expect(await s.buscarCep('99999999'), isNull);
      expect(() => s.buscarCep('123'), throwsFormatException);
    });

    test(
      'converte texto em coordenadas, só no Brasil e se identificando',
      () async {
        final p = await s.buscarCoordenadas('Vila Sônia - SP');
        expect(p, _vilaSonia);
        expect(_pedidos.last.queryParameters['countrycodes'], 'br');
        expect(_cabecalhos.last['User-Agent'], contains('PetCade'));
      },
    );

    test('lugar desconhecido retorna null', () async {
      expect(await s.buscarCoordenadas('Lugar Que Não Existe'), isNull);
    });
  });

  group('Telas', () {
    late FakeFirebaseFirestore db;

    setUp(() async {
      db = FakeFirebaseFirestore();
      Fb.usar(
        db: db,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'eu', displayName: 'Pedro'),
        ),
      );
      LocalizacaoService.instancia.posicao.value = _minhaPosicao;
    });
    tearDown(() => LocalizacaoService.instancia.posicao.value = null);

    Future<void> abrir(WidgetTester t, Widget tela) async {
      t.view.physicalSize = const Size(400, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: tela));
      await t.pump();
    }

    Future<void> esperar(WidgetTester t) async {
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets(
      'Cadastro: digitar "Vila Sônia - SP" sem tocar no mapa coloca o pet '
      'na Vila Sônia (e não na minha posição)',
      (t) async {
        await abrir(
          t,
          CadastroPetScreen(
            fotosIniciais: [base64Decode(_png)],
            enderecoService: EnderecoService(cliente: _clienteFalso()),
          ),
        );
        Future<void> digitar(String dica, String texto) async {
          final campo = find.widgetWithText(TextFormField, dica);
          await t.scrollUntilVisible(
            campo,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await t.enterText(campo, texto);
        }

        await digitar('Ex.: Thor', 'Nina');
        await digitar(
          'Coleira, manchas, cicatriz, comportamento...',
          'Gata laranja',
        );
        await t.tap(find.text('Próximo'));
        await esperar(t); // → Fotos
        await t.tap(find.text('Próximo'));
        await esperar(t); // → Localização

        await t.enterText(
          find.widgetWithText(TextFormField, 'Ex.: Vila Sônia, São Paulo - SP'),
          'Vila Sônia - SP',
        );
        await t.tap(find.text('Próximo'));
        await esperar(t); // localiza sozinho e pede confirmação
        expect(find.text('Tem certeza que é este o local?'), findsOneWidget);
        await t.tap(find.text('Sim, é aqui'));
        await esperar(t); // → Confirmar
        expect(find.text('Publicar anúncio'), findsOneWidget);

        await t.tap(find.text('Publicar anúncio'));
        await esperar(t);
        final docs = (await db.collection('pets_perdidos').get()).docs;
        expect(docs, hasLength(1));
        final pet = Pet.fromDocument(docs.single);
        expect(pet.localizacao, 'Vila Sônia - SP');
        expect(pet.latitude, _vilaSonia.latitude);
        expect(pet.longitude, _vilaSonia.longitude);
        expect(pet.latitude, isNot(_minhaPosicao.latitude));
      },
    );

    testWidgets('Alterar localização pelo CEP corrige um anúncio antigo', (
      t,
    ) async {
      await db.collection('pets_perdidos').doc('nina').set({
        'nome': 'Nina',
        'especie': 'Gato',
        'localizacao': 'Vila Sônia - SP',
        'latitude': _minhaPosicao.latitude,
        'longitude': _minhaPosicao.longitude,
        'donoId': 'eu',
        'criadoEm': Timestamp.now(),
      });
      final nina = Pet.fromDocument(
        await db.collection('pets_perdidos').doc('nina').get(),
      );
      await abrir(
        t,
        AlterarLocalScreen(
          pet: nina,
          servico: EnderecoService(cliente: _clienteFalso()),
        ),
      );

      await t.enterText(
        find.widgetWithText(TextField, '00000-000'),
        '05622000',
      );
      await t.tap(find.byTooltip('Buscar CEP'));
      await esperar(t);
      expect(find.text('Tem certeza que é este o local?'), findsOneWidget);
      await t.tap(find.text('Sim, é aqui'));
      await esperar(t);
      expect(find.text('Vila Sônia, São Paulo - SP'), findsOneWidget);
      expect(find.text('05622-000'), findsOneWidget);

      await t.tap(find.text('Salvar localização'));
      await esperar(t);
      final d = (await db.collection('pets_perdidos').doc('nina').get())
          .data()!;
      expect(d['localizacao'], 'Vila Sônia, São Paulo - SP');
      expect(d['latitude'], _vilaSonia.latitude);
      expect(d['longitude'], _vilaSonia.longitude);
    });
  });

  group('Escolher e confirmar o local', () {
    test('busca dá preferência a lugares perto de mim', () async {
      final s = EnderecoService(cliente: _clienteFalso());
      final lugares = await s.buscarLugares(
        'José Bonifácio',
        perto: _minhaPosicao,
      );
      expect(lugares, hasLength(2));
      expect(_pedidos.last.queryParameters['viewbox'], isNotNull);
      expect(_pedidos.last.queryParameters['bounded'], '0');
      expect(
        lugares.last.nomeCurto,
        'José Bonifácio, São Paulo, Região Metropolitana de São Paulo, '
        'São Paulo, Região Sudeste',
      );
    });

    testWidgets(
      'Caso "Kevin": José Bonifácio mostra as opções e salva o bairro de SP',
      (t) async {
        final db = FakeFirebaseFirestore();
        Fb.usar(
          db: db,
          auth: MockFirebaseAuth(
            signedIn: true,
            mockUser: MockUser(uid: 'eu', displayName: 'Pedro'),
          ),
        );
        LocalizacaoService.instancia.posicao.value = _minhaPosicao;
        addTearDown(() => LocalizacaoService.instancia.posicao.value = null);
        t.view.physicalSize = const Size(400, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: CadastroPetScreen(
              fotosIniciais: [base64Decode(_png)],
              enderecoService: EnderecoService(cliente: _clienteFalso()),
            ),
          ),
        );
        Future<void> esperar() async {
          for (var i = 0; i < 6; i++) {
            await t.pump(const Duration(milliseconds: 100));
          }
        }

        Future<void> digitar(String dica, String texto) async {
          final campo = find.widgetWithText(TextFormField, dica);
          await t.scrollUntilVisible(
            campo,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await t.enterText(campo, texto);
        }

        await digitar('Ex.: Thor', 'Kevin');
        await digitar('Coleira, manchas, cicatriz, comportamento...', 'Pardo');
        await t.tap(find.text('Próximo'));
        await esperar();
        await t.tap(find.text('Próximo'));
        await esperar();
        await t.enterText(
          find.widgetWithText(TextFormField, 'Ex.: Vila Sônia, São Paulo - SP'),
          'José Bonifácio',
        );
        await t.tap(find.text('Próximo'));
        await esperar();

        // Duas opções com o mesmo nome
        expect(find.text('Qual destes lugares?'), findsOneWidget);
        // Escolhe a cidade do interior por engano e desiste
        await t.tap(find.textContaining('São José do Rio Preto'));
        await esperar();
        expect(find.text('Tem certeza que é este o local?'), findsOneWidget);
        await t.tap(find.text('Não, escolher outro'));
        await esperar();
        // Volta à lista e escolhe o bairro de São Paulo
        expect(find.text('Qual destes lugares?'), findsOneWidget);
        await t.tap(find.textContaining('Região Metropolitana'));
        await esperar();
        await t.tap(find.text('Sim, é aqui'));
        await esperar();

        expect(find.text('Publicar anúncio'), findsOneWidget);
        expect(find.text('Local onde foi visto'), findsOneWidget);
        await t.tap(find.text('Publicar anúncio'));
        await esperar();
        final pet = Pet.fromDocument(
          (await db.collection('pets_perdidos').get()).docs.single,
        );
        expect(pet.latitude, _joseBonifacioBairro.latitude);
        expect(pet.longitude, _joseBonifacioBairro.longitude);
      },
    );
  });
}
