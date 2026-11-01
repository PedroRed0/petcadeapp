import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/comuns.dart';
import '../../core/widgets/logo_petcade.dart';
import '../../services/auth_service.dart';
import 'criar_conta_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _auth = AuthService();

  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await _auth.entrar(_emailController.text, _senhaController.text);
      // O AuthGate (main.dart) troca de tela sozinho.
    } catch (e) {
      if (mounted) mostrarAviso(context, AuthService.mensagemErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueciSenha() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      mostrarAviso(context, 'Digite seu e-mail no campo acima primeiro.');
      return;
    }
    try {
      await _auth.redefinirSenha(email);
      if (mounted) {
        mostrarAviso(
          context,
          'Enviamos um link para $email redefinir a senha.',
        );
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, AuthService.mensagemErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final branco70 = Colors.white.withValues(alpha: 0.7);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.roxo, AppColors.roxoEscuro],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: LogoPetcade(tamanho: 84)),
                      const SizedBox(height: 12),
                      Text(
                        'Juntos por eles',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Entre para ajudar a reencontrar pets',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: branco70,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textoPrincipal,
                        ),
                        decoration: _decoracao(
                          'E-mail',
                          Icons.mail_outline_rounded,
                        ),
                        validator: (v) => (v ?? '').contains('@')
                            ? null
                            : 'Digite um e-mail válido',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: !_senhaVisivel,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _entrar(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textoPrincipal,
                        ),
                        decoration: _decoracao(
                          'Senha',
                          Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _senhaVisivel
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').isEmpty ? 'Digite sua senha' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _carregando ? null : _entrar,
                        child: _carregando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _esqueciSenha,
                        style: TextButton.styleFrom(foregroundColor: branco70),
                        child: const Text('Esqueci minha senha'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Não tem conta? ',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CriarContaScreen(),
                              ),
                            ),
                            child: Text(
                              'Cadastre-se',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.laranja,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracao(String dica, IconData icone) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: dica,
      prefixIcon: Icon(icone, size: 20),
      fillColor: Colors.white,
      filled: true,
      border: borda,
      enabledBorder: borda,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.laranja, width: 1.5),
      ),
      errorStyle: GoogleFonts.poppins(color: AppColors.laranjaClaro),
    );
  }
}
