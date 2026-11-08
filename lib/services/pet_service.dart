import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notificacao.dart';
import '../models/pet.dart';
import 'firebase_refs.dart';

class PetService {
  CollectionReference<Map<String, dynamic>> get _colecaoPets =>
      Fb.db.collection('pets_perdidos');

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

    // Lista atualizada de quem acompanha o anúncio.
    final atual = await _colecaoPets.doc(pet.id).get();
    final seguidores = Pet.fromDocument(atual).seguidores;
    if (seguidores.isEmpty) return;

    final lote = Fb.db.batch();
    final notificacoes = Fb.db.collection('notificacoes');
    for (final uid in seguidores) {
      if (uid == pet.donoId) continue;
      lote.set(notificacoes.doc(), {
        'paraId': uid,
        'autorId': pet.donoId,
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

  // ---------- Denúncias ----------

  static const motivosDenuncia = [
    'Anúncio falso ou golpe',
    'Pediu dinheiro ou pagamento antecipado',
    'Conteúdo ofensivo ou impróprio',
    'Não é um animal perdido',
    'Outro motivo',
  ];

  DocumentReference<Map<String, dynamic>> _denuncia(String petId, String uid) =>
      Fb.db.collection('denuncias').doc('${petId}_$uid');

  /// Se o usuário logado já denunciou este anúncio.
  Future<bool> jaDenunciei(Pet pet) async {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null || pet.id == null) return false;
    final d = await _denuncia(pet.id!, uid).get();
    return d.exists;
  }

  /// Registra a denúncia e soma +1 no anúncio (as duas coisas juntas).
  /// Com [Pet.limiteDenuncias] denúncias o anúncio sai das buscas.
  Future<void> denunciar(
    Pet pet, {
    required String motivo,
    String detalhes = '',
  }) async {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null || pet.id == null) return;
    final lote = Fb.db.batch();
    lote.set(_denuncia(pet.id!, uid), {
      'petId': pet.id,
      'autorId': uid,
      'motivo': motivo,
      'detalhes': detalhes.trim(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
    lote.update(_colecaoPets.doc(pet.id), {
      'denuncias': FieldValue.increment(1),
    });
    await lote.commit();
  }

  /// Corrige onde o pet foi visto.
  Future<void> atualizarLocal(
    Pet pet, {
    required String localizacao,
    required double latitude,
    required double longitude,
  }) => _colecaoPets.doc(pet.id).update({
    'localizacao': localizacao,
    'latitude': latitude,
    'longitude': longitude,
  });

  Future<void> reativar(Pet pet) =>
      _colecaoPets.doc(pet.id).update({'status': Pet.statusPerdido});

  Future<void> excluir(Pet pet) => _colecaoPets.doc(pet.id).delete();
}
