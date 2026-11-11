import 'package:cloud_firestore/cloud_firestore.dart';

class Notificacao {
  static const tipoAvistamento = 'avistamento';
  static const tipoEncontrado = 'encontrado';
  static const tipoAjuda = 'ajuda';

  final String id;
  final String paraId;
  final String autorId;
  final String tipo;
  final String titulo;
  final String mensagem;
  final String petId;
  final String telefone; // contato de quem viu o pet (opcional)
  final bool lida;
  final DateTime criadoEm;

  const Notificacao({
    required this.id,
    required this.paraId,
    this.autorId = '',
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.petId = '',
    this.telefone = '',
    this.lida = false,
    required this.criadoEm,
  });

  factory Notificacao.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final criado = data['criadoEm'];
    return Notificacao(
      id: doc.id,
      paraId: data['paraId']?.toString() ?? '',
      autorId: data['autorId']?.toString() ?? '',
      tipo: data['tipo']?.toString() ?? '',
      titulo: data['titulo']?.toString() ?? '',
      mensagem: data['mensagem']?.toString() ?? '',
      petId: data['petId']?.toString() ?? '',
      telefone: data['telefone']?.toString() ?? '',
      lida: data['lida'] == true,
      criadoEm: criado is Timestamp ? criado.toDate() : DateTime.now(),
    );
  }
}
