import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pet.dart';

class PetService {
  final CollectionReference _colecaoPets = FirebaseFirestore.instance
      .collection('pets_perdidos');

  /// Limite de segurança: um documento do Firestore aceita no máximo 1 MB.
  /// Deixamos uma folga para os outros campos.
  static const int tamanhoMaximoFotoBytes = 700 * 1024;

  /// Converte os bytes da foto (já reduzida pelo image_picker) em texto
  /// base64, para ser salvo dentro do próprio documento do Firestore.
  /// Assim não precisamos do Firebase Storage, que é pago.
  String converterFoto(Uint8List bytes) {
    if (bytes.lengthInBytes > tamanhoMaximoFotoBytes) {
      throw Exception(
        'A foto ficou grande demais (${(bytes.lengthInBytes / 1024).round()} KB). '
        'Escolha outra imagem.',
      );
    }
    return base64Encode(bytes);
  }

  // Salva um novo pet no Firestore
  Future<void> cadastrarPet(Pet pet) async {
    await _colecaoPets.add(pet.toMap());
  }

  // Stream em tempo real com todos os pets (ordenados do mais recente pro mais antigo).
  // A ordenação é feita aqui no app para que documentos sem o campo
  // 'criadoEm' não sumam da lista (o orderBy do Firestore os ignoraria).
  Stream<List<Pet>> listarPets() {
    return _colecaoPets.snapshots().map((snapshot) {
      final pets = snapshot.docs.map((doc) => Pet.fromDocument(doc)).toList();
      pets.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return pets;
    });
  }
}
