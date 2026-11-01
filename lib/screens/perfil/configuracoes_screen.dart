import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/widgets/comuns.dart';
import '../../services/auth_service.dart';
import '../../services/localizacao_service.dart';
import '../texto_screen.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, modo, _) => LinhaOpcao(
              icone: Icons.dark_mode_outlined,
              titulo: 'Modo escuro',
              onTap: alternarTema,
              trailing: Switch(
                value: modo == ThemeMode.dark,
                onChanged: (_) => alternarTema(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          LinhaOpcao(
            icone: Icons.my_location_rounded,
            titulo: 'Atualizar minha localização',
            subtitulo: 'Usada para mostrar a distância dos pets',
            onTap: () async {
              final p = await LocalizacaoService.instancia.atualizar();
              if (context.mounted) {
                mostrarAviso(
                  context,
                  p == null
                      ? 'Não foi possível obter a localização. Verifique as permissões.'
                      : 'Localização atualizada.',
                );
              }
            },
          ),
          const SizedBox(height: 10),
          LinhaOpcao(
            icone: Icons.lock_reset_rounded,
            titulo: 'Redefinir senha',
            subtitulo: 'Enviaremos um link para seu e-mail',
            onTap: () async {
              final email = AuthService().usuarioAtual?.email;
              if (email == null) return;
              try {
                await AuthService().redefinirSenha(email);
                if (context.mounted) {
                  mostrarAviso(context, 'Link enviado para $email.');
                }
              } catch (e) {
                if (context.mounted) {
                  mostrarAviso(context, AuthService.mensagemErro(e));
                }
              }
            },
          ),
          const SizedBox(height: 10),
          LinhaOpcao(
            icone: Icons.description_outlined,
            titulo: 'Termos de Uso',
            onTap: () => abrirTexto(context, TextoApp.termos),
          ),
          const SizedBox(height: 10),
          LinhaOpcao(
            icone: Icons.privacy_tip_outlined,
            titulo: 'Política de Privacidade',
            onTap: () => abrirTexto(context, TextoApp.privacidade),
          ),
        ],
      ),
    );
  }
}
