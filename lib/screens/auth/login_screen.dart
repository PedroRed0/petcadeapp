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
  bool _carregandoGoogle = false;

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

  Future<void> _entrarComGoogle() async {
    setState(() => _carregandoGoogle = true);
    try {
      await _auth.entrarComGoogle();
      // Se entrou, o AuthGate troca de tela sozinho.
    } catch (e) {
      if (mounted) mostrarAviso(context, AuthService.mensagemErro(e));
    } finally {
      if (mounted) setState(() => _carregandoGoogle = false);
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'ou',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: branco70,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _BotaoGoogle(
                        carregando: _carregandoGoogle,
                        onPressed: _carregando || _carregandoGoogle
                            ? null
                            : _entrarComGoogle,
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        alignment: WrapAlignment.center,
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

/// Botão branco "Entrar com Google" com o "G" colorido.
class _BotaoGoogle extends StatelessWidget {
  final bool carregando;
  final VoidCallback? onPressed;

  const _BotaoGoogle({required this.carregando, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textoPrincipal,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.8),
        disabledForegroundColor: AppColors.textoSecundario,
      ),
      child: carregando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(painter: _LogoGoogle()),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Entrar com Google',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Desenha o "G" do Google com as quatro cores.
class _LogoGoogle extends CustomPainter {
  const _LogoGoogle();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final traco = s * 0.2;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: (s - traco) / 2,
    );
    Paint cor(int c) => Paint()
      ..color = Color(c)
      ..style = PaintingStyle.stroke
      ..strokeWidth = traco;
    const grau = 3.14159265 / 180;
    canvas.drawArc(rect, -40 * grau, -100 * grau, false, cor(0xFFEA4335));
    canvas.drawArc(rect, -140 * grau, -90 * grau, false, cor(0xFFFBBC05));
    canvas.drawArc(rect, -230 * grau, -95 * grau, false, cor(0xFF34A853));
    canvas.drawArc(rect, -325 * grau, -35 * grau, false, cor(0xFF4285F4));
    // barra horizontal azul
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - traco / 2, s / 2 - traco / 4, traco),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
