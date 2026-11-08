import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/comuns.dart';
import '../../core/widgets/seletor_local.dart';
import '../../models/pet.dart';
import '../../services/endereco_service.dart';
import '../../services/pet_service.dart';

/// Corrige o local de um anúncio já publicado.
class AlterarLocalScreen extends StatefulWidget {
  final Pet pet;

  /// Só para testes.
  final EnderecoService? servico;

  const AlterarLocalScreen({super.key, required this.pet, this.servico});

  @override
  State<AlterarLocalScreen> createState() => _AlterarLocalScreenState();
}

class _AlterarLocalScreenState extends State<AlterarLocalScreen> {
  final _form = GlobalKey<FormState>();
  final _seletor = GlobalKey<SeletorLocalState>();
  late final _localizacao = TextEditingController(text: widget.pet.localizacao);
  LatLng? _ponto;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.pet.temLocal) {
      _ponto = LatLng(widget.pet.latitude, widget.pet.longitude);
    }
  }

  @override
  void dispose() {
    _localizacao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final ok = await _seletor.currentState?.garantirPonto() ?? false;
      if (!mounted) return;
      if (!ok || _ponto == null) {
        mostrarAviso(
          context,
          'Não achamos esse local no mapa. Use o CEP ou toque no mapa.',
        );
        return;
      }
      await PetService().atualizarLocal(
        widget.pet,
        localizacao: _localizacao.text.trim(),
        latitude: _ponto!.latitude,
        longitude: _ponto!.longitude,
      );
      if (mounted) {
        mostrarAviso(context, 'Localização atualizada!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar localização')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Onde ${widget.pet.nome} foi visto pela última vez?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textoSecundario,
              ),
            ),
            SeletorLocal(
              key: _seletor,
              localizacao: _localizacao,
              pontoInicial: _ponto,
              servico: widget.servico,
              onPonto: (p) => setState(() => _ponto = p),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Salvar localização'),
            ),
          ],
        ),
      ),
    );
  }
}
