import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../services/endereco_service.dart';
import '../../services/localizacao_service.dart';
import '../theme/app_colors.dart';
import 'comuns.dart';

/// Escolha do local onde o pet foi visto:
/// CEP → preenche o bairro e marca o mapa;
/// bairro/endereço → "Localizar" marca o mapa;
/// toque no mapa → ajusta o ponto exato;
/// "Usar minha localização atual" → GPS (só quando a pessoa pede).
class SeletorLocal extends StatefulWidget {
  final TextEditingController localizacao;
  final LatLng? pontoInicial;
  final ValueChanged<LatLng?> onPonto;

  /// Só para testes.
  final EnderecoService? servico;

  const SeletorLocal({
    super.key,
    required this.localizacao,
    required this.onPonto,
    this.pontoInicial,
    this.servico,
  });

  @override
  State<SeletorLocal> createState() => SeletorLocalState();
}

class SeletorLocalState extends State<SeletorLocal> {
  final _cep = TextEditingController();
  final _mapa = MapController();
  late final EnderecoService _servico = widget.servico ?? EnderecoService();
  LatLng? _ponto;
  bool _buscandoCep = false;
  bool _buscandoEndereco = false;

  /// Texto da última busca que deu certo (para não buscar de novo).
  String _ultimoBuscado = '';

  @override
  void initState() {
    super.initState();
    _ponto = widget.pontoInicial;
  }

  @override
  void dispose() {
    _cep.dispose();
    super.dispose();
  }

  void _marcar(LatLng p, {double zoom = 15}) {
    setState(() => _ponto = p);
    widget.onPonto(p);
    try {
      _mapa.move(p, zoom);
    } catch (_) {
      // mapa ainda não desenhado: ele já abre no ponto certo
    }
  }

  String _erro(Object e) {
    if (e is FormatException) return e.message;
    return 'Sem conexão para buscar o endereço. Tente de novo ou toque no mapa.';
  }

  Future<void> buscarCep() async {
    FocusScope.of(context).unfocus();
    setState(() => _buscandoCep = true);
    try {
      final end = await _servico.buscarCep(_cep.text);
      if (!mounted) return;
      if (end == null) {
        mostrarAviso(context, 'CEP não encontrado.');
        return;
      }
      _cep.text = end.cep;
      widget.localizacao.text = end.resumo;
      final p = await _servico.coordenadasDoEndereco(end);
      if (!mounted) return;
      if (p == null) {
        mostrarAviso(
          context,
          'Achamos o endereço, mas não o ponto no mapa. Toque no mapa para marcar.',
        );
        return;
      }
      _ultimoBuscado = widget.localizacao.text;
      _marcar(p, zoom: end.logradouro.isNotEmpty ? 16 : 14);
    } catch (e) {
      if (mounted) mostrarAviso(context, _erro(e));
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  /// Procura no mapa o que foi digitado em "Bairro / cidade".
  /// Retorna true se marcou um ponto.
  Future<bool> localizarEndereco({bool avisar = true}) async {
    final texto = widget.localizacao.text.trim();
    if (texto.isEmpty) {
      if (avisar) mostrarAviso(context, 'Digite o bairro ou endereço.');
      return false;
    }
    FocusScope.of(context).unfocus();
    setState(() => _buscandoEndereco = true);
    try {
      final p = await _servico.buscarCoordenadas(texto);
      if (!mounted) return false;
      if (p == null) {
        if (avisar) {
          mostrarAviso(
            context,
            'Não achamos "$texto" no mapa. Confira o nome ou toque no mapa.',
          );
        }
        return false;
      }
      _ultimoBuscado = texto;
      _marcar(p, zoom: 14);
      return true;
    } catch (e) {
      if (mounted && avisar) mostrarAviso(context, _erro(e));
      return false;
    } finally {
      if (mounted) setState(() => _buscandoEndereco = false);
    }
  }

  /// Usado ao avançar: se ainda não há ponto (ou o texto mudou depois da
  /// última busca), tenta localizar o que foi digitado.
  Future<bool> garantirPonto() async {
    final texto = widget.localizacao.text.trim();
    if (_ponto != null && (_ultimoBuscado.isEmpty || _ultimoBuscado == texto)) {
      return true;
    }
    if (texto.isEmpty) return _ponto != null;
    return await localizarEndereco(avisar: false) || _ponto != null;
  }

  Future<void> _usarMinhaLocalizacao() async {
    final p = await LocalizacaoService.instancia.atualizar();
    if (!mounted) return;
    if (p == null) {
      mostrarAviso(context, 'Não foi possível obter sua localização.');
      return;
    }
    _ultimoBuscado = '';
    _marcar(p, zoom: 16);
  }

  Widget _carregando() => const Padding(
    padding: EdgeInsets.all(14),
    child: SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _rotulo(String texto) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      texto,
      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final centro =
        _ponto ??
        LocalizacaoService.instancia.posicao.value ??
        LocalizacaoService.padrao;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rotulo('CEP (opcional)'),
        TextField(
          controller: _cep,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => buscarCep(),
          decoration: InputDecoration(
            hintText: '00000-000',
            prefixIcon: const Icon(Icons.markunread_mailbox_outlined, size: 20),
            suffixIcon: _buscandoCep
                ? _carregando()
                : IconButton(
                    tooltip: 'Buscar CEP',
                    icon: const Icon(Icons.search_rounded, size: 20),
                    onPressed: buscarCep,
                  ),
          ),
        ),
        _rotulo('Bairro / endereço'),
        TextFormField(
          controller: widget.localizacao,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => localizarEndereco(),
          decoration: InputDecoration(
            hintText: 'Ex.: Vila Sônia, São Paulo - SP',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            suffixIcon: _buscandoEndereco
                ? _carregando()
                : IconButton(
                    tooltip: 'Localizar no mapa',
                    icon: const Icon(Icons.travel_explore_rounded, size: 20),
                    onPressed: localizarEndereco,
                  ),
          ),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Campo obrigatório' : null,
        ),
        _rotulo(
          _ponto == null
              ? 'Busque pelo CEP ou bairro, ou toque no mapa'
              : 'Toque no mapa para ajustar o ponto exato',
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: tema.colorScheme.outline),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: centro,
                initialZoom: _ponto == null ? 11 : 15,
                onTap: (_, p) {
                  _ultimoBuscado = '';
                  _marcar(p, zoom: _mapa.camera.zoom);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.petcade',
                ),
                if (_ponto != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _ponto!,
                        width: 36,
                        height: 36,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 36,
                          color: AppColors.laranja,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _usarMinhaLocalizacao,
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('Usar minha localização atual'),
          ),
        ),
      ],
    );
  }
}
