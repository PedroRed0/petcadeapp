import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/pet.dart';

class PetService {
  final CollectionReference _colecaoPets = FirebaseFirestore.instance
      .collection('pets_perdidos');

  // Envia a foto para o Storage e retorna a URL pública
  Future<String> uploadFoto(File foto) async {
    final nomeArquivo = '${const Uuid().v4()}.jpg';
    final referencia = FirebaseStorage.instance.ref().child(
      'fotos_pets/$nomeArquivo',
    );
    await referencia.putFile(foto);
    return await referencia.getDownloadURL();
  }

  // Salva um novo pet no Firestore
  Future<void> cadastrarPet(Pet pet) async {
    await _colecaoPets.add(pet.toMap());
  }

  // Stream em tempo real com todos os pets (ordenados do mais recente pro mais antigo)
  Stream<List<Pet>> listarPets() {
    return _colecaoPets
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Pet.fromDocument(doc)).toList(),
        );
  }
}
