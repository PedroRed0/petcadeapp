import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petcade/core/theme/app_theme.dart';
import 'package:petcade/core/widgets/selo_nivel.dart';
import 'package:petcade/main.dart';
import 'package:petcade/models/conversa.dart';
import 'package:petcade/models/nivel.dart';
import 'package:petcade/models/perfil_publico.dart';
import 'package:petcade/models/pet.dart';
import 'package:petcade/screens/chat/chat_screen.dart';
import 'package:petcade/screens/chat/conversas_screen.dart';
import 'package:petcade/screens/detalhes_pet_screen.dart';
import 'package:petcade/services/chat_service.dart';
import 'package:petcade/services/firebase_refs.dart';
import 'package:petcade/services/prestigio_service.dart';

late FakeFirebaseFirestore db;

void _entrarComo(String uid) {
  Fb.usar(
    db: db,
    auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: uid, displayName: uid, isEmailVerified: true),
    ),
  );
}

Future<Pet> _pet() async {
  await db.collection('pets_perdidos').doc('nina').set({
    'nome': 'Nina',
    'especie': 'Gato',
    'donoId': 'pedro',
    'status': 'perdido',
    'criadoEm': Timestamp.now(),
  });
  return Pet.fromDocument(
    await db.collection('pets_perdidos').doc('nina').get(),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.collection('perfis').doc('ana').set({
      'nome': 'Ana S.',
      'foto': '',
      'fotoUrl': '',
    });
    await db.collection('perfis').doc('pedro').set({
      'nome': 'Pedro R.',
      'foto': '',
      'fotoUrl': '',
    });
  });

  group('Níveis', () {
    test('limites: 5 bronze, 10 prata, 20 ouro, 50 diamante', () {
      expect(Nivel.deQuantidade(0), Nivel.iniciante);
      expect(Nivel.deQuantidade(4), Nivel.iniciante);
      expect(Nivel.deQuantidade(5), Nivel.bronze);
      expect(Nivel.deQuantidade(9), Nivel.bronze);
      expect(Nivel.deQuantidade(10), Nivel.prata);
      expect(Nivel.deQuantidade(20), Nivel.ouro);
      expect(Nivel.deQuantidade(49), Nivel.ouro);
      expect(Nivel.deQuantidade(50), Nivel.diamante);
      expect(Nivel.deQuantidade(300), Nivel.diamante);
    });

    test('quanto falta e progresso', () {
      expect(Nivel.iniciante.faltamPara(3), 2);
      expect(Nivel.bronze.faltamPara(7), 3);
      expect(Nivel.ouro.faltamPara(20), 30);
      expect(Nivel.diamante.proximo, isNull);
      expect(Nivel.bronze.progresso(5), 0);
      expect(Nivel.bronze.progresso(10), 1);
      expect(Nivel.diamante.progresso(80), 1);
    });

    test('nome curto público', () {
      expect(PerfilPublico.nomeCurto('Pedro Henrique Rodrigues'), 'Pedro R.');
      expect(PerfilPublico.nomeCurto('Ana'), 'Ana');
      expect(PerfilPublico.nomeCurto('  '), '');
    });
  });

  group('Prestígio', () {
    test('quem avisou vira candidato, o tutor credita e conta +1', () async {
      final pet = await _pet();
      _entrarComo('ana');
      await PrestigioService().registrarInteresse(pet);

      _entrarComo('pedro');
      expect(await PrestigioService().candidatos(pet), ['ana']);
      await PrestigioService().registrarAjuda(pet, 'ana');

      expect(await PrestigioService().encontrados('ana').first, 1);
      final n = (await db.collection('notificacoes').get()).docs.single;
      expect(n['paraId'], 'ana');
      expect(n['tipo'], 'ajuda');
    });

    test('dono não vira candidato do próprio anúncio', () async {
      final pet = await _pet();
      _entrarComo('pedro');
      await PrestigioService().registrarInteresse(pet);
      expect(await PrestigioService().candidatos(pet), isEmpty);
    });

    test('5 ajudas = Bronze', () async {
      _entrarComo('ana');
      for (var i = 0; i < 5; i++) {
        await db.collection('ajudas').doc('p$i').set({'ajudanteId': 'ana'});
      }
      expect(await PrestigioService().nivel('ana').first, Nivel.bronze);
    });
  });

  group('Bate-papo', () {
    test('id da conversa é o mesmo dos dois lados', () {
      expect(Conversa.idEntre('pedro', 'ana'), 'ana_pedro');
      expect(Conversa.idEntre('ana', 'pedro'), 'ana_pedro');
    });

    test('abrir pelo anúncio cria a conversa e registra interesse', () async {
      final pet = await _pet();
      _entrarComo('ana');
      final id = await ChatService().abrirConversa('pedro', pet: pet);
      expect(id, 'ana_pedro');
      final c = (await db.collection('conversas').doc(id).get()).data()!;
      expect(c['participantes'], ['ana', 'pedro']);
      expect(c['petNome'], 'Nina');
      expect(
        (await db.collection('interessados').doc('nina_ana').get()).exists,
        isTrue,
      );
    });

    test('mensagem nova aparece como não lida para o outro', () async {
      _entrarComo('ana');
      final id = await ChatService().abrirConversa('pedro');
      await ChatService().enviarTexto(id, 'Oi! Acho que vi a Nina 🐱');
      expect(await ChatService().naoLidas().first, 0); // eu que mandei

      _entrarComo('pedro');
      expect(await ChatService().naoLidas().first, 1);
      final lista = await ChatService().minhasConversas().first;
      expect(lista.single.ultimaMensagem, 'Oi! Acho que vi a Nina 🐱');
      await ChatService().marcarComoLida(id);
      expect(await ChatService().naoLidas().first, 0);
    });

    test('mensagens de foto e áudio guardam prévia e dados', () async {
      _entrarComo('ana');
      final id = await ChatService().abrirConversa('pedro');
      await ChatService().enviarImagem(id, Uint8List.fromList([1, 2, 3]));
      await ChatService().enviarAudio(
        id,
        Uint8List.fromList([4, 5, 6]),
        mime: 'audio/mp4',
        duracao: const Duration(seconds: 7),
      );
      final msgs = await ChatService().mensagens(id).first;
      expect(msgs.map((m) => m.tipo), [
        TipoMensagem.imagem,
        TipoMensagem.audio,
      ]);
      expect(msgs.last.duracaoMs, 7000);
      final c = (await db.collection('conversas').doc(id).get()).data()!;
      expect(c['ultimaMensagem'], '🎤 Áudio');
    });

    test('mensagens grandes demais são recusadas', () async {
      _entrarComo('ana');
      final id = await ChatService().abrirConversa('pedro');
      expect(
        () => ChatService().enviarImagem(
          id,
          Uint8List(ChatService.tamanhoMaximoImagem + 1),
        ),
        throwsException,
      );
    });

    test('emoji sozinho fica grande; texto normal não', () {
      expect(soEmojis('😂'), isTrue);
      expect(soEmojis('🐶❤️'), isTrue);
      expect(soEmojis('oi 😂'), isFalse);
      expect(soEmojis('ok!'), isFalse);
      expect(soEmojis('123'), isFalse);
    });
  });

  group('Telas', () {
    Future<void> abrir(
      WidgetTester t,
      Widget tela,
      Size tam,
      double esc,
    ) async {
      t.view.physicalSize = tam;
      t.view.devicePixelRatio = 1;
      t.view.padding = const FakeViewPadding(bottom: 48);
      t.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.light,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(esc)),
            child: envolverApp(c, child),
          ),
          home: tela,
        ),
      );
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    Future<String> conversaComMensagens() async {
      _entrarComo('ana');
      final id = await ChatService().abrirConversa('pedro', pet: await _pet());
      final chat = ChatService();
      await chat.enviarTexto(
        id,
        'Oi Pedro! Acho que vi a Nina perto da padaria da esquina com a Avenida Francisco Morato.',
      );
      await chat.enviarTexto(id, '😂');
      _entrarComo('pedro');
      await chat.enviarTexto(id, 'Sério?! Muito obrigado!! 🙏');
      await chat.enviarAudio(
        id,
        Uint8List.fromList([1, 2, 3]),
        mime: 'audio/mp4',
        duracao: const Duration(seconds: 12),
      );
      _entrarComo('ana');
      return id;
    }

    for (final (tam, esc) in [
      (const Size(320, 568), 1.3),
      (const Size(360, 740), 1.0),
    ]) {
      testWidgets('Conversa (${tam.width.toInt()}px, fonte ${esc}x)', (
        t,
      ) async {
        final id = await conversaComMensagens();
        await abrir(t, ChatScreen(conversaId: id, outroId: 'pedro'), tam, esc);
        expect(find.text('Pedro R.'), findsOneWidget);
        expect(find.text('sobre Nina'), findsOneWidget);
        expect(find.text('😂'), findsOneWidget);
        expect(find.byTooltip('Ouvir'), findsOneWidget);

        // a barra de digitação fica acima da barra do Android
        final barra = t.getRect(find.byTooltip('Gravar áudio'));
        expect(barra.bottom, lessThanOrEqualTo(tam.height - 48));

        // digitar troca 🎤 por ➤ e envia
        await t.enterText(find.byType(TextField), 'Já estou indo!');
        await t.pump();
        expect(find.byTooltip('Gravar áudio'), findsNothing);
        await t.tap(find.byTooltip('Enviar'));
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Já estou indo!'), findsOneWidget);

        // painel de emojis
        await t.tap(find.byTooltip('Emojis'));
        await t.pump();
        await t.tap(find.text('😀'));
        await t.pump();
        expect(find.widgetWithText(TextField, '😀'), findsOneWidget);
      });

      testWidgets(
        'Lista de conversas (${tam.width.toInt()}px, fonte ${esc}x)',
        (t) async {
          await conversaComMensagens();
          _entrarComo('ana');
          await abrir(t, const ConversasScreen(), tam, esc);
          expect(find.text('Pedro R.'), findsOneWidget);
          expect(find.textContaining('🎤 Áudio'), findsOneWidget);
        },
      );

      testWidgets('Cartão de prestígio (${tam.width.toInt()}px)', (t) async {
        for (var i = 0; i < 7; i++) {
          await db.collection('ajudas').doc('p$i').set({'ajudanteId': 'ana'});
        }
        _entrarComo('ana');
        await abrir(
          t,
          const Scaffold(body: CartaoPrestigio(uid: 'ana')),
          tam,
          esc,
        );
        expect(find.text('Prestígio Bronze'), findsOneWidget);
        expect(find.text('7 animais encontrados'), findsOneWidget);
        expect(find.textContaining('Faltam 3 para'), findsOneWidget);
      });
    }
    for (final tam in [const Size(320, 568), const Size(360, 740)]) {
      testWidgets(
        'Encontrado → escolher quem ajudou (${tam.width.toInt()}px)',
        (t) async {
          final pet = await _pet();
          _entrarComo('ana');
          await PrestigioService().registrarInteresse(pet);
          _entrarComo('pedro');
          await abrir(t, DetalhesPetScreen(pet: pet), tam, 1.3);

          await t.tap(find.text('Marcar como encontrado'));
          for (var i = 0; i < 8; i++) {
            await t.pump(const Duration(milliseconds: 100));
          }
          expect(find.text('Ana S.'), findsOneWidget);
          expect(find.text('Encontrei sem ajuda do app'), findsOneWidget);
          await t.tap(find.text('Ana S.'));
          await t.pump();
          await t.tap(find.text('Confirmar'));
          for (var i = 0; i < 8; i++) {
            await t.pump(const Duration(milliseconds: 100));
          }
          final ajuda = await db.collection('ajudas').doc('nina').get();
          expect(ajuda['ajudanteId'], 'ana');
          final atual = Pet.fromDocument(
            await db.collection('pets_perdidos').doc('nina').get(),
          );
          expect(atual.perdido, isFalse);
          expect(await PrestigioService().encontrados('ana').first, 1);
        },
      );
    }
  });
}
