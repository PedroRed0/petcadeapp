import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/comuns.dart';
import '../../services/auth_service.dart';
import '../texto_screen.dart';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({super.key});

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();

  bool _senhaVisivel = false;
  bool _confirmarVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    for (final c in [_nome, _email, _telefone, _senha, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await AuthService().criarConta(
        nome: _nome.text,
        email: _email.text,
        telefone: _telefone.text,
        senha: _senha.text,
      );
      // Já fica logado: volta para a raiz, que agora mostra o app.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) mostrarAviso(context, AuthService.mensagemErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = GoogleFonts.poppins(
      fontSize: 12,
      color: AppColors.destaque(context),
      decoration: TextDecoration.underline,
    );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Criar conta',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Vamos juntos ajudar a encontrar os pets que precisam!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textoSecundario,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length < 3 ? 'Digite seu nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'E-mail',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                  validator: (v) => (v ?? '').contains('@')
                      ? null
                      : 'Digite um e-mail válido',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Telefone (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _senha,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    hintText: 'Senha',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: _olho(
                      _senhaVisivel,
                      () => setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                  validator: (v) => (v ?? '').length < 6
                      ? 'Use pelo menos 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmar,
                  obscureText: !_confirmarVisivel,
                  decoration: InputDecoration(
                    hintText: 'Confirmar senha',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: _olho(
                      _confirmarVisivel,
                      () => setState(
                        () => _confirmarVisivel = !_confirmarVisivel,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v != _senha.text ? 'As senhas não são iguais' : null,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _carregando ? null : _cadastrar,
                  child: _carregando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cadastrar'),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textoSecundario,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Ao se cadastrar, você concorda com nossos ',
                      ),
                      TextSpan(
                        text: 'Termos de Uso',
                        style: link,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => abrirTexto(context, TextoApp.termos),
                      ),
                      const TextSpan(text: ' e '),
                      TextSpan(
                        text: 'Política de Privacidade',
                        style: link,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>
                              abrirTexto(context, TextoApp.privacidade),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _olho(bool visivel, VoidCallback onTap) => IconButton(
    icon: Icon(
      visivel ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      size: 20,
    ),
    onPressed: onTap,
  );
}
