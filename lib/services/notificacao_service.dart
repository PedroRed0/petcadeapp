import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notificacao.dart';
import '../models/pet.dart';
import 'firebase_refs.dart';

/// Notificações dentro do app, guardadas no Firestore (grátis).
class NotificacaoService {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      Fb.db.collection('notificacoes');

  String? get _uid => Fb.auth.currentUser?.uid;

  Stream<List<Notificacao>> minhas() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _colecao.where('paraId', isEqualTo: uid).snapshots().map((s) {
      final lista = s.docs.map(Notificacao.fromDocument).toList();
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return lista;
    });
  }

  Stream<int> quantidadeNaoLidas() =>
      minhas().map((l) => l.where((n) => !n.lida).length);

  Future<void> marcarTodasComoLidas(List<Notificacao> lista) async {
    final naoLidas = lista.where((n) => !n.lida).toList();
    if (naoLidas.isEmpty) return;
    final lote = Fb.db.batch();
    for (final n in naoLidas) {
      lote.update(_colecao.doc(n.id), {'lida': true});
    }
    await lote.commit();
  }

  Future<void> excluir(Notificacao n) => _colecao.doc(n.id).delete();

  /// Alguém viu o pet: avisa o tutor.
  Future<void> informarAvistamento({
    required Pet pet,
    required String onde,
    required String mensagem,
    required String telefone,
  }) async {
    if (pet.donoId.isEmpty) {
      throw Exception(
        'Este anúncio é antigo e não tem um tutor cadastrado para receber o aviso.',
      );
    }
    final nome = Fb.auth.currentUser?.displayName ?? 'Alguém';
    final partes = <String>[
      '$nome informou que viu ${pet.nome}${onde.isNotEmpty ? ' em $onde' : ''}.',
      if (mensagem.isNotEmpty) '"$mensagem"',
    ];
    await _colecao.add({
      'paraId': pet.donoId,
      'tipo': Notificacao.tipoAvistamento,
      'titulo': 'Novo avistamento',
      'mensagem': partes.join(' '),
      'petId': pet.id,
      'telefone': telefone.trim(),
      'lida': false,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }
}
