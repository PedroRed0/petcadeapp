import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';

class UsuarioService {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      FirebaseFirestore.instance.collection('usuarios');

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  /// Dados do usuário logado, em tempo real.
  Stream<Usuario?> usuarioAtual() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return _colecao.doc(id).snapshots().map((doc) {
      if (doc.exists) return Usuario.fromDocument(doc);
      // Conta criada antes desta versão: monta com o que o Auth sabe.
      final u = FirebaseAuth.instance.currentUser;
      return Usuario(
        uid: id,
        nome: u?.displayName ?? '',
        email: u?.email ?? '',
      );
    });
  }

  Future<void> atualizarPerfil({
    required String nome,
    required String telefone,
  }) async {
    final id = uid;
    if (id == null) return;
    await FirebaseAuth.instance.currentUser?.updateDisplayName(nome.trim());
    await _colecao.doc(id).set({
      'nome': nome.trim(),
      'telefone': telefone.trim(),
      'email': FirebaseAuth.instance.currentUser?.email ?? '',
    }, SetOptions(merge: true));
  }

  Future<void> alternarFavorito(String petId, bool salvar) async {
    final id = uid;
    if (id == null) return;
    await _colecao.doc(id).set({
      'favoritos': salvar
          ? FieldValue.arrayUnion([petId])
          : FieldValue.arrayRemove([petId]),
    }, SetOptions(merge: true));
  }
}
