import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario.dart';
import 'firebase_refs.dart';
import 'perfil_service.dart';

class UsuarioService {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      Fb.db.collection('usuarios');

  String? get uid => Fb.auth.currentUser?.uid;

  /// Dados do usuário logado, em tempo real.
  Stream<Usuario?> usuarioAtual() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return _colecao.doc(id).snapshots().map((doc) {
      if (doc.exists) return Usuario.fromDocument(doc);
      // Conta criada antes desta versão: monta com o que o Auth sabe.
      final u = Fb.auth.currentUser;
      return Usuario(
        uid: id,
        nome: u?.displayName ?? '',
        email: u?.email ?? '',
        fotoUrl: u?.photoURL ?? '',
      );
    });
  }

  Future<void> atualizarPerfil({
    required String nome,
    required String telefone,
  }) async {
    final id = uid;
    if (id == null) return;
    await Fb.auth.currentUser?.updateDisplayName(nome.trim());
    await _colecao.doc(id).set({
      'nome': nome.trim(),
      'telefone': telefone.trim(),
      'email': Fb.auth.currentUser?.email ?? '',
    }, SetOptions(merge: true));
    await PerfilService().sincronizar();
  }

  /// Troca a foto de perfil (já reduzida). Passe null para remover.
  Future<void> atualizarFoto(Uint8List? bytes) async {
    final id = uid;
    if (id == null) return;
    if (bytes != null && bytes.lengthInBytes > 150 * 1024) {
      throw Exception('Foto muito grande. Escolha outra imagem.');
    }
    await _colecao.doc(id).set({
      'foto': bytes == null ? '' : base64Encode(bytes),
      // Ao remover, também esquece a foto do Google.
      if (bytes == null) 'fotoUrl': '',
    }, SetOptions(merge: true));
    await PerfilService().sincronizar();
  }

  /// Salva / tira dos salvos. Guarda no perfil (para "Animais salvos") e
  /// no anúncio (para o tutor poder avisar quando o pet for encontrado).
  Future<void> alternarFavorito(String petId, bool salvar) async {
    final id = uid;
    if (id == null) return;
    final lote = Fb.db.batch();
    lote.set(_colecao.doc(id), {
      'favoritos': salvar
          ? FieldValue.arrayUnion([petId])
          : FieldValue.arrayRemove([petId]),
    }, SetOptions(merge: true));
    lote.update(Fb.db.collection('pets_perdidos').doc(petId), {
      'seguidores': salvar
          ? FieldValue.arrayUnion([id])
          : FieldValue.arrayRemove([id]),
    });
    await lote.commit();
  }
}
