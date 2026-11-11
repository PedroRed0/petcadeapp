import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/nivel.dart';
import '../models/notificacao.dart';
import '../models/pet.dart';
import 'firebase_refs.dart';

/// Prestígio: quantos animais cada pessoa ajudou a encontrar.
///
/// - Quem avisa "Eu vi este pet" ou conversa com o tutor pelo anúncio vira
///   "interessado" naquele anúncio.
/// - Ao marcar o pet como encontrado, o tutor escolhe quem ajudou (entre os
///   interessados). Isso cria uma "ajuda", que conta para o nível da pessoa.
class PrestigioService {
  CollectionReference<Map<String, dynamic>> get _ajudas =>
      Fb.db.collection('ajudas');
  CollectionReference<Map<String, dynamic>> get _interessados =>
      Fb.db.collection('interessados');

  /// Registra que o usuário logado ajudou / se interessou por este anúncio.
  Future<void> registrarInteresse(Pet pet) async {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null || pet.id == null || pet.donoId.isEmpty) return;
    if (uid == pet.donoId) return;
    final ref = _interessados.doc('${pet.id}_$uid');
    try {
      if ((await ref.get()).exists) return;
    } catch (_) {}
    await ref.set({
      'petId': pet.id,
      'uid': uid,
      'donoId': pet.donoId,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Quem pode ter ajudado a encontrar o pet (para o tutor escolher).
  Future<List<String>> candidatos(Pet pet) async {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null || pet.id == null) return [];
    final r = await _interessados
        .where('donoId', isEqualTo: uid)
        .where('petId', isEqualTo: pet.id)
        .get();
    return r.docs.map((d) => d['uid'].toString()).toSet().toList();
  }

  /// O tutor credita quem ajudou e a pessoa recebe uma notificação.
  /// Se a ajuda fizer a pessoa subir de nível, a notificação vira
  /// "Patente desbloqueada".
  Future<void> registrarAjuda(Pet pet, String ajudanteId) async {
    final uid = Fb.auth.currentUser?.uid;
    if (uid == null || pet.id == null) return;
    var antes = 0;
    try {
      antes = (await _ajudas.where('ajudanteId', isEqualTo: ajudanteId).get())
          .docs
          .length;
    } catch (_) {}
    final novo = Nivel.subiu(antes, antes + 1);
    final depois = antes + 1;

    final lote = Fb.db.batch();
    lote.set(_ajudas.doc(pet.id), {
      'petId': pet.id,
      'petNome': pet.nome,
      'ajudanteId': ajudanteId,
      'donoId': uid,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    lote.set(Fb.db.collection('notificacoes').doc(), {
      'paraId': ajudanteId,
      'autorId': uid,
      'tipo': Notificacao.tipoAjuda,
      'titulo': novo != null
          ? 'Patente desbloqueada'
          : 'Você ajudou a encontrar ${pet.nome}! 🎉',
      'mensagem': novo != null
          ? 'Você virou ${novo.titulo}! $depois pets encontrados.'
          : 'O tutor confirmou a sua ajuda. Agora são $depois '
                '${depois == 1 ? 'pet encontrado' : 'pets encontrados'}.',
      if (novo != null) 'patente': novo.name,
      'petId': pet.id,
      'lida': false,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    await lote.commit();
  }

  /// Quantos animais a pessoa ajudou a encontrar (em tempo real).
  Stream<int> encontrados(String uid) {
    if (uid.isEmpty) return Stream.value(0);
    return _ajudas
        .where('ajudanteId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<Nivel> nivel(String uid) => encontrados(uid).map(Nivel.deQuantidade);
}
