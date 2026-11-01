import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  static const statusPerdido = 'perdido';
  static const statusEncontrado = 'encontrado';

  final String? id;
  final String nome;
  final String especie; // Cachorro, Gato, Outro
  final String raca;
  final String cor;
  final String sexo; // Macho, Fêmea, Não sei
  final String porte; // Pequeno, Médio, Grande
  final double? peso; // kg
  final String descricao; // características

  /// Fotos salvas direto no Firestore como texto (base64), sem precisar do
  /// Firebase Storage (que exige o plano pago Blaze).
  final List<String> fotos;

  /// Só para cadastros antigos que tinham URL.
  final String fotoUrl;

  final String localizacao; // bairro / cidade
  final double latitude;
  final double longitude;
  final DateTime vistoEm; // última vez visto
  final double? recompensa;
  final String status;

  final String donoId;
  final String donoNome;

  final DateTime criadoEm;

  const Pet({
    this.id,
    required this.nome,
    required this.especie,
    this.raca = '',
    this.cor = '',
    this.sexo = '',
    this.porte = '',
    this.peso,
    this.descricao = '',
    this.fotos = const [],
    this.fotoUrl = '',
    this.localizacao = '',
    this.latitude = 0,
    this.longitude = 0,
    required this.vistoEm,
    this.recompensa,
    this.status = statusPerdido,
    this.donoId = '',
    this.donoNome = '',
    required this.criadoEm,
  });

  bool get perdido => status != statusEncontrado;
  bool get temLocal => latitude != 0 || longitude != 0;

  /// "Cachorro - Pug"
  String get especieRaca =>
      [especie, raca].where((s) => s.trim().isNotEmpty).join(' - ');

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'especie': especie,
      'raca': raca,
      'cor': cor,
      'sexo': sexo,
      'porte': porte,
      'peso': peso,
      'descricao': descricao,
      'fotos': fotos,
      'localizacao': localizacao,
      'latitude': latitude,
      'longitude': longitude,
      'vistoEm': Timestamp.fromDate(vistoEm),
      'recompensa': recompensa,
      'status': status,
      'donoId': donoId,
      'donoNome': donoNome,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  factory Pet.fromMap(String? id, Map<String, dynamic> data) {
    double? paraDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    DateTime? paraData(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    String txt(String campo) => data[campo]?.toString() ?? '';

    // Fotos: formato novo (lista) ou antigo (um campo só)
    final fotos = <String>[
      if (data['fotos'] is List)
        ...(data['fotos'] as List).map((e) => e.toString()),
    ];
    if (fotos.isEmpty && txt('fotoBase64').isNotEmpty) {
      fotos.add(txt('fotoBase64'));
    }

    final criadoEm = paraData(data['criadoEm']) ?? DateTime.now();

    return Pet(
      id: id,
      nome: txt('nome'),
      especie: txt('especie'),
      // cadastros antigos tinham "racaCor" num campo só
      raca: txt('raca').isNotEmpty ? txt('raca') : txt('racaCor'),
      cor: txt('cor'),
      sexo: txt('sexo'),
      porte: txt('porte'),
      peso: paraDouble(data['peso']),
      descricao: txt('descricao'),
      fotos: fotos,
      fotoUrl: txt('fotoUrl'),
      localizacao: txt('localizacao'),
      latitude: paraDouble(data['latitude']) ?? 0,
      longitude: paraDouble(data['longitude']) ?? 0,
      vistoEm: paraData(data['vistoEm']) ?? criadoEm,
      recompensa: paraDouble(data['recompensa']),
      status: txt('status').isEmpty ? statusPerdido : txt('status'),
      donoId: txt('donoId'),
      donoNome: txt('donoNome'),
      criadoEm: criadoEm,
    );
  }

  factory Pet.fromDocument(DocumentSnapshot doc) =>
      Pet.fromMap(doc.id, (doc.data() as Map<String, dynamic>?) ?? {});
}
