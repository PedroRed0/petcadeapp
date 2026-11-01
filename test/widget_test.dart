import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:petcade/core/utils/formatos.dart';
import 'package:petcade/core/widgets/pet_card.dart';
import 'package:petcade/models/filtro_pets.dart';
import 'package:petcade/models/pet.dart';

Pet _pet(
  String nome, {
  String especie = 'Cachorro',
  String raca = '',
  String local = '',
  String status = Pet.statusPerdido,
  double lat = 0,
  double lng = 0,
  DateTime? criado,
}) => Pet(
  id: nome,
  nome: nome,
  especie: especie,
  raca: raca,
  localizacao: local,
  status: status,
  latitude: lat,
  longitude: lng,
  vistoEm: DateTime(2026, 9, 22),
  criadoEm: criado ?? DateTime(2026, 10, 1),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('PetCard mostra as informações do pet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetCard(
            pet: _pet('Zóio', raca: 'Pug', local: 'José Bonifácio - SP'),
          ),
        ),
      ),
    );
    expect(find.text('Zóio'), findsOneWidget);
    expect(find.text('Cachorro - Pug'), findsOneWidget);
    expect(find.text('Perdido'), findsOneWidget);
    expect(find.text('Visto em 22/09/2026'), findsOneWidget);
    expect(find.text('José Bonifácio - SP'), findsOneWidget);
  });

  group('FiltroPets', () {
    final pets = [
      _pet(
        'Thor',
        raca: 'Pug',
        local: 'Itaquera - SP',
        criado: DateTime(2026, 10, 3),
      ),
      _pet(
        'Mia',
        especie: 'Gato',
        raca: 'Siamês',
        local: 'Mooca',
        criado: DateTime(2026, 10, 2),
      ),
      _pet('Luna', status: Pet.statusEncontrado),
    ];

    test('esconde encontrados e ordena por mais recentes', () {
      final r = const FiltroPets().aplicar(pets);
      expect(r.map((p) => p.nome), ['Thor', 'Mia']);
    });

    test('filtra por espécie, texto sem acento e região', () {
      expect(
        const FiltroPets(especie: 'Gato').aplicar(pets).map((p) => p.nome),
        ['Mia'],
      );
      expect(
        const FiltroPets(texto: 'siames').aplicar(pets).map((p) => p.nome),
        ['Mia'],
      );
      expect(
        const FiltroPets(regiao: 'itaquera').aplicar(pets).map((p) => p.nome),
        ['Thor'],
      );
    });

    test('ordena pelos mais próximos', () {
      final perto = _pet('Perto', lat: -23.55, lng: -46.63);
      final longe = _pet(
        'Longe',
        lat: -22.90,
        lng: -43.17,
        criado: DateTime(2026, 10, 9),
      );
      final r = const FiltroPets(ordenacao: Ordenacao.proximos)
          .aplicar([longe, perto], posicao: const LatLng(-23.56, -46.64));
      expect(r.first.nome, 'Perto');
    });
  });

  test('Pet lê cadastros antigos (racaCor e fotoBase64)', () {
    final p = Pet.fromMap('x', {
      'nome': 'Rex',
      'racaCor': 'Vira-lata',
      'fotoBase64': 'abc',
    });
    expect(p.raca, 'Vira-lata');
    expect(p.fotos, ['abc']);
    expect(p.perdido, isTrue);
  });

  test('formatos', () {
    expect(formatarDistancia(1234), '1,2 km');
    expect(formatarDistancia(430), '430 m');
    expect(formatarDistancia(25300), '25 km');
    expect(primeiroNome('Kevin Kalel'), 'Kevin');
    expect(
      formatarTempoRelativo(
        DateTime(2026, 1, 1, 10),
        agora: DateTime(2026, 1, 1, 11),
      ),
      'Há 1 h',
    );
  });
}
