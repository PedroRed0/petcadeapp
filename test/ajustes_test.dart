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
import 'package:petcade/screens/detalhes_pet_screen.dart';
import 'package:petcade/screens/perfil/casas_adocao_screen.dart';
import 'package:petcade/services/abrigo_service.dart';
import 'package:petcade/services/auth_service.dart';
import 'package:petcade/services/endereco_service.dart';
import 'package:petcade/services/firebase_refs.dart';
import 'package:petcade/services/localizacao_service.dart';
import 'package:petcade/services/usuario_service.dart';

const _eu = LatLng(-23.5400, -46.4560); // Itaquera

/// Resposta no formato do Overpass (OpenStreetMap).
http.Client _overpassFalso() => MockClient((req) async {
  expect(req.url.host, 'overpass-api.de');
  expect(req.body, contains('animal_shelter'));
  return http.Response.bytes(
    utf8.encode(
      jsonEncode({
        'elements': [
          {
            'type': 'node',
            'lat': -23.60,
            'lon': -46.50,
            'tags': {'amenity': 'animal_shelter', 'name': 'Abrigo Longe'},
          },
          {
            'type': 'way',
            'center': {'lat': -23.545, 'lon': -46.46},
            'tags': {
              'amenity': 'animal_shelter',
              'name': 'Casa dos Bichos',
              'addr:street': 'Rua das Flores',
              'addr:housenumber': '10',
              'addr:suburb': 'Itaquera',
              'phone': '+55 11 99999-0000',
            },
          },
          {
            'type': 'node',
            'lat': -23.56,
            'lon': -46.47,
            'tags': {'amenity': 'animal_shelter'},
          },
          {
            'type': 'node',
            'lat': -23.70,
            'lon': -46.70,
            'tags': {'amenity': 'animal_shelter', 'name': 'Muito Longe'},
          },
        ],
      }),
    ),
    200,
  );
});

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Login com Google: nome no perfil', () {
    test('perfil antigo sem nome ganha o nome da conta Google', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('usuarios').doc('ana').set({
        'nome': '',
        'email': 'ana@gmail.com',
        'favoritos': [],
      });
      Fb.usar(
        db: db,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(
            uid: 'ana',
            email: 'ana@gmail.com',
            displayName: 'Ana Souza',
          ),
        ),
      );
      await AuthService().garantirPerfil();
      final d = (await db.collection('usuarios').doc('ana').get()).data()!;
      expect(d['nome'], 'Ana Souza');
      final perfil = (await db.collection('perfis').doc('ana').get()).data()!;
      expect(perfil['nome'], 'Ana S.');
      expect((await UsuarioService().usuarioAtual().first)!.nome, 'Ana Souza');
    });

    test('sem nome na conta, usa o nome que o Google devolveu', () async {
      final db = FakeFirebaseFirestore();
      Fb.usar(
        db: db,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'bia', email: 'bia.lima@gmail.com'),
        ),
      );
      await AuthService().garantirPerfil(nomeGoogle: 'Bia Lima');
      final d = (await db.collection('usuarios').doc('bia').get()).data()!;
      expect(d['nome'], 'Bia Lima');
    });

    test('último recurso: a parte do e-mail antes do @', () async {
      final db = FakeFirebaseFirestore();
      Fb.usar(
        db: db,
        auth: MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'ze', email: 'ze.carlos@gmail.com'),
        ),
      );
      await AuthService().garantirPerfil();
      final d = (await db.collection('usuarios').doc('ze').get()).data()!;
      expect(d['nome'], 'ze.carlos');
    });
  });

  group('Casas de adoção', () {
    test('as 3 mais próximas, em ordem de distância', () async {
      final r = await AbrigoService(cliente: _overpassFalso()).proximos(_eu);
      expect(r.map((a) => a.nome), [
        'Casa dos Bichos',
        'Abrigo de animais', // sem nome no mapa
        'Abrigo Longe',
      ]);
      expect(r.first.endereco, 'Rua das Flores, 10 - Itaquera');
      expect(r.first.telefone, '+55 11 99999-0000');
      expect(r.first.rota.toString(), contains('destination=-23.545'));
    });

    for (final tam in [const Size(320, 568), const Size(400, 800)]) {
      testWidgets('tela (${tam.width.toInt()}px)', (t) async {
        LocalizacaoService.instancia.posicao.value = _eu;
        addTearDown(() => LocalizacaoService.instancia.posicao.value = null);
        t.view.physicalSize = tam;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: CasasAdocaoScreen(
              servico: AbrigoService(cliente: _overpassFalso()),
            ),
          ),
        );
        await t.tap(find.text('Buscar casas de adoção próximas'));
        for (var i = 0; i < 8; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Casa dos Bichos'), findsOneWidget);
        expect(find.text('Como chegar'), findsWidgets);
        expect(find.text('Abrigo de animais'), findsOneWidget);
        expect(find.text('Ligar'), findsOneWidget);
      });
    }
  });

  testWidgets('Página do pet tem o botão "Ver no mapa"', (t) async {
    final db = FakeFirebaseFirestore();
    Fb.usar(
      db: db,
      auth: MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'ana', isEmailVerified: true),
      ),
    );
    await db.collection('pets_perdidos').doc('pingo').set({
      'nome': 'Pingo',
      'especie': 'Outro',
      'donoId': 'pedro',
      'localizacao': 'Travessa Tucupi',
      'latitude': -23.55,
      'longitude': -46.60,
      'criadoEm': Timestamp.now(),
    });
    final pet = Pet.fromDocument(
      await db.collection('pets_perdidos').doc('pingo').get(),
    );
    t.view.physicalSize = const Size(400, 860);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DetalhesPetScreen(pet: pet),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byTooltip('Ver no mapa'), findsOneWidget);
    await t.tap(find.byTooltip('Ver no mapa'));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // O mapa abre centralizado no Pingo, já com o card dele
    expect(find.text('Mapa de casos'), findsOneWidget);
    expect(find.text('Ver detalhes'), findsOneWidget);
    expect(find.text('Pingo'), findsWidgets);
  });

  test('Lugar.encurtar tira país, CEP e região', () {
    expect(
      Lugar.encurtar(
        'Vila Sônia, São Paulo, Região Geográfica Imediata de São Paulo, '
        'São Paulo, 05622-000, Brasil',
      ),
      'Vila Sônia, São Paulo, São Paulo',
    );
  });
}
