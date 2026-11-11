import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatos.dart';
import '../../core/widgets/avatar_usuario.dart';
import '../../core/widgets/comuns.dart';
import '../../core/widgets/selo_nivel.dart';
import '../../models/conversa.dart';
import '../../models/perfil_publico.dart';
import '../../models/pet.dart';
import '../../services/chat_service.dart';
import '../../services/firebase_refs.dart';
import '../../services/perfil_service.dart';

/// Abre a conversa com outra pessoa (criando, se ainda não existir).
Future<void> abrirConversaCom(
  BuildContext context,
  String outroId, {
  Pet? pet,
}) async {
  try {
    final id = await ChatService().abrirConversa(outroId, pet: pet);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversaId: id, outroId: outroId),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      mostrarAviso(
        context,
        'Não foi possível abrir a conversa: '
        '${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}

/// Conversa no estilo do Instagram: texto, emojis, fotos e áudios.
class ChatScreen extends StatefulWidget {
  final String conversaId;
  final String outroId;

  const ChatScreen({
    super.key,
    required this.conversaId,
    required this.outroId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chat = ChatService();
  final _texto = TextEditingController();
  final _foco = FocusNode();
  late final Stream<List<Mensagem>> _mensagens = _chat.mensagens(
    widget.conversaId,
  );
  late final Stream<Conversa?> _conversa = _chat.conversa(widget.conversaId);
  late final Stream<PerfilPublico?> _perfil = PerfilService().perfil(
    widget.outroId,
  );
  StreamSubscription<Conversa?>? _assinatura;

  final String _eu = Fb.auth.currentUser?.uid ?? '';
  bool _mostrarEmojis = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
    _foco.addListener(() {
      if (_foco.hasFocus && _mostrarEmojis) {
        setState(() => _mostrarEmojis = false);
      }
    });
    // Marca como lida ao abrir e sempre que chegar mensagem nova.
    _assinatura = _conversa.listen((c) {
      if (c != null && c.naoLidaPor(_eu)) {
        _chat.marcarComoLida(widget.conversaId).catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _texto.dispose();
    _foco.dispose();
    _BolhaAudioState.pararTodos();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() acao) async {
    setState(() => _enviando = true);
    try {
      await acao();
    } catch (e) {
      if (mounted) {
        mostrarAviso(
          context,
          'Não foi possível enviar: '
          '${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _enviarTexto() {
    final t = _texto.text.trim();
    if (t.isEmpty) return;
    _texto.clear();
    _executar(() => _chat.enviarTexto(widget.conversaId, t));
  }

  Future<void> _enviarFoto() async {
    final origem = await abrirJanela<ImageSource>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, size: 20),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, size: 20),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
    if (origem == null) return;
    final img = await ImagePicker().pickImage(
      source: origem,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 60,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    await _executar(() => _chat.enviarImagem(widget.conversaId, bytes));
  }

  void _inserirEmoji(String e) {
    final sel = _texto.selection;
    final t = _texto.text;
    final inicio = sel.isValid ? sel.start : t.length;
    final fim = sel.isValid ? sel.end : t.length;
    _texto.value = TextEditingValue(
      text: t.replaceRange(inicio, fim, e),
      selection: TextSelection.collapsed(offset: inicio + e.length),
    );
  }

  void _alternarEmojis() {
    if (_mostrarEmojis) {
      setState(() => _mostrarEmojis = false);
      _foco.requestFocus();
    } else {
      _foco.unfocus();
      setState(() => _mostrarEmojis = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_mostrarEmojis,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _mostrarEmojis = false);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: StreamBuilder<PerfilPublico?>(
            stream: _perfil,
            builder: (context, snap) {
              final p = snap.data;
              return Row(
                children: [
                  AvatarPerfil(perfil: p, raio: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p?.nome.isNotEmpty == true
                                    ? p!.nome
                                    : 'Usuário',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SeloNivelDe(uid: widget.outroId),
                          ],
                        ),
                        StreamBuilder<Conversa?>(
                          stream: _conversa,
                          builder: (context, c) {
                            final pet = c.data?.petNome ?? '';
                            if (pet.isEmpty) return const SizedBox.shrink();
                            return Text(
                              'sobre $pet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textoSecundario,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        body: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<Mensagem>>(
                stream: _mensagens,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return EstadoVazio(
                      icone: Icons.cloud_off_rounded,
                      titulo: 'Não foi possível carregar',
                      texto: '${snap.error}',
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final msgs = snap.data!;
                  if (msgs.isEmpty) {
                    return const EstadoVazio(
                      icone: Icons.waving_hand_outlined,
                      titulo: 'Diga olá!',
                      texto:
                          'Combine encontros em lugares públicos e nunca '
                          'faça pagamentos antecipados.',
                    );
                  }
                  return GestureDetector(
                    onTap: () {
                      _foco.unfocus();
                      if (_mostrarEmojis) {
                        setState(() => _mostrarEmojis = false);
                      }
                    },
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      itemCount: msgs.length,
                      itemBuilder: (context, i) {
                        // A lista é invertida: o item 0 é a mais nova.
                        final idx = msgs.length - 1 - i;
                        final m = msgs[idx];
                        final anterior = idx > 0 ? msgs[idx - 1] : null;
                        final proxima = idx < msgs.length - 1
                            ? msgs[idx + 1]
                            : null;
                        final novoDia =
                            anterior == null ||
                            !_mesmoDia(anterior.criadoEm, m.criadoEm);
                        final fimDoGrupo =
                            proxima == null ||
                            proxima.autorId != m.autorId ||
                            proxima.criadoEm.difference(m.criadoEm).inMinutes >
                                5;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (novoDia)
                              Center(child: _SeparadorDia(data: m.criadoEm)),
                            _LinhaMensagem(
                              key: ValueKey(m.id),
                              mensagem: m,
                              minha: m.autorId == _eu,
                              mostrarHora: fimDoGrupo,
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            _BarraDigitacao(
              texto: _texto,
              foco: _foco,
              enviando: _enviando,
              emojisAbertos: _mostrarEmojis,
              onEmoji: _alternarEmojis,
              onFoto: _enviarFoto,
              onEnviar: _enviarTexto,
              onAudio: (bytes, mime, duracao) => _executar(
                () => _chat.enviarAudio(
                  widget.conversaId,
                  bytes,
                  mime: mime,
                  duracao: duracao,
                ),
              ),
            ),
            if (_mostrarEmojis) _PainelEmojis(onEscolher: _inserirEmoji),
          ],
        ),
      ),
    );
  }
}

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _SeparadorDia extends StatelessWidget {
  final DateTime data;

  const _SeparadorDia({required this.data});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final ontem = hoje.subtract(const Duration(days: 1));
    final texto = _mesmoDia(data, hoje)
        ? 'Hoje'
        : _mesmoDia(data, ontem)
        ? 'Ontem'
        : formatarData(data);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textoSecundario,
        ),
      ),
    );
  }
}

/// Mensagem só com emojis (até 3) aparece grande, sem balão.
bool soEmojis(String t) {
  final s = t.replaceAll(RegExp(r'\s'), '');
  if (s.isEmpty || s.runes.length > 8) return false;
  if (RegExp(r'[A-Za-z0-9À-ÿ.,!?@#\$%&*()\-_=+\[\]{};:"<>/\\|~^]')
      .hasMatch(s)) {
    return false;
  }
  return s.runes.any((r) => r > 0x2000);
}

class _LinhaMensagem extends StatelessWidget {
  final Mensagem mensagem;
  final bool minha;
  final bool mostrarHora;

  const _LinhaMensagem({
    super.key,
    required this.mensagem,
    required this.minha,
    required this.mostrarHora,
  });

  @override
  Widget build(BuildContext context) {
    final m = mensagem;
    final tema = Theme.of(context);
    final corBalao = minha
        ? AppColors.roxo
        : tema.colorScheme.surfaceContainerHighest;
    final corTexto = minha ? Colors.white : tema.colorScheme.onSurface;
    final raio = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(minha || !mostrarHora ? 20 : 6),
      bottomRight: Radius.circular(!minha || !mostrarHora ? 20 : 6),
    );
    final larguraMax = MediaQuery.sizeOf(context).width * 0.72;

    Widget conteudo;
    switch (m.tipo) {
      case TipoMensagem.texto:
        if (soEmojis(m.texto)) {
          conteudo = Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(m.texto, style: const TextStyle(fontSize: 40)),
          );
        } else {
          conteudo = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: corBalao, borderRadius: raio),
            child: Text(
              m.texto,
              style: GoogleFonts.poppins(fontSize: 14.5, color: corTexto),
            ),
          );
        }
      case TipoMensagem.imagem:
        conteudo = _BolhaImagem(base64: m.dados, raio: raio);
      case TipoMensagem.audio:
        conteudo = _BolhaAudio(
          mensagem: m,
          corBalao: corBalao,
          corTexto: corTexto,
          raio: raio,
        );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: mostrarHora ? 10 : 2),
      child: Column(
        crossAxisAlignment: minha
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: larguraMax),
            child: conteudo,
          ),
          if (mostrarHora)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 6, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatarHora(m.criadoEm),
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  if (minha && m.pendente) ...[
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: AppColors.textoSecundario,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BolhaImagem extends StatelessWidget {
  final String base64;
  final BorderRadius raio;

  const _BolhaImagem({required this.base64, required this.raio});

  static final Map<int, Uint8List> _cache = {};

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = _cache[base64.hashCode] ??= base64Decode(base64);
    } catch (_) {}
    if (bytes == null) {
      return const Icon(Icons.broken_image_outlined);
    }
    final b = bytes;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _FotoTelaCheia(bytes: b)),
      ),
      child: ClipRRect(
        borderRadius: raio,
        child: Image.memory(
          b,
          width: 220,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class _FotoTelaCheia extends StatelessWidget {
  final Uint8List bytes;

  const _FotoTelaCheia({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(maxScale: 5, child: Image.memory(bytes)),
      ),
    );
  }
}

/// Balão de áudio: ▶︎ ━━━━━ 0:12
class _BolhaAudio extends StatefulWidget {
  final Mensagem mensagem;
  final Color corBalao;
  final Color corTexto;
  final BorderRadius raio;

  const _BolhaAudio({
    required this.mensagem,
    required this.corBalao,
    required this.corTexto,
    required this.raio,
  });

  @override
  State<_BolhaAudio> createState() => _BolhaAudioState();
}

class _BolhaAudioState extends State<_BolhaAudio> {
  /// Só um áudio tocando por vez.
  static _BolhaAudioState? _tocando;

  static void pararTodos() {
    _tocando?._parar();
    _tocando = null;
  }

  AudioPlayer? _player;
  final List<StreamSubscription> _assinaturas = [];
  bool _tocandoAgora = false;
  Duration _posicao = Duration.zero;

  Duration get _duracao => Duration(milliseconds: widget.mensagem.duracaoMs);

  @override
  void dispose() {
    if (_tocando == this) _tocando = null;
    for (final a in _assinaturas) {
      a.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  void _parar() {
    _player?.stop();
    if (mounted) {
      setState(() {
        _tocandoAgora = false;
        _posicao = Duration.zero;
      });
    }
  }

  Future<void> _alternar() async {
    if (_tocandoAgora) {
      await _player?.pause();
      setState(() => _tocandoAgora = false);
      return;
    }
    if (_tocando != this) {
      _tocando?._parar();
      _tocando = this;
    }
    try {
      if (_player == null) {
        final p = AudioPlayer();
        _player = p;
        _assinaturas.add(
          p.onPositionChanged.listen((d) {
            if (mounted) setState(() => _posicao = d);
          }),
        );
        _assinaturas.add(
          p.onPlayerComplete.listen((_) {
            if (mounted) {
              setState(() {
                _tocandoAgora = false;
                _posicao = Duration.zero;
              });
            }
          }),
        );
        await p.setSource(
          BytesSource(
            base64Decode(widget.mensagem.dados),
            mimeType: widget.mensagem.mime.isEmpty
                ? 'audio/mp4'
                : widget.mensagem.mime,
          ),
        );
      }
      await _player!.resume();
      if (mounted) setState(() => _tocandoAgora = true);
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Não foi possível tocar o áudio.');
    }
  }

  String _formatar(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = _duracao.inMilliseconds;
    final progresso = total == 0
        ? 0.0
        : (_posicao.inMilliseconds / total).clamp(0.0, 1.0);
    return Container(
      width: 220,
      padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
      decoration: BoxDecoration(
        color: widget.corBalao,
        borderRadius: widget.raio,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: _tocandoAgora ? 'Pausar' : 'Ouvir',
            onPressed: _alternar,
            icon: Icon(
              _tocandoAgora ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: widget.corTexto,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 3,
                color: widget.corTexto,
                backgroundColor: widget.corTexto.withValues(alpha: 0.25),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatar(
              _tocandoAgora || _posicao > Duration.zero ? _posicao : _duracao,
            ),
            style: GoogleFonts.poppins(fontSize: 12, color: widget.corTexto),
          ),
        ],
      ),
    );
  }
}

/// Barra de digitação: 😊 [ Mensagem... ] 🖼️ 🎤  /  ➤
class _BarraDigitacao extends StatefulWidget {
  final TextEditingController texto;
  final FocusNode foco;
  final bool enviando;
  final bool emojisAbertos;
  final VoidCallback onEmoji;
  final VoidCallback onFoto;
  final VoidCallback onEnviar;
  final void Function(Uint8List bytes, String mime, Duration duracao) onAudio;

  const _BarraDigitacao({
    required this.texto,
    required this.foco,
    required this.enviando,
    required this.emojisAbertos,
    required this.onEmoji,
    required this.onFoto,
    required this.onEnviar,
    required this.onAudio,
  });

  @override
  State<_BarraDigitacao> createState() => _BarraDigitacaoState();
}

class _BarraDigitacaoState extends State<_BarraDigitacao> {
  AudioRecorder? _gravador;
  bool _gravando = false;
  final _cronometro = Stopwatch();
  Timer? _timer;
  String _mime = 'audio/mp4';

  @override
  void dispose() {
    _timer?.cancel();
    _gravador?.dispose();
    super.dispose();
  }

  Future<void> _comecarGravacao() async {
    try {
      final g = _gravador ??= AudioRecorder();
      if (!await g.hasPermission()) {
        if (mounted) {
          mostrarAviso(context, 'Permita o uso do microfone para gravar.');
        }
        return;
      }
      // AAC (m4a) toca em Android e iPhone. Se o navegador não gravar AAC,
      // usa Opus.
      var encoder = AudioEncoder.aacLc;
      if (kIsWeb && !await g.isEncoderSupported(AudioEncoder.aacLc)) {
        encoder = AudioEncoder.opus;
      }
      _mime = encoder == AudioEncoder.opus ? 'audio/webm' : 'audio/mp4';
      var caminho = '';
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        caminho =
            '${dir.path}/petcade_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      await g.start(
        RecordConfig(
          encoder: encoder,
          bitRate: 32000,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: caminho,
      );
      _cronometro
        ..reset()
        ..start();
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!mounted) return;
        setState(() {});
        if (_cronometro.elapsed >= ChatService.duracaoMaximaAudio) {
          _pararGravacao(enviar: true);
        }
      });
      setState(() => _gravando = true);
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Não foi possível gravar o áudio.');
    }
  }

  Future<void> _pararGravacao({required bool enviar}) async {
    if (!_gravando) return;
    _timer?.cancel();
    _cronometro.stop();
    final duracao = _cronometro.elapsed;
    setState(() => _gravando = false);
    try {
      if (!enviar) {
        await _gravador?.cancel();
        return;
      }
      final caminho = await _gravador?.stop();
      if (caminho == null) return;
      if (duracao < const Duration(milliseconds: 700)) {
        if (mounted) mostrarAviso(context, 'Áudio muito curto.');
        return;
      }
      // Funciona com arquivo (Android) e com endereço "blob:" (navegador).
      final bytes = await XFile(caminho).readAsBytes();
      widget.onAudio(bytes, _mime, duracao);
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Não foi possível gravar o áudio.');
    }
  }

  String get _tempo {
    final d = _cronometro.elapsed;
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final temTexto = widget.texto.text.trim().isNotEmpty;

    Widget conteudo;
    if (_gravando) {
      conteudo = Row(
        children: [
          IconButton(
            tooltip: 'Cancelar áudio',
            onPressed: () => _pararGravacao(enviar: false),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.perdido,
            ),
          ),
          const _PontoGravando(),
          const SizedBox(width: 8),
          Text(
            _tempo,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gravando…',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textoSecundario,
              ),
            ),
          ),
          _BotaoEnviar(onTap: () => _pararGravacao(enviar: true)),
        ],
      );
    } else {
      conteudo = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: widget.emojisAbertos ? 'Teclado' : 'Emojis',
            onPressed: widget.onEmoji,
            icon: Icon(
              widget.emojisAbertos
                  ? Icons.keyboard_outlined
                  : Icons.emoji_emotions_outlined,
              color: AppColors.textoSecundario,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.texto,
              focusNode: widget.foco,
              minLines: 1,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.poppins(fontSize: 14.5),
              decoration: const InputDecoration(
                hintText: 'Mensagem…',
                counterText: '',
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (temTexto)
            Padding(
              padding: const EdgeInsets.all(4),
              child: _BotaoEnviar(
                onTap: widget.enviando ? null : widget.onEnviar,
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Enviar foto',
              onPressed: widget.enviando ? null : widget.onFoto,
              icon: const Icon(
                Icons.image_outlined,
                color: AppColors.textoSecundario,
              ),
            ),
            IconButton(
              tooltip: 'Gravar áudio',
              onPressed: widget.enviando ? null : _comecarGravacao,
              icon: const Icon(
                Icons.mic_none_rounded,
                color: AppColors.textoSecundario,
              ),
            ),
          ],
        ],
      );
    }

    return SafeArea(
      top: false,
      bottom: !widget.emojisAbertos,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: tema.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: [
              conteudo,
              if (widget.enviando)
                const Positioned(
                  left: 24,
                  right: 24,
                  bottom: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotaoEnviar extends StatelessWidget {
  final VoidCallback? onTap;

  const _BotaoEnviar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.roxo,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Tooltip(
            message: 'Enviar',
            child: Icon(Icons.send_rounded, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PontoGravando extends StatefulWidget {
  const _PontoGravando();

  @override
  State<_PontoGravando> createState() => _PontoGravandoState();
}

class _PontoGravandoState extends State<_PontoGravando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.perdido,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Painel de emojis (sem pacote extra).
class _PainelEmojis extends StatelessWidget {
  final ValueChanged<String> onEscolher;

  const _PainelEmojis({required this.onEscolher});

  static const emojis = [
    // carinhas
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
    '🙂', '😉', '😍', '🥰', '😘', '😋', '😜', '🤗', '🤩', '🥳',
    '😎', '🤔', '🤨', '😐', '😶', '🙄', '😏', '😮', '😯', '😲',
    '😳', '🥺', '😢', '😭', '😤', '😠', '😡', '🤯', '😱', '😴',
    // gestos
    '👍', '👎', '👏', '🙌', '🙏', '🤝', '👋', '✌️', '🤞', '💪',
    '👀', '👉', '👆', '👌', '🫶', '✋',
    // corações
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🤍', '🖤', '💔', '💕',
    // pets e natureza
    '🐶', '🐕', '🦮', '🐩', '🐱', '🐈', '🐈‍⬛', '🐾', '🐰', '🐹',
    '🐦', '🐢', '🦴', '🏠', '📍', '🗺️', '🔍', '📸', '🌳', '🌧️',
    // outros
    '✅', '❗', '❓', '⭐', '🎉', '🔥', '💯', '🙈', '😺', '😻',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 46,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, i) => InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onEscolher(emojis[i]),
            child: Center(
              child: Text(emojis[i], style: const TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ),
    );
  }
}
