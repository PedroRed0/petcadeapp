import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _data(dynamic v) => v is Timestamp ? v.toDate() : null;

/// Conversa entre duas pessoas. O id é `uidMenor_uidMaior`.
class Conversa {
  final String id;
  final List<String> participantes;
  final String ultimaMensagem;
  final String ultimoAutor;
  final DateTime? ultimoEnvio;
  final Map<String, DateTime?> lidaPor;
  final String petNome;

  const Conversa({
    required this.id,
    required this.participantes,
    this.ultimaMensagem = '',
    this.ultimoAutor = '',
    this.ultimoEnvio,
    this.lidaPor = const {},
    this.petNome = '',
  });

  static String idEntre(String a, String b) {
    final l = [a, b]..sort();
    return '${l[0]}_${l[1]}';
  }

  String outro(String eu) =>
      participantes.firstWhere((p) => p != eu, orElse: () => '');

  bool naoLidaPor(String eu) {
    if (ultimoEnvio == null || ultimoAutor == eu || ultimoAutor.isEmpty) {
      return false;
    }
    final lida = lidaPor[eu];
    return lida == null || lida.isBefore(ultimoEnvio!);
  }

  factory Conversa.fromDocument(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    final lidas = <String, DateTime?>{};
    if (d['lidaPor'] is Map) {
      (d['lidaPor'] as Map).forEach((k, v) => lidas['$k'] = _data(v));
    }
    return Conversa(
      id: doc.id,
      participantes: [
        if (d['participantes'] is List)
          ...(d['participantes'] as List).map((e) => '$e'),
      ],
      ultimaMensagem: d['ultimaMensagem']?.toString() ?? '',
      ultimoAutor: d['ultimoAutor']?.toString() ?? '',
      // Enquanto o servidor não confirma o horário, usa "agora".
      ultimoEnvio:
          _data(d['ultimoEnvio']) ??
          (d.containsKey('ultimoEnvio') && d['ultimaMensagem'] != ''
              ? DateTime.now()
              : null),
      lidaPor: lidas,
      petNome: d['petNome']?.toString() ?? '',
    );
  }
}

enum TipoMensagem { texto, imagem, audio }

class Mensagem {
  final String id;
  final String autorId;
  final TipoMensagem tipo;
  final String texto;
  final String dados; // base64 da imagem ou do áudio
  final String mime; // tipo do áudio (ex.: audio/mp4)
  final int duracaoMs;
  final DateTime criadoEm;
  final bool pendente; // ainda enviando

  const Mensagem({
    required this.id,
    required this.autorId,
    required this.tipo,
    this.texto = '',
    this.dados = '',
    this.mime = '',
    this.duracaoMs = 0,
    required this.criadoEm,
    this.pendente = false,
  });

  factory Mensagem.fromDocument(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    final tipo = TipoMensagem.values.firstWhere(
      (t) => t.name == d['tipo'],
      orElse: () => TipoMensagem.texto,
    );
    final criado = _data(d['criadoEm']);
    return Mensagem(
      id: doc.id,
      autorId: d['autorId']?.toString() ?? '',
      tipo: tipo,
      texto: d['texto']?.toString() ?? '',
      dados: d['dados']?.toString() ?? '',
      mime: d['mime']?.toString() ?? '',
      duracaoMs: (d['duracaoMs'] is num) ? (d['duracaoMs'] as num).toInt() : 0,
      criadoEm: criado ?? DateTime.now(),
      pendente: criado == null,
    );
  }
}
