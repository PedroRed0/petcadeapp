// Abre todas as telas em celulares de tamanhos diferentes, com fonte
// normal e aumentada, e falha se algo ficar "fora da tela" (overflow).
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petcade/core/theme/app_theme.dart';
import 'package:petcade/main.dart';
import 'package:petcade/screens/mapa_screen.dart';
import 'package:petcade/models/pet.dart';
import 'package:petcade/screens/animais_perdidos_screen.dart';
import 'package:petcade/screens/buscar_screen.dart';
import 'package:petcade/screens/auth/criar_conta_screen.dart';
import 'package:petcade/screens/auth/login_screen.dart';
import 'package:petcade/screens/cadastro_pet_screen.dart';
import 'package:petcade/screens/detalhes_pet_screen.dart';
import 'package:petcade/screens/main_shell.dart';
import 'package:petcade/screens/perfil/ajuda_screen.dart';
import 'package:petcade/screens/perfil/animais_salvos_screen.dart';
import 'package:petcade/screens/perfil/configuracoes_screen.dart';
import 'package:petcade/screens/perfil/editar_perfil_screen.dart';
import 'package:petcade/screens/perfil/meus_anuncios_screen.dart';
import 'package:petcade/screens/texto_screen.dart';
import 'package:petcade/models/usuario.dart';
import 'package:petcade/services/firebase_refs.dart';
import 'package:petcade/services/localizacao_service.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAIAAAAmkwkpAAAAEElEQVR4nGP43yUPRwzEcQC/UhqBZFbBrwAAAABJRU5ErkJggg==';

const _uid = 'eu';

final _pets = <Map<String, dynamic>>[
  {
    'nome': 'Bartolomeu Fernandes da Silva',
    'especie': 'Cachorro',
    'raca': 'Golden Retriever com Labrador',
    'cor': 'Caramelo com manchas brancas',
    'sexo': 'Macho',
    'porte': 'Grande',
    'peso': 32.5,
    'descricao': 'Usa coleira vermelha com plaquinha, tem uma cicatriz na orelha esquerda e é muito dócil com crianças.',
    'fotos': [_png, _png],
    'localizacao': 'Jardim Nossa Senhora do Carmo, Itaquera - São Paulo - SP',
    'latitude': -23.54,
    'longitude': -46.45,
    'recompensa': 1500.0,
    'status': 'perdido',
    'donoId': _uid,
    'donoNome': 'Maria Aparecida dos Santos Oliveira',
  },
  {
    'nome': 'Mia',
    'especie': 'Gato',
    'raca': 'Siamês',
    'sexo': 'Fêmea',
    'porte': 'Pequeno',
    'descricao': 'Olhos azuis.',
    'fotos': [_png],
    'localizacao': 'Mooca - SP',
    'latitude': -23.55,
    'longitude': -46.60,
    'status': 'perdido',
    'donoId': 'outra-pessoa',
    'donoNome': 'João',
  },
  {
    'nome': 'Luna',
    'especie': 'Gato',
    'status': 'encontrado',
    'donoId': _uid,
    'localizacao': 'Centro',
  },
];

Future<FakeFirebaseFirestore> _prepararFirebase() async {
  final db = FakeFirebaseFirestore();
  final agora = Timestamp.fromDate(DateTime(2026, 10, 20, 14, 30));
  for (var i = 0; i < _pets.length; i++) {
    await db.collection('pets_perdidos').doc('pet$i').set({
      ..._pets[i],
      'vistoEm': agora,
      'criadoEm': agora,
    });
  }
  await db.collection('usuarios').doc(_uid).set({
    'nome': 'Kevin Kalel Alexandre de Albuquerque Monteiro',
    'email': 'kevin.kalel.alexandre.monteiro@emailmuitolongo.com.br',
    'telefone': '(11) 98765-4321',
    'favoritos': ['pet1'],
    'foto': _png,
  });
  await db.collection('notificacoes').add({
    'paraId': _uid,
    'tipo': 'avistamento',
    'titulo': 'Novo avistamento de um pet muito querido',
    'mensagem': 'Fulano de Tal informou que viu Bartolomeu na Avenida Jacu-Pêssego perto do posto de gasolina.',
    'petId': 'pet0',
    'telefone': '(11) 91234-5678',
    'lida': false,
    'criadoEm': agora,
  });
  await db.collection('notificacoes').add({
    'paraId': _uid,
    'tipo': 'encontrado',
    'titulo': 'Pet encontrado!',
    'mensagem': 'Mia foi localizada.',
    'petId': 'pet1',
    'lida': true,
    'criadoEm': agora,
  });
  Fb.usar(
    db: db,
    auth: MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: _uid,
        email: 'kevin@email.com',
        displayName: 'Kevin Kalel',
      ),
    ),
  );
  return db;
}

Pet _petDe(int i) => Pet.fromMap('pet$i', {
  ..._pets[i],
  'vistoEm': Timestamp.fromDate(DateTime(2026, 10, 20)),
  'criadoEm': Timestamp.fromDate(DateTime(2026, 10, 20)),
});

const _tamanhos = {
  'pequeno 320x568': Size(320, 568),
  'médio 360x740': Size(360, 740),
};
const _escalas = [1.0, 1.3];

Future<void> _abrir(
  WidgetTester t,
  Widget tela,
  Size tamanho,
  double escala,
) async {
  t.view.physicalSize = tamanho;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: envolverApp(context, child),
      ),
      home: tela,
    ),
  );
  await _esperar(t);
}

Future<void> _esperar(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Rola cada lista até o fim, para que tudo seja desenhado.
Future<void> _rolarTudo(WidgetTester t) async {
  for (final estado in t.stateList<ScrollableState>(find.byType(Scrollable))) {
    final pos = estado.position;
    if (pos.hasContentDimensions && pos.maxScrollExtent > 0) {
      pos.jumpTo(pos.maxScrollExtent);
      await t.pump(const Duration(milliseconds: 100));
    }
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final MapEntry(key: nomeTam, value: tamanho) in _tamanhos.entries) {
    for (final escala in _escalas) {
      final sufixo = '($nomeTam, fonte ${escala}x)';

      testWidgets('Login $sufixo', (t) async {
        await _prepararFirebase();
        await _abrir(t, const LoginScreen(), tamanho, escala);
        await _rolarTudo(t);
      });

      testWidgets('Criar conta $sufixo', (t) async {
        await _prepararFirebase();
        await _abrir(t, const CriarContaScreen(), tamanho, escala);
        await _rolarTudo(t);
      });

      testWidgets('Abas principais $sufixo', (t) async {
        await _prepararFirebase();
        await _abrir(t, const MainShell(), tamanho, escala);
        await _rolarTudo(t);
        for (final aba in ['Buscar', 'Notificações', 'Perfil', 'Início']) {
          await t.tap(find.text(aba).last);
          await _esperar(t);
          await _rolarTudo(t);
        }
      });

      testWidgets('Detalhes (dono e visitante) $sufixo', (t) async {
        await _prepararFirebase();
        await _abrir(t, DetalhesPetScreen(pet: _petDe(0)), tamanho, escala);
        await _rolarTudo(t);
        await _abrir(t, DetalhesPetScreen(pet: _petDe(1)), tamanho, escala);
        await _rolarTudo(t);
        await t.tap(find.text('Eu vi este pet'), warnIfMissed: false);
        await _esperar(t);
      });

      final telas = <String, Widget Function()>{
        'Lista de animais': () => const AnimaisPerdidosScreen(),
        'Meus anúncios': () => const MeusAnunciosScreen(),
        'Animais salvos': () => const AnimaisSalvosScreen(),
        'Configurações': () => const ConfiguracoesScreen(),
        'Ajuda': () => const AjudaScreen(),
        'Termos': () => const TextoScreen(texto: TextoApp.termos),
        'Editar perfil': () => const EditarPerfilScreen(
          usuario: Usuario(
            uid: _uid,
            nome: 'Kevin Kalel Alexandre',
            email: 'kevin.kalel.alexandre.monteiro@emailmuitolongo.com.br',
            foto: _png,
          ),
        ),
      };
      for (final MapEntry(key: nome, value: criar) in telas.entries) {
        testWidgets('$nome $sufixo', (t) async {
          await _prepararFirebase();
          await _abrir(t, criar(), tamanho, escala);
          await _rolarTudo(t);
        });
      }

      testWidgets('Cadastro (4 etapas) $sufixo', (t) async {
        await _prepararFirebase();
        await _abrir(
          t,
          CadastroPetScreen(
            fotosIniciais: [base64Decode(_png), base64Decode(_png)],
          ),
          tamanho,
          escala,
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

        await digitar('Ex.: Thor', 'Bartolomeu');
        await digitar(
          'Coleira, manchas, cicatriz, comportamento...',
          'Coleira vermelha e cicatriz',
        );
        Future<void> proximo() async {
          await t.tap(find.text('Próximo'));
          await _esperar(t);
          await _rolarTudo(t);
        }

        await proximo(); // → Fotos
        await proximo(); // → Localização
        expect(find.text('Usar minha localização atual'), findsOneWidget);
      });
    }
  }

  // Erro enviado pelo Pedro: a janela "Ordenar por" ficava atrás da
  // barra de navegação do Android (◁ ○ ▢).
  for (final MapEntry(key: nomeTam, value: tamanho) in _tamanhos.entries) {
    testWidgets('Janelas não ficam atrás da barra do Android ($nomeTam)', (
      t,
    ) async {
      await _prepararFirebase();
      const barra = 48.0;
      t.view.padding = const FakeViewPadding(bottom: barra);
      t.view.viewPadding = const FakeViewPadding(bottom: barra);
      await _abrir(t, const BuscarScreen(), tamanho, 1.3);
      for (final (linha, ultimaOpcao) in [
        ('Ordenar por', 'Mais próximos'),
        ('Sexo', 'Fêmea'),
        ('Porte', 'Grande'),
      ]) {
        await t.scrollUntilVisible(
          find.text(linha),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await t.ensureVisible(find.text(linha));
        await _esperar(t);
        await t.tap(find.text(linha));
        await _esperar(t);
        final fim = t.getRect(find.text(ultimaOpcao).last).bottom;
        expect(
          fim,
          lessThanOrEqualTo(tamanho.height - barra),
          reason: '"$ultimaOpcao" ficou atrás da barra do sistema',
        );
        Navigator.of(t.element(find.text(ultimaOpcao).last)).pop();
        await _esperar(t);
      }
    });
  }

  // Erros enviados pelo Pedro na tela do mapa: filtros atrás da barra do
  // Android e card do pet esticado na tela inteira.
  for (final MapEntry(key: nomeTam, value: tamanho) in _tamanhos.entries) {
    testWidgets('Mapa: filtros e card do pet ($nomeTam)', (t) async {
      await _prepararFirebase();
      const barra = 48.0;
      t.view.padding = const FakeViewPadding(bottom: barra);
      t.view.viewPadding = const FakeViewPadding(bottom: barra);
      // "minha posição" perto da Mia, para o pin aparecer no mapa
      LocalizacaoService.instancia.posicao.value = const LatLng(-23.55, -46.60);
      addTearDown(() => LocalizacaoService.instancia.posicao.value = null);
      await _abrir(t, const MapaScreen(), tamanho, 1.0);
      final limite = tamanho.height - barra;
      expect(t.getRect(find.text('Gatos')).bottom, lessThanOrEqualTo(limite));
      expect(
        t.getRect(find.byIcon(Icons.my_location_rounded)).bottom,
        lessThanOrEqualTo(limite),
      );

      // toca no primeiro pin do mapa
      final pin = find.descendant(
        of: find.byType(MarkerLayer),
        matching: find.byType(GestureDetector),
      );
      t.widget<GestureDetector>(pin.first).onTap!();
      await _esperar(t);
      final botao = find.text('Ver detalhes');
      expect(botao, findsOneWidget);
      expect(t.getRect(botao).bottom, lessThanOrEqualTo(limite));
      // o card deve ter só o tamanho do conteúdo (não a tela toda)
      final topoCard = t.getRect(find.byType(BottomSheet)).top;
      expect(topoCard, greaterThan(tamanho.height * 0.35));
    });
  }
}
