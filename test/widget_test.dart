import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petcade/models/pet.dart';
import 'package:petcade/screens/animais_perdidos_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('PetCard mostra as informações do pet', (tester) async {
    final pet = Pet(
      id: '1',
      nome: 'Rex',
      especie: 'Cachorro',
      racaCor: 'Vira-lata caramelo',
      descricao: 'Coleira azul, porte médio',
      localizacao: 'Praça da Sé',
      latitude: -23.5,
      longitude: -46.6,
      recompensa: 200,
      criadoEm: DateTime(2026, 10, 31),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: PetCard(pet: pet))),
      ),
    );

    expect(find.text('Rex'), findsOneWidget);
    expect(find.text('Cachorro'), findsOneWidget);
    expect(find.text('Vira-lata caramelo'), findsOneWidget);
    expect(find.text('Praça da Sé'), findsOneWidget);
    expect(find.text('Recompensa R\$ 200'), findsOneWidget);
    expect(find.text('Cadastrado em 31/10/2026'), findsOneWidget);
  });
}
