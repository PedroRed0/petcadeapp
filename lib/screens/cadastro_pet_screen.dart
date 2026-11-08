import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatos.dart';
import '../core/widgets/comuns.dart';
import '../core/widgets/pet_card.dart';
import '../core/widgets/seletor_local.dart';
import '../models/pet.dart';
import '../services/endereco_service.dart';
import '../services/pet_service.dart';
import '../services/firebase_refs.dart';

/// Cadastro em 4 etapas: Informações → Fotos → Localização → Confirmar
class CadastroPetScreen extends StatefulWidget {
  /// Só para os testes automáticos (começar já com fotos).
  @visibleForTesting
  final List<Uint8List> fotosIniciais;

  /// Só para os testes automáticos (busca de endereço simulada).
  @visibleForTesting
  final EnderecoService? enderecoService;

  const CadastroPetScreen({
    super.key,
    this.fotosIniciais = const [],
    this.enderecoService,
  });

  @override
  State<CadastroPetScreen> createState() => _CadastroPetScreenState();
}

class _CadastroPetScreenState extends State<CadastroPetScreen> {
  static const _etapas = ['Informações', 'Fotos', 'Localização', 'Confirmar'];

  int _etapa = 0;
  bool _enviando = false;
  final _petService = PetService();

  // Etapa 1
  final _formInfo = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _raca = TextEditingController();
  final _cor = TextEditingController();
  final _peso = TextEditingController();
  final _descricao = TextEditingController();
  final _recompensa = TextEditingController();
  String _especie = 'Cachorro';
  String _sexo = 'Macho';
  String _porte = 'Médio';

  // Etapa 2
  final List<Uint8List> _fotos = [];

  // Etapa 3
  final _formLocal = GlobalKey<FormState>();
  final _localizacao = TextEditingController();
  final _seletor = GlobalKey<SeletorLocalState>();
  LatLng? _ponto;
  DateTime _vistoEm = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fotos.addAll(widget.fotosIniciais);
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _raca,
      _cor,
      _peso,
      _descricao,
      _recompensa,
      _localizacao,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _numero(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Pet _montarPet() {
    final user = Fb.auth.currentUser;
    return Pet(
      nome: _nome.text.trim(),
      especie: _especie,
      raca: _raca.text.trim(),
      cor: _cor.text.trim(),
      sexo: _sexo,
      porte: _porte,
      peso: _numero(_peso),
      descricao: _descricao.text.trim(),
      fotos: _fotos.map(_petService.converterFoto).toList(),
      localizacao: _localizacao.text.trim(),
      latitude: _ponto?.latitude ?? 0,
      longitude: _ponto?.longitude ?? 0,
      vistoEm: _vistoEm,
      recompensa: _numero(_recompensa),
      donoId: user?.uid ?? '',
      // Só o primeiro nome fica público no anúncio.
      donoNome: primeiroNome(user?.displayName ?? ''),
      criadoEm: DateTime.now(),
    );
  }

  Future<void> _proximo() async {
    FocusScope.of(context).unfocus();
    switch (_etapa) {
      case 0:
        if (!_formInfo.currentState!.validate()) return;
      case 1:
        if (_fotos.isEmpty) {
          mostrarAviso(context, 'Adicione pelo menos uma foto do pet.');
          return;
        }
      case 2:
        if (!_formLocal.currentState!.validate()) return;
        // Se a pessoa só digitou o bairro, localiza no mapa sozinho.
        final ok = await _seletor.currentState?.garantirPonto() ?? false;
        if (!mounted) return;
        if (!ok || _ponto == null) {
          mostrarAviso(
            context,
            'Não achamos esse local no mapa. Use o CEP ou toque no mapa.',
          );
          return;
        }
      case 3:
        _publicar();
        return;
    }
    setState(() => _etapa++);
  }

  void _voltar() {
    if (_etapa == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _etapa--);
    }
  }

  Future<void> _publicar() async {
    setState(() => _enviando = true);
    try {
      await _petService.cadastrarPet(_montarPet());
      if (mounted) {
        mostrarAviso(context, 'Anúncio publicado! Torcemos por vocês 🧡');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        mostrarAviso(
          context,
          'Erro ao publicar: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _adicionarFoto(ImageSource origem) async {
    if (_fotos.length >= PetService.maxFotos) {
      mostrarAviso(context, 'Máximo de ${PetService.maxFotos} fotos.');
      return;
    }
    try {
      // Reduz e comprime para caber no Firestore (máx. 1 MB por anúncio).
      final imagem = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 55,
      );
      if (imagem == null) return;
      final bytes = await imagem.readAsBytes();
      if (bytes.lengthInBytes > PetService.tamanhoMaximoFotoBytes) {
        if (mounted) mostrarAviso(context, 'Foto muito grande. Tente outra.');
        return;
      }
      setState(() => _fotos.add(bytes));
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Não foi possível abrir a foto.');
    }
  }

  Future<void> _escolherDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _vistoEm,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (data == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_vistoEm),
    );
    setState(() {
      _vistoEm = DateTime(
        data.year,
        data.month,
        data.day,
        hora?.hour ?? _vistoEm.hour,
        hora?.minute ?? _vistoEm.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _etapa == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cadastrar animal perdido'),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _voltar,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: _Progresso(etapas: _etapas, atual: _etapa),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_etapa),
                  child: switch (_etapa) {
                    0 => _etapaInformacoes(),
                    1 => _etapaFotos(),
                    2 => _etapaLocalizacao(),
                    _ => _etapaConfirmar(),
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: ElevatedButton(
                  onPressed: _enviando ? null : _proximo,
                  child: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_etapa == 3 ? 'Publicar anúncio' : 'Próximo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Etapa 1 ----------
  Widget _etapaInformacoes() {
    return Form(
      key: _formInfo,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          _rotulo('Nome do pet'),
          TextFormField(
            controller: _nome,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Ex.: Thor'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Campo obrigatório' : null,
          ),
          _rotulo('Espécie'),
          _Opcoes(
            opcoes: const ['Cachorro', 'Gato', 'Outro'],
            valor: _especie,
            onChanged: (v) => setState(() => _especie = v),
          ),
          _rotulo('Raça'),
          TextFormField(
            controller: _raca,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ex.: Pug, SRD (vira-lata)',
            ),
          ),
          _rotulo('Cor'),
          TextFormField(
            controller: _cor,
            decoration: const InputDecoration(hintText: 'Ex.: Caramelo'),
          ),
          _rotulo('Sexo'),
          _Opcoes(
            opcoes: const ['Macho', 'Fêmea', 'Não sei'],
            valor: _sexo,
            onChanged: (v) => setState(() => _sexo = v),
          ),
          _rotulo('Porte'),
          _Opcoes(
            opcoes: const ['Pequeno', 'Médio', 'Grande'],
            valor: _porte,
            onChanged: (v) => setState(() => _porte = v),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rotulo('Peso (kg)'),
                    TextFormField(
                      controller: _peso,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(hintText: 'Opcional'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rotulo('Recompensa (R\$)'),
                    TextFormField(
                      controller: _recompensa,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Opcional'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _rotulo('Características'),
          TextFormField(
            controller: _descricao,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Coleira, manchas, cicatriz, comportamento...',
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Descreva o pet' : null,
          ),
        ],
      ),
    );
  }

  // ---------- Etapa 2 ----------
  Widget _etapaFotos() {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tema.colorScheme.outline),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.laranjaClaro,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 22,
                      color: AppColors.laranja,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adicione fotos do seu pet',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Fotos ajudam muito na identificação (até ${PetService.maxFotos})',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _BotaoFoto(
                      icone: Icons.photo_camera_outlined,
                      texto: 'Tirar foto',
                      onTap: () => _adicionarFoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BotaoFoto(
                      icone: Icons.photo_library_outlined,
                      texto: 'Galeria',
                      onTap: () => _adicionarFoto(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_fotos.isNotEmpty)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var i = 0; i < _fotos.length; i++)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(_fotos[i], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _fotos.removeAt(i)),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (i == 0)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.laranja,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Capa',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  // ---------- Etapa 3 ----------
  Widget _etapaLocalizacao() {
    return Form(
      key: _formLocal,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          _rotulo('Quando foi visto pela última vez?'),
          InkWell(
            onTap: _escolherDataHora,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
              ),
              child: Text(
                formatarDataHora(_vistoEm),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ),
          SeletorLocal(
            key: _seletor,
            localizacao: _localizacao,
            pontoInicial: _ponto,
            servico: widget.enderecoService,
            onPonto: (p) => setState(() => _ponto = p),
          ),
        ],
      ),
    );
  }

  // ---------- Etapa 4 ----------
  Widget _etapaConfirmar() {
    Pet? previa;
    try {
      previa = _montarPet();
    } catch (_) {}
    final linhas = <(String, String)>[
      ('Espécie', _especie),
      if (_raca.text.trim().isNotEmpty) ('Raça', _raca.text.trim()),
      if (_cor.text.trim().isNotEmpty) ('Cor', _cor.text.trim()),
      ('Sexo', _sexo),
      ('Porte', _porte),
      if (_numero(_peso) != null) ('Peso', '${_peso.text.trim()} kg'),
      ('Visto em', formatarDataHora(_vistoEm)),
      ('Local', _localizacao.text.trim()),
      if (_numero(_recompensa) != null)
        ('Recompensa', 'R\$ ${_recompensa.text.trim()}'),
      ('Fotos', '${_fotos.length}'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        Text(
          'Confira antes de publicar',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Text(
          'É assim que o anúncio vai aparecer:',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textoSecundario,
          ),
        ),
        const SizedBox(height: 12),
        if (previa != null) PetCard(pet: previa),
        const SizedBox(height: 16),
        for (final (rotulo, valor) in linhas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    rotulo,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    valor,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _rotulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      texto,
      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

/// Indicador 1 — 2 — 3 — 4
class _Progresso extends StatelessWidget {
  final List<String> etapas;
  final int atual;

  const _Progresso({required this.etapas, required this.atual});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < etapas.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == 0
                            ? Colors.transparent
                            : (i <= atual
                                  ? AppColors.laranja
                                  : tema.colorScheme.outline),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= atual
                            ? AppColors.laranja
                            : tema.colorScheme.surfaceContainerHighest,
                      ),
                      child: i < atual
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: i <= atual
                                    ? Colors.white
                                    : AppColors.textoSecundario,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == etapas.length - 1
                            ? Colors.transparent
                            : (i < atual
                                  ? AppColors.laranja
                                  : tema.colorScheme.outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  etapas[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: i == atual ? FontWeight.w600 : FontWeight.w400,
                    color: i == atual
                        ? tema.colorScheme.onSurface
                        : AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Opcoes extends StatelessWidget {
  final List<String> opcoes;
  final String valor;
  final ValueChanged<String> onChanged;

  const _Opcoes({
    required this.opcoes,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final o in opcoes)
          ChoiceChip(
            label: Text(o),
            selected: valor == o,
            onSelected: (_) => onChanged(o),
          ),
      ],
    );
  }
}

class _BotaoFoto extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;

  const _BotaoFoto({
    required this.icone,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fundoDestaque(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icone, size: 24, color: AppColors.destaque(context)),
              const SizedBox(height: 6),
              Text(
                texto,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.destaque(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
