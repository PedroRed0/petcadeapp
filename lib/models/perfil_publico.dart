import 'package:cloud_firestore/cloud_firestore.dart';

/// O que outras pessoas podem ver de um usuário (no bate-papo, por exemplo).
/// Nada de e-mail ou telefone aqui.
class PerfilPublico {
  final String uid;
  final String nome; // ex.: "Pedro R."
  final String foto; // base64 (pequena)
  final String fotoUrl; // foto do Google

  const PerfilPublico({
    required this.uid,
    required this.nome,
    this.foto = '',
    this.fotoUrl = '',
  });

  factory PerfilPublico.fromDocument(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return PerfilPublico(
      uid: doc.id,
      nome: d['nome']?.toString() ?? '',
      foto: d['foto']?.toString() ?? '',
      fotoUrl: d['fotoUrl']?.toString() ?? '',
    );
  }

  /// "Pedro Henrique Rodrigues" → "Pedro R."
  static String nomeCurto(String completo) {
    final partes = completo.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (partes.isEmpty) return '';
    if (partes.length == 1) return partes.first;
    return '${partes.first} ${partes.last[0].toUpperCase()}.';
  }
}
