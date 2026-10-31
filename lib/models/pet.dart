import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String? id;
  final String nome;
  final String especie;
  final String racaCor;
  final String descricao;

  /// Foto salva direto no Firestore como texto (base64), sem precisar do
  /// Firebase Storage (que exige o plano pago Blaze).
  final String fotoBase64;

  /// Mantido só por compatibilidade com cadastros antigos que tinham URL.
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
    this.fotoBase64 = '',
    this.fotoUrl = '',
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
      'fotoBase64': fotoBase64,
      'fotoUrl': fotoUrl,
      'localizacao': localizacao,
      'latitude': latitude,
      'longitude': longitude,
      'recompensa': recompensa,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  // Converte um documento do Firestore de volta em um objeto Pet.
  // É tolerante a campos faltando ou com tipo diferente, para que um
  // documento "estranho" não derrube a lista inteira.
  factory Pet.fromDocument(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    double? paraDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    DateTime paraData(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return Pet(
      id: doc.id,
      nome: data['nome']?.toString() ?? '',
      especie: data['especie']?.toString() ?? '',
      racaCor: data['racaCor']?.toString() ?? '',
      descricao: data['descricao']?.toString() ?? '',
      fotoBase64: data['fotoBase64']?.toString() ?? '',
      fotoUrl: data['fotoUrl']?.toString() ?? '',
      localizacao: data['localizacao']?.toString() ?? '',
      latitude: paraDouble(data['latitude']) ?? 0,
      longitude: paraDouble(data['longitude']) ?? 0,
      recompensa: paraDouble(data['recompensa']),
      criadoEm: paraData(data['criadoEm']),
    );
  }
}
