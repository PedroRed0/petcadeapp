import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final List<String> favoritos; // ids dos pets salvos

  /// Foto de perfil escolhida no app (base64, salva no Firestore).
  final String foto;

  /// Foto da conta Google (usada se não houver [foto]).
  final String fotoUrl;

  const Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    this.telefone = '',
    this.favoritos = const [],
    this.foto = '',
    this.fotoUrl = '',
  });

  factory Usuario.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Usuario(
      uid: doc.id,
      nome: data['nome']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      telefone: data['telefone']?.toString() ?? '',
      foto: data['foto']?.toString() ?? '',
      fotoUrl: data['fotoUrl']?.toString() ?? '',
      favoritos: [
        if (data['favoritos'] is List)
          ...(data['favoritos'] as List).map((e) => e.toString()),
      ],
    );
  }
}
