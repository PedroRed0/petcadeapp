import 'package:flutter/material.dart';

import '../../core/widgets/comuns.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Usuario usuario;

  const EditarPerfilScreen({super.key, required this.usuario});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario.nome);
  late final _telefone = TextEditingController(text: widget.usuario.telefone);
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await UsuarioService().atualizarPerfil(
        nome: _nome.text,
        telefone: _telefone.text,
      );
      if (mounted) {
        mostrarAviso(context, 'Perfil atualizado.');
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
      appBar: AppBar(title: const Text('Editar perfil')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (v) =>
                  (v ?? '').trim().length < 3 ? 'Digite seu nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.usuario.email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
