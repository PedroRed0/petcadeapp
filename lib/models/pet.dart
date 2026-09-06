import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String? id;
  final String nome;
  final String especie;
  final String racaCor;
  final String descricao;
  final String fotoUrl;
  final String localizacao;
  final double latitude;
  final double longitude;
  final double? recompensa;
  final DateTime criadoEm;

  const Pet({
    this.id,
    required this.nome,
    required this.especie,
    required this.racaCor,
    required this.descricao,
    required this.fotoUrl,
    required this.localizacao,
    required this.latitude,
    required this.longitude,
    this.recompensa,
    required this.criadoEm,
  });

  // Converte o objeto Dart em algo que o Firestore consegue salvar
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'especie': especie,
      'racaCor': racaCor,
      'descricao': descricao,
      'fotoUrl': fotoUrl,
      'localizacao': localizacao,
      'latitude': latitude,
      'longitude': longitude,
      'recompensa': recompensa,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  // Converte um documento do Firestore de volta em um objeto Pet
  factory Pet.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      nome: data['nome'] ?? '',
      especie: data['especie'] ?? '',
      racaCor: data['racaCor'] ?? '',
      descricao: data['descricao'] ?? '',
      fotoUrl: data['fotoUrl'] ?? '',
      localizacao: data['localizacao'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      recompensa: data['recompensa']?.toDouble(),
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
