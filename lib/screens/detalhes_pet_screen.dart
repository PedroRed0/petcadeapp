import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatos.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/confirmacao_email.dart';
import '../core/widgets/pet_foto.dart';
import '../core/widgets/selo_status.dart';
import '../models/pet.dart';
import '../models/usuario.dart';
import '../services/localizacao_service.dart';
import '../services/notificacao_service.dart';
import '../services/pet_service.dart';
import '../services/usuario_service.dart';
import '../services/firebase_refs.dart';

void abrirDetalhesPet(BuildContext context, Pet pet) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DetalhesPetScreen(pet: pet)),
  );
}

class DetalhesPetScreen extends StatefulWidget {
  final Pet pet;

  const DetalhesPetScreen({super.key, required this.pet});

  @override
  State<DetalhesPetScreen> createState() => _DetalhesPetScreenState();
}

class _DetalhesPetScreenState extends State<DetalhesPetScreen> {
  late final Stream<Pet?> _petStream;
  late final Stream<Usuario?> _usuario;
  final _paginas = PageController();
  int _foto = 0;

  @override
  void initState() {
    super.initState();
    _petStream = widget.pet.id == null
        ? Stream.value(widget.pet)
        : PetService().pet(widget.pet.id!);
    _usuario = UsuarioService().usuarioAtual();
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  String get _meuUid => Fb.auth.currentUser?.uid ?? '';

  void _compartilhar(Pet pet) {
    final linhas = [
      '🐾 ${pet.perdido ? 'Animal perdido' : 'Animal encontrado'}: ${pet.nome}',
      if (pet.especieRaca.isNotEmpty) pet.especieRaca,
      if (pet.localizacao.isNotEmpty) 'Visto por último em: ${pet.localizacao}',
      'Data: ${formatarDataHora(pet.vistoEm)}',
      if (pet.descricao.isNotEmpty) pet.descricao,
      if (pet.recompensa != null && pet.recompensa! > 0)
        'Recompensa: R\$ ${pet.recompensa!.toStringAsFixed(0)}',
      '',
      'Viu esse pet? Avise pelo app PetCadê!',
    ];
    final texto = linhas.join('\n');
    SharePlus.instance.share(ShareParams(text: texto)).catchError((_) async {
      // Navegadores sem a função "compartilhar": copia o texto.
      await Clipboard.setData(ClipboardData(text: texto));
      if (mounted) mostrarAviso(context, 'Texto do anúncio copiado!');
      return const ShareResult('', ShareResultStatus.unavailable);
    });
  }

  Future<void> _informarAvistamento(Pet pet) async {
    if (!await exigirEmailConfirmado(context) || !mounted) return;
    final enviado = await abrirJanela<bool>(
      context: context,
      builder: (_) => _FormAvistamento(pet: pet),
    );
    if (enviado == true && mounted) {
      mostrarAviso(context, 'Obrigado! O tutor foi avisado.');
    }
  }

  Future<void> _denunciar(Pet pet) async {
    if (!await exigirEmailConfirmado(context) || !mounted) return;
    try {
      if (await PetService().jaDenunciei(pet)) {
        if (mounted) {
          mostrarAviso(context, 'Você já denunciou este anúncio. Obrigado!');
        }
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    final enviada = await abrirJanela<bool>(
      context: context,
      builder: (_) => _FormDenuncia(pet: pet),
    );
    if (enviada == true && mounted) {
      mostrarAviso(
        context,
        'Denúncia enviada. Obrigado por ajudar a manter o PetCadê seguro!',
      );
    }
  }

  Future<void> _marcarEncontrado(Pet pet) async {
    final ok = await confirmar(
      context,
      titulo: 'Pet encontrado?',
      texto:
          'O anúncio de ${pet.nome} vai para "Finalizados" e sai das buscas.',
      acao: 'Sim, foi encontrado',
    );
    if (!ok) return;
    try {
      await PetService().marcarEncontrado(pet);
      if (mounted) mostrarAviso(context, 'Que ótima notícia! 🎉');
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pet?>(
      stream: _petStream,
      initialData: widget.pet,
      builder: (context, snap) {
        final pet = snap.data;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EstadoVazio(
              icone: Icons.delete_outline_rounded,
              titulo: 'Este anúncio foi removido',
            ),
          );
        }
        final souDono = pet.donoId.isNotEmpty && pet.donoId == _meuUid;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _galeria(pet, souDono),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                sliver: SliverList.list(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SeloStatus(pet: pet),
                              const SizedBox(height: 6),
                              Text(
                                pet.nome.isEmpty ? 'Sem nome' : pet.nome,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!souDono) _botaoFavorito(pet),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Atributos(pet: pet),
                    const SizedBox(height: 22),
                    _titulo('Última vez visto'),
                    const SizedBox(height: 8),
                    _InfoLinha(
                      icone: Icons.calendar_today_outlined,
                      texto: formatarDataHora(pet.vistoEm),
                    ),
                    if (pet.localizacao.isNotEmpty)
                      _InfoLinha(
                        icone: Icons.location_on_outlined,
                        texto: pet.localizacao,
                      ),
                    ValueListenableBuilder(
                      valueListenable: LocalizacaoService.instancia.posicao,
                      builder: (context, _, _) {
                        final d = LocalizacaoService.instancia.distanciaAte(
                          pet,
                        );
                        return d == null
                            ? const SizedBox.shrink()
                            : _InfoLinha(
                                icone: Icons.near_me_outlined,
                                texto: '${formatarDistancia(d)} de você',
                              );
                      },
                    ),
                    if (pet.descricao.isNotEmpty || pet.cor.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _titulo('Características'),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (pet.cor.isNotEmpty) 'Cor: ${pet.cor}.',
                          pet.descricao,
                        ].where((s) => s.isNotEmpty).join('\n'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                    if (pet.recompensa != null && pet.recompensa! > 0) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.laranjaClaro,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.volunteer_activism_outlined,
                              size: 20,
                              color: AppColors.laranja,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Recompensa de R\$ ${pet.recompensa!.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textoPrincipal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (pet.emRevisao) ...[
                      const SizedBox(height: 18),
                      _Aviso(
                        icone: Icons.flag_outlined,
                        titulo: 'Anúncio em revisão',
                        texto: souDono
                            ? 'Seu anúncio recebeu denúncias e saiu das buscas '
                                  'até ser revisado. Se for um engano, fale com a '
                                  'gente em Ajuda e suporte.'
                            : 'Este anúncio recebeu denúncias e está sendo '
                                  'revisado. Tenha cuidado.',
                      ),
                    ],
                    if (!souDono && pet.perdido) ...[
                      const SizedBox(height: 18),
                      const _Aviso(
                        icone: Icons.shield_outlined,
                        titulo: 'Cuidado com golpes',
                        texto:
                            'Nunca faça pagamentos antecipados nem passe '
                            'códigos recebidos por SMS. Combine encontros em '
                            'locais públicos. Se algo parecer estranho, toque '
                            'na bandeira no topo para denunciar.',
                      ),
                    ],
                    if (pet.donoNome.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Anunciado por ${pet.donoNome} em ${formatarData(pet.criadoEm)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => _compartilhar(pet),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(52, 52),
                        shape: const CircleBorder(),
                      ),
                      child: const Tooltip(
                        message: 'Compartilhar',
                        child: Icon(Icons.share_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: pet.perdido
                        ? ElevatedButton(
                            onPressed: () => souDono
                                ? _marcarEncontrado(pet)
                                : _informarAvistamento(pet),
                            child: _RotuloBotao(
                              icone: souDono
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.visibility_outlined,
                              texto: souDono
                                  ? 'Marcar como encontrado'
                                  : 'Eu vi este pet',
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => _compartilhar(pet),
                            child: const _RotuloBotao(
                              icone: Icons.share_outlined,
                              texto: 'Compartilhar',
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _galeria(Pet pet, bool souDono) {
    final total = pet.fotos.isEmpty ? 1 : pet.fotos.length;
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.roxoEscuro,
      foregroundColor: Colors.white,
      actions: [
        if (!souDono && pet.id != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.3),
              child: IconButton(
                tooltip: 'Denunciar anúncio',
                icon: const Icon(
                  Icons.flag_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => _denunciar(pet),
              ),
            ),
          ),
      ],
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _paginas,
              itemCount: total,
              onPageChanged: (i) => setState(() => _foto = i),
              itemBuilder: (_, i) => PetFoto(pet: pet, indice: i),
            ),
            if (total > 1)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_foto + 1}/$total',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _botaoFavorito(Pet pet) {
    return StreamBuilder<Usuario?>(
      stream: _usuario,
      builder: (context, snap) {
        final salvo = snap.data?.favoritos.contains(pet.id) ?? false;
        return IconButton(
          tooltip: salvo ? 'Remover dos salvos' : 'Salvar',
          onPressed: pet.id == null
              ? null
              : () => UsuarioService().alternarFavorito(pet.id!, !salvo),
          icon: Icon(
            salvo ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: salvo ? AppColors.perdido : AppColors.textoSecundario,
          ),
        );
      },
    );
  }

  Widget _titulo(String texto) => Text(
    texto,
    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
  );
}

/// Ícone + texto que diminui para caber no botão (nunca quebra).
class _RotuloBotao extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _RotuloBotao({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 18),
          const SizedBox(width: 8),
          Text(texto, maxLines: 1),
        ],
      ),
    );
  }
}

/// Linha com Espécie · Peso · Sexo · Porte
class _Atributos extends StatelessWidget {
  final Pet pet;

  const _Atributos({required this.pet});

  @override
  Widget build(BuildContext context) {
    final itens = <(IconData, String)>[
      if (pet.especie.isNotEmpty) (Icons.pets_rounded, pet.especie),
      if (pet.peso != null)
        (
          Icons.monitor_weight_outlined,
          '${pet.peso!.toStringAsFixed(pet.peso! % 1 == 0 ? 0 : 1).replaceAll('.', ',')} kg',
        ),
      if (pet.sexo.isNotEmpty)
        (
          pet.sexo == 'Fêmea' ? Icons.female_rounded : Icons.male_rounded,
          pet.sexo,
        ),
      if (pet.porte.isNotEmpty) (Icons.straighten_rounded, pet.porte),
    ];
    if (itens.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < itens.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 32,
                color: Theme.of(context).colorScheme.outline,
              ),
            Expanded(
              child: Column(
                children: [
                  Icon(
                    itens[i].$1,
                    size: 18,
                    color: AppColors.destaque(context),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        itens[i].$2,
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _InfoLinha({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caixinha de aviso (segurança / revisão).
class _Aviso extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;

  const _Aviso({
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fundoDestaque(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: AppColors.destaque(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulário de denúncia.
class _FormDenuncia extends StatefulWidget {
  final Pet pet;

  const _FormDenuncia({required this.pet});

  @override
  State<_FormDenuncia> createState() => _FormDenunciaState();
}

class _FormDenunciaState extends State<_FormDenuncia> {
  final _detalhes = TextEditingController();
  String? _motivo;
  bool _enviando = false;

  @override
  void dispose() {
    _detalhes.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_motivo == null) {
      mostrarAviso(context, 'Escolha um motivo.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await PetService().denunciar(
        widget.pet,
        motivo: _motivo!,
        detalhes: _detalhes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarAviso(context, 'Não foi possível enviar a denúncia: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Denunciar anúncio',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Sua denúncia é anônima: o tutor não fica sabendo quem denunciou.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 12),
            for (final m in PetService.motivosDenuncia)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                onTap: () => setState(() => _motivo = m),
                leading: Icon(
                  _motivo == m
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: _motivo == m
                      ? AppColors.laranja
                      : AppColors.textoSecundario,
                ),
                title: Text(m, style: GoogleFonts.poppins(fontSize: 14)),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _detalhes,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Detalhes (opcional)',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enviar denúncia'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulário "Eu vi este pet".
class _FormAvistamento extends StatefulWidget {
  final Pet pet;

  const _FormAvistamento({required this.pet});

  @override
  State<_FormAvistamento> createState() => _FormAvistamentoState();
}

class _FormAvistamentoState extends State<_FormAvistamento> {
  final _onde = TextEditingController();
  final _mensagem = TextEditingController();
  final _telefone = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _onde.dispose();
    _mensagem.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_onde.text.trim().isEmpty) {
      mostrarAviso(context, 'Diga onde você viu o pet.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await NotificacaoService().informarAvistamento(
        pet: widget.pet,
        onde: _onde.text.trim(),
        mensagem: _mensagem.text.trim(),
        telefone: _telefone.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarAviso(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Você viu ${widget.pet.nome}?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'O tutor vai receber uma notificação.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _onde,
            decoration: const InputDecoration(
              hintText: 'Onde? (rua, bairro, ponto de referência)',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mensagem,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Detalhes (opcional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _telefone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Seu telefone para contato (opcional)',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar aviso'),
          ),
        ],
      ),
    );
  }
}

/// Caixa de confirmação simples.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String acao,
  bool perigo = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
        titulo,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: Text(texto, style: GoogleFonts.poppins(fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: perigo ? AppColors.perdido : AppColors.laranja,
          ),
          child: Text(acao),
        ),
      ],
    ),
  );
  return r == true;
}
