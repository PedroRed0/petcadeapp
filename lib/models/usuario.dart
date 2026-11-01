import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final List<String> favoritos; // ids dos pets salvos

  const Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    this.telefone = '',
    this.favoritos = const [],
  });

  factory Usuario.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Usuario(
      uid: doc.id,
      nome: data['nome']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      telefone: data['telefone']?.toString() ?? '',
      favoritos: [
        if (data['favoritos'] is List)
          ...(data['favoritos'] as List).map((e) => e.toString()),
      ],
    );
  }
}
