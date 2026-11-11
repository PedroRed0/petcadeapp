import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/perfil_publico.dart';
import 'firebase_refs.dart';

/// Perfis públicos (nome curto e foto), usados no bate-papo.
class PerfilService {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      Fb.db.collection('perfis');

  /// Atualiza o perfil público do usuário logado a partir do perfil privado.
  Future<void> sincronizar() async {
    final user = Fb.auth.currentUser;
    if (user == null) return;
    final privado = await Fb.db.collection('usuarios').doc(user.uid).get();
    final d = privado.data() ?? {};
    final nome = (d['nome']?.toString() ?? '').isNotEmpty
        ? d['nome'].toString()
        : (user.displayName ?? '');
    await _colecao.doc(user.uid).set({
      'nome': PerfilPublico.nomeCurto(nome),
      'foto': d['foto']?.toString() ?? '',
      'fotoUrl': d.containsKey('fotoUrl')
          ? d['fotoUrl'].toString()
          : (user.photoURL ?? ''),
    });
  }

  Stream<PerfilPublico?> perfil(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _colecao
        .doc(uid)
        .snapshots()
        .map((d) => d.exists ? PerfilPublico.fromDocument(d) : null);
  }

  Future<PerfilPublico?> buscar(String uid) async {
    final d = await _colecao.doc(uid).get();
    return d.exists ? PerfilPublico.fromDocument(d) : null;
  }
}
