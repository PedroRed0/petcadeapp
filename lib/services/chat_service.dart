import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/conversa.dart';
import '../models/pet.dart';
import 'firebase_refs.dart';
import 'prestigio_service.dart';

/// Bate-papo entre duas pessoas. Texto, fotos e áudios ficam no próprio
/// Firestore (fotos e áudios em base64, bem comprimidos) — grátis.
class ChatService {
  static const tamanhoMaximoImagem = 250 * 1024;
  static const tamanhoMaximoAudio = 400 * 1024;
  static const duracaoMaximaAudio = Duration(seconds: 60);

  CollectionReference<Map<String, dynamic>> get _conversas =>
      Fb.db.collection('conversas');

  String? get _eu => Fb.auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _mensagens(String conversaId) =>
      _conversas.doc(conversaId).collection('mensagens');

  /// Abre (ou cria) a conversa com outra pessoa. Retorna o id.
  /// Se vier de um anúncio, a pessoa também conta como "interessada" nele.
  Future<String> abrirConversa(String outroId, {Pet? pet}) async {
    final eu = _eu!;
    if (outroId == eu) {
      throw Exception('Você não pode conversar consigo mesmo.');
    }
    final id = Conversa.idEntre(eu, outroId);
    final ref = _conversas.doc(id);
    final existe = (await ref.get()).exists;
    if (!existe) {
      final ps = [eu, outroId]..sort();
      await ref.set({
        'participantes': ps,
        'criadoEm': FieldValue.serverTimestamp(),
        'ultimaMensagem': '',
        'ultimoAutor': '',
        'petNome': pet?.nome ?? '',
        'lidaPor': <String, dynamic>{},
      });
    }
    if (pet != null) {
      try {
        await PrestigioService().registrarInteresse(pet);
      } catch (_) {}
    }
    return id;
  }

  /// Minhas conversas que já têm mensagens, da mais recente para a mais antiga.
  Stream<List<Conversa>> minhasConversas() {
    final eu = _eu;
    if (eu == null) return Stream.value([]);
    return _conversas.where('participantes', arrayContains: eu).snapshots().map(
      (s) {
        final lista = s.docs
            .map(Conversa.fromDocument)
            .where((c) => c.ultimaMensagem.isNotEmpty)
            .toList();
        lista.sort(
          (a, b) => (b.ultimoEnvio ?? DateTime(2000)).compareTo(
            a.ultimoEnvio ?? DateTime(2000),
          ),
        );
        return lista;
      },
    );
  }

  /// Quantas conversas têm mensagem nova para mim.
  Stream<int> naoLidas() {
    final eu = _eu;
    if (eu == null) return Stream.value(0);
    return minhasConversas().map(
      (l) => l.where((c) => c.naoLidaPor(eu)).length,
    );
  }

  Stream<Conversa?> conversa(String id) => _conversas
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Conversa.fromDocument(d) : null);

  /// Últimas 200 mensagens, da mais antiga para a mais nova.
  Stream<List<Mensagem>> mensagens(String conversaId) {
    return _mensagens(conversaId)
        .orderBy('criadoEm', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (s) => s.docs.map(Mensagem.fromDocument).toList().reversed.toList(),
        );
  }

  Future<void> marcarComoLida(String conversaId) async {
    final eu = _eu;
    if (eu == null) return;
    await _conversas.doc(conversaId).update({
      'lidaPor.$eu': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _enviar(
    String conversaId,
    Map<String, dynamic> dados,
    String previa,
  ) async {
    final eu = _eu!;
    final lote = Fb.db.batch();
    lote.set(_mensagens(conversaId).doc(), {
      ...dados,
      'autorId': eu,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    lote.update(_conversas.doc(conversaId), {
      'ultimaMensagem': previa,
      'ultimoAutor': eu,
      'ultimoEnvio': FieldValue.serverTimestamp(),
      'lidaPor.$eu': FieldValue.serverTimestamp(),
    });
    await lote.commit();
  }

  Future<void> enviarTexto(String conversaId, String texto) {
    final t = texto.trim();
    if (t.isEmpty) return Future.value();
    final previa = t.length > 80 ? '${t.substring(0, 80)}…' : t;
    return _enviar(conversaId, {'tipo': 'texto', 'texto': t}, previa);
  }

  Future<void> enviarImagem(String conversaId, Uint8List bytes) {
    if (bytes.lengthInBytes > tamanhoMaximoImagem) {
      throw Exception('A foto ficou grande demais. Escolha outra.');
    }
    return _enviar(conversaId, {
      'tipo': 'imagem',
      'dados': base64Encode(bytes),
    }, '📷 Foto');
  }

  Future<void> enviarAudio(
    String conversaId,
    Uint8List bytes, {
    required String mime,
    required Duration duracao,
  }) {
    if (bytes.lengthInBytes > tamanhoMaximoAudio) {
      throw Exception('O áudio ficou grande demais (máx. 1 minuto).');
    }
    return _enviar(conversaId, {
      'tipo': 'audio',
      'dados': base64Encode(bytes),
      'mime': mime,
      'duracaoMs': duracao.inMilliseconds,
    }, '🎤 Áudio');
  }
}
