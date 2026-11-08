import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'comuns.dart';

/// Antes de publicar, avisar avistamento ou denunciar: exige e-mail
/// confirmado. Retorna true se pode continuar.
Future<bool> exigirEmailConfirmado(BuildContext context) async {
  final auth = AuthService();
  if (auth.emailConfirmado) return true;
  // Talvez a pessoa já tenha clicado no link: confere no Firebase.
  try {
    if (await auth.atualizarConfirmacao()) return true;
  } catch (_) {}
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _DialogoConfirmar(),
  );
  return ok == true;
}

class _DialogoConfirmar extends StatefulWidget {
  const _DialogoConfirmar();

  @override
  State<_DialogoConfirmar> createState() => _DialogoConfirmarState();
}

class _DialogoConfirmarState extends State<_DialogoConfirmar> {
  final _auth = AuthService();
  bool _ocupado = false;

  Future<void> _jaConfirmei() async {
    setState(() => _ocupado = true);
    try {
      final ok = await _auth.atualizarConfirmacao();
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
      } else {
        mostrarAviso(
          context,
          'Ainda não confirmado. Abra o link que enviamos para o seu e-mail.',
        );
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, AuthService.mensagemErro(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() => _ocupado = true);
    try {
      await _auth.reenviarConfirmacao();
      if (mounted) {
        mostrarAviso(context, 'E-mail reenviado. Confira também o spam.');
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, AuthService.mensagemErro(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.usuarioAtual?.email ?? 'seu e-mail';
    return AlertDialog(
      icon: const Icon(
        Icons.mark_email_unread_outlined,
        color: AppColors.laranja,
      ),
      title: Text(
        'Confirme seu e-mail',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Para manter o PetCadê seguro, só contas com e-mail confirmado podem '
        'publicar anúncios, avisar avistamentos e denunciar.\n\n'
        'Enviamos um link para $email. Abra o link e depois toque em '
        '"Já confirmei".',
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: _ocupado ? null : _reenviar,
          child: const Text('Reenviar'),
        ),
        TextButton(
          onPressed: _ocupado ? null : () => Navigator.pop(context, false),
          child: const Text('Agora não'),
        ),
        TextButton(
          onPressed: _ocupado ? null : _jaConfirmei,
          style: TextButton.styleFrom(foregroundColor: AppColors.laranja),
          child: const Text('Já confirmei'),
        ),
      ],
    );
  }
}

/// Faixa na tela inicial enquanto o e-mail não for confirmado.
/// Some sozinha quando a pessoa volta ao app depois de clicar no link.
class AvisoConfirmarEmail extends StatefulWidget {
  const AvisoConfirmarEmail({super.key});

  @override
  State<AvisoConfirmarEmail> createState() => _AvisoConfirmarEmailState();
}

class _AvisoConfirmarEmailState extends State<AvisoConfirmarEmail>
    with WidgetsBindingObserver {
  final _auth = AuthService();
  late bool _confirmado = _auth.emailConfirmado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_confirmado) _conferir();
  }

  Future<void> _conferir() async {
    try {
      final ok = await _auth.atualizarConfirmacao();
      if (mounted && ok) setState(() => _confirmado = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmado || _auth.usuarioAtual == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.fundoDestaque(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final ok = await exigirEmailConfirmado(context);
            if (mounted && ok) setState(() => _confirmado = true);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 22,
                  color: AppColors.destaque(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirme seu e-mail',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Necessário para publicar anúncios. Toque aqui.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textoSecundario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
