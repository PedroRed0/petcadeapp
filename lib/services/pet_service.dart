import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notificacao.dart';
import '../models/pet.dart';

class PetService {
  CollectionReference<Map<String, dynamic>> get _colecaoPets =>
      FirebaseFirestore.instance.collection('pets_perdidos');

  /// Um documento do Firestore aceita no máximo 1 MB no total.
  static const int maxFotos = 3;
  static const int tamanhoMaximoFotoBytes = 250 * 1024;

  /// Converte a foto (já reduzida pelo image_picker) em texto base64,
  /// para ser salva dentro do próprio documento. Assim não precisamos do
  /// Firebase Storage, que é pago.
  String converterFoto(Uint8List bytes) {
    if (bytes.lengthInBytes > tamanhoMaximoFotoBytes) {
      throw Exception(
        'Uma das fotos ficou grande demais '
        '(${(bytes.lengthInBytes / 1024).round()} KB). Escolha outra imagem.',
      );
    }
    return base64Encode(bytes);
  }

  Future<void> cadastrarPet(Pet pet) async {
    await _colecaoPets.add(pet.toMap());
  }

  /// Todos os pets, em tempo real (mais recentes primeiro).
  /// A ordenação é feita no app para não precisar de índice no Firestore.
  Stream<List<Pet>> listarPets() {
    return _colecaoPets.snapshots().map((snapshot) {
      final pets = snapshot.docs.map(Pet.fromDocument).toList();
      pets.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return pets;
    });
  }

  /// Um pet só, em tempo real (null se foi excluído).
  Stream<Pet?> pet(String id) {
    return _colecaoPets
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Pet.fromDocument(doc) : null);
  }

  /// Anúncios criados pelo usuário.
  Stream<List<Pet>> meusPets(String uid) {
    return _colecaoPets.where('donoId', isEqualTo: uid).snapshots().map((s) {
      final pets = s.docs.map(Pet.fromDocument).toList();
      pets.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return pets;
    });
  }

  /// Marca como encontrado e avisa quem tinha salvo esse pet.
  Future<void> marcarEncontrado(Pet pet) async {
    await _colecaoPets.doc(pet.id).update({'status': Pet.statusEncontrado});

    final quemSalvou = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('favoritos', arrayContains: pet.id)
        .get();
    final lote = FirebaseFirestore.instance.batch();
    final notificacoes = FirebaseFirestore.instance.collection('notificacoes');
    for (final u in quemSalvou.docs) {
      if (u.id == pet.donoId) continue;
      lote.set(notificacoes.doc(), {
        'paraId': u.id,
        'tipo': Notificacao.tipoEncontrado,
        'titulo': 'Pet encontrado!',
        'mensagem': '${pet.nome} foi localizado e já está com o tutor.',
        'petId': pet.id,
        'lida': false,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
    await lote.commit();
  }

  Future<void> reativar(Pet pet) =>
      _colecaoPets.doc(pet.id).update({'status': Pet.statusPerdido});

  Future<void> excluir(Pet pet) => _colecaoPets.doc(pet.id).delete();
}
