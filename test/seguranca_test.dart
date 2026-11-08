import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petcade/core/theme/app_theme.dart';
import 'package:petcade/core/widgets/confirmacao_email.dart';
import 'package:petcade/models/filtro_pets.dart';
import 'package:petcade/models/pet.dart';
import 'package:petcade/screens/detalhes_pet_screen.dart';
import 'package:petcade/services/firebase_refs.dart';
import 'package:petcade/services/pet_service.dart';
import 'package:petcade/services/usuario_service.dart';

late FakeFirebaseFirestore db;

Future<Pet> _criarPet({String donoId = 'pedro', int denuncias = 0}) async {
  await db.collection('pets_perdidos').doc('nina').set({
    'nome': 'Nina',
    'especie': 'Gato',
    'donoId': donoId,
    'denuncias': denuncias,
    'seguidores': <String>[],
    'status': 'perdido',
    'criadoEm': Timestamp.now(),
  });
  return Pet.fromDocument(
    await db.collection('pets_perdidos').doc('nina').get(),
  );
}

void _entrarComo(String uid, {bool confirmado = true}) {
  Fb.usar(
    db: db,
    auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: uid,
        email: '$uid@email.com',
        displayName: uid,
        isEmailVerified: confirmado,
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => db = FakeFirebaseFirestore());

  group('Denúncias', () {
    test('registra a denúncia e soma +1 no anúncio', () async {
      final pet = await _criarPet();
      _entrarComo('ana');
      expect(await PetService().jaDenunciei(pet), isFalse);
      await PetService().denunciar(pet, motivo: 'Anúncio falso ou golpe');
      final d = (await db.collection('denuncias').doc('nina_ana').get())
          .data()!;
      expect(d['autorId'], 'ana');
      expect(d['motivo'], 'Anúncio falso ou golpe');
      final atualizado = Pet.fromDocument(
        await db.collection('pets_perdidos').doc('nina').get(),
      );
      expect(atualizado.denuncias, 1);
      expect(await PetService().jaDenunciei(pet), isTrue);
    });

    test('com 3 denúncias o anúncio some das buscas e do mapa', () async {
      final ok = await _criarPet(denuncias: 2);
      expect(const FiltroPets().aplicar([ok]), hasLength(1));
      final revisao = await _criarPet(denuncias: Pet.limiteDenuncias);
      expect(revisao.emRevisao, isTrue);
      expect(const FiltroPets().aplicar([revisao]), isEmpty);
    });
  });

  group('Salvar e avisar quando encontrado', () {
    test('salvar coloca a pessoa na lista de seguidores do anúncio', () async {
      await _criarPet();
      _entrarComo('ana');
      await UsuarioService().alternarFavorito('nina', true);
      var pet = Pet.fromDocument(
        await db.collection('pets_perdidos').doc('nina').get(),
      );
      expect(pet.seguidores, ['ana']);
      final perfil = await db.collection('usuarios').doc('ana').get();
      expect(perfil.data()!['favoritos'], ['nina']);

      await UsuarioService().alternarFavorito('nina', false);
      pet = Pet.fromDocument(
        await db.collection('pets_perdidos').doc('nina').get(),
      );
      expect(pet.seguidores, isEmpty);
    });

    test('ao marcar como encontrado, avisa só quem seguia', () async {
      await _criarPet();
      _entrarComo('ana');
      await UsuarioService().alternarFavorito('nina', true);
      _entrarComo('pedro');
      final pet = Pet.fromDocument(
        await db.collection('pets_perdidos').doc('nina').get(),
      );
      await PetService().marcarEncontrado(pet);
      final n = (await db.collection('notificacoes').get()).docs;
      expect(n, hasLength(1));
      expect(n.single['paraId'], 'ana');
      expect(n.single['autorId'], 'pedro');
      expect(n.single['tipo'], 'encontrado');
    });
  });

  group('Confirmação de e-mail', () {
    Future<void> abrirBotao(
      WidgetTester t,
      ValueChanged<bool> resultado,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    resultado(await exigirEmailConfirmado(context)),
                child: const Text('publicar'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('e-mail confirmado: segue direto', (t) async {
      _entrarComo('ana');
      bool? r;
      await abrirBotao(t, (v) => r = v);
      await t.tap(find.text('publicar'));
      await t.pumpAndSettle();
      expect(r, isTrue);
      expect(find.text('Confirme seu e-mail'), findsNothing);
    });

    testWidgets('e-mail não confirmado: pede a confirmação', (t) async {
      _entrarComo('ze', confirmado: false);
      bool? r;
      await abrirBotao(t, (v) => r = v);
      await t.tap(find.text('publicar'));
      await t.pumpAndSettle();
      expect(find.text('Confirme seu e-mail'), findsOneWidget);
      await t.tap(find.text('Agora não'));
      await t.pumpAndSettle();
      expect(r, isFalse);
    });
  });

  group('Tela de detalhes', () {
    Future<void> abrir(WidgetTester t, Pet pet) async {
      t.view.physicalSize = const Size(400, 900);
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
    }

    testWidgets('visitante vê a bandeira de denúncia e o aviso de golpes', (
      t,
    ) async {
      final pet = await _criarPet();
      _entrarComo('ana');
      await abrir(t, pet);
      expect(find.byTooltip('Denunciar anúncio'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Cuidado com golpes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Cuidado com golpes'), findsOneWidget);

      await t.tap(find.byTooltip('Denunciar anúncio'));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.text('Anúncio falso ou golpe'));
      await t.pump();
      await t.tap(find.text('Enviar denúncia'));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(
        (await db.collection('denuncias').doc('nina_ana').get()).exists,
        isTrue,
      );
    });

    testWidgets('dono não vê a bandeira; anúncio em revisão avisa o dono', (
      t,
    ) async {
      final pet = await _criarPet(denuncias: Pet.limiteDenuncias);
      _entrarComo('pedro');
      await abrir(t, pet);
      expect(find.byTooltip('Denunciar anúncio'), findsNothing);
      await t.scrollUntilVisible(
        find.text('Anúncio em revisão'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Anúncio em revisão'), findsOneWidget);
    });
  });
}
