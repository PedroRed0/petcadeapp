import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/pet_service.dart';
import '../models/pet.dart';

import 'dart:io';

import '../core/theme/app_colors.dart';
import '../core/widgets/theme_toggle_button.dart';

class CadastroPetScreen extends StatefulWidget {
  const CadastroPetScreen({super.key});

  @override
  State<CadastroPetScreen> createState() => _CadastroPetScreenState();
}

class _CadastroPetScreenState extends State<CadastroPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final _recompensaController = TextEditingController();

  String _especie = 'Cachorro';
  File? _foto;

  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) {
      setState(() => _foto = File(imagem.path));
    }
  }

  final _petService = PetService();
  bool _enviando = false;

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_foto == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adicione uma foto do pet')));
      return;
    }

    setState(() => _enviando = true);

    try {
      final fotoUrl = await _petService.uploadFoto(_foto!);

      final novoPet = Pet(
        nome: _nomeController.text.trim(),
        especie: _especie,
        racaCor: _racaController.text.trim(),
        descricao: _descricaoController.text.trim(),
        fotoUrl: fotoUrl,
        localizacao: _localizacaoController.text.trim(),
        latitude:
            -23.5610, // fixo por enquanto — depois plugamos GPS de verdade
        longitude: -46.5250,
        recompensa: _recompensaController.text.trim().isEmpty
            ? null
            : double.tryParse(_recompensaController.text.trim()),
        criadoEm: DateTime.now(),
      );

      await _petService.cadastrarPet(novoPet);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet cadastrado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao cadastrar: $e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cadastrar Pet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Foto
            GestureDetector(
              onTap: _selecionarFoto,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.laranjaClaro.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.laranja.withValues(alpha: 0.4),
                  ),
                ),
                child: _foto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_rounded,
                            color: AppColors.laranja,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicionar foto do pet',
                            style: GoogleFonts.poppins(
                              color: AppColors.laranja,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _foto!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            _campoTexto(controller: _nomeController, label: 'Nome do pet'),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _especie,
              decoration: const InputDecoration(labelText: 'Espécie'),
              items: [
                'Cachorro',
                'Gato',
                'Outro',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _especie = v!),
            ),
            const SizedBox(height: 14),

            _campoTexto(controller: _racaController, label: 'Raça / cor'),
            const SizedBox(height: 14),

            _campoTexto(
              controller: _descricaoController,
              label: 'Descrição detalhada (porte, coleira, características)',
              maxLines: 4,
            ),
            const SizedBox(height: 14),

            _campoTexto(
              controller: _localizacaoController,
              label: 'Última localização aproximada',
              suffixIcon: Icons.my_location_rounded,
            ),
            const SizedBox(height: 14),

            _campoTexto(
              controller: _recompensaController,
              label: 'Recompensa (R\$) — opcional',
              keyboardType: TextInputType.number,
              obrigatorio: false,
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _enviando ? null : _cadastrar,
              child: _enviando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Cadastrar Pet Desaparecido'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? suffixIcon,
    bool obrigatorio = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: AppColors.azulMedio)
            : null,
      ),
      validator: (v) {
        if (obrigatorio && (v == null || v.trim().isEmpty)) {
          return 'Campo obrigatório';
        }
        return null;
      },
    );
  }
}
