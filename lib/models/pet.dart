import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  static const statusPerdido = 'perdido';
  static const statusEncontrado = 'encontrado';

  /// Com esta quantidade de denúncias o anúncio some das buscas até ser
  /// revisado (no Firebase Console, zerando o campo "denuncias").
  static const limiteDenuncias = 3;

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

  /// Quem salvou o anúncio (recebe aviso quando o pet for encontrado).
  final List<String> seguidores;

  /// Quantas pessoas denunciaram o anúncio.
  final int denuncias;

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
    this.seguidores = const [],
    this.denuncias = 0,
    required this.criadoEm,
  });

  bool get perdido => status != statusEncontrado;
  bool get temLocal => latitude != 0 || longitude != 0;
  bool get emRevisao => denuncias >= limiteDenuncias;

  /// "Cachorro - Pug"
  String get especieRaca {
    final r = raca.trim();
    if (r.isEmpty || r.toLowerCase() == especie.trim().toLowerCase()) {
      return especie;
    }
    return especie.isEmpty ? r : '$especie - $r';
  }

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
      'seguidores': seguidores,
      'denuncias': denuncias,
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
      seguidores: [
        if (data['seguidores'] is List)
          ...(data['seguidores'] as List).map((e) => e.toString()),
      ],
      denuncias: (data['denuncias'] is num)
          ? (data['denuncias'] as num).toInt()
          : 0,
      criadoEm: criadoEm,
    );
  }

  factory Pet.fromDocument(DocumentSnapshot doc) =>
      Pet.fromMap(doc.id, (doc.data() as Map<String, dynamic>?) ?? {});
}
